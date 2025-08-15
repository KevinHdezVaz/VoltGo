/*

import 'dart:convert';
import 'dart:io';
 
import 'package:Voltgo_app/data/models/chat/ChatMessage.dart';
import 'package:Voltgo_app/data/services/ChatServiceApi.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/data/services/storageService.dart';
import 'package:Voltgo_app/ui/MenuPage/Chats/PermissionService.dart';
import 'package:Voltgo_app/ui/MenuPage/Chats/WaveVisualizer.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:http/http.dart' as http;
 

import 'package:flutter/material.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter/painting.dart'
    as painting; // Import explícito para TextDirection

import 'dart:math';
import 'dart:async';

import 'package:vibration/vibration.dart'; 
class ChatScreen extends StatefulWidget {
  final String inputMode;
  final List<ChatMessage>? initialMessages;
  final int? sessionId;
  final String? initialMessage;

  const ChatScreen({
    Key? key,
    required this.inputMode,
    this.initialMessages,
    this.sessionId,
    this.initialMessage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _transcribedText = '';
  bool _isTyping = false;
  int _typingIndex = 0;
  File? _stagedImageFile; // Guardará la imagen que está lista para ser enviada

  // --- NUEVAS VARIABLES DE ESTADO ---
  bool _isPremium = false;
  int _userMessageCount = 0;
  final int _messageLimit = 3;

  Timer? _typingTimer; // Nullable
  final ImagePicker _picker = ImagePicker();

  bool _isSpeechInitialized = false;
  AnimationController?
      _sunController; // Nullable  late Animation<double> _sunAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ChatServiceApi _chatService = ChatServiceApi();

  final Color frutia_background = Colors.white; // Un crema suave y cálido
  final Color frutia_accent =
      Color(0xFFFF8A65); // Durazno/Coral como acento principal
  final Color frutia_primary_text =
      Color(0xFF5D4037); // Marrón oscuro para texto

  // Colores mejorados para los bubbles
  final Color user_bubble_color = const Color.fromARGB(
      255, 236, 112, 67); // Color principal para el usuario

  final Color bot_bubble_color =
      AppColors.accent; // Gris oscuro elegante para el bot

  final Color user_text_color =
      Colors.white; // Texto blanco para mejor contraste
  final Color bot_text_color = Colors.white;
  final Color time_text_color = Colors.white70; // Color más suave para la hora

  List<ChatMessage> _messages = [];
  int? _currentSessionId;
  bool _isSaved = false;
  String? _emotionalState;
  String? _conversationLevel;
  bool _initialMessageSent = false;

  double _soundLevel = 0.0; // Nueva variable para el nivel de sonido
  // Lógica para conteo de tokens y resumen
  final int _tokenLimit = 500;
  int _totalTokens = 0;

  List<TextSpan> _parseTextToSpans(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: TextStyle(
              color: textColor, // Usar el color pasado
              fontFamily: 'Lora',
              fontSize: 15,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: textColor, // Usar el color pasado
            fontFamily: 'Lora',
            fontSize: 15,
            height: 1.6,
            letterSpacing: 0.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            color: textColor, // Usar el color pasado
            fontFamily: 'Lora',
            fontSize: 15,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      );
    }
    return spans;
  }

  // --- NEW: GlobalKeys for the new showcase targets ---
  final GlobalKey _saveButtonKey = GlobalKey(debugLabel: 'saveButtonShowcase');
  final GlobalKey _micButtonKey = GlobalKey(debugLabel: 'micButtonShowcase');
  final GlobalKey _voiceChatButtonKey =
      GlobalKey(debugLabel: 'voiceChatButtonShowcase');

  bool _isCheckingPlan = true; // Empieza en true para mostrar el loader
  bool _hasActivePlan = false; // Determina si el usuario tiene un plan

  @override
  void initState() {
    super.initState();
    // En lugar de llamar a _checkUserPlanStatus, llamamos a una función más completa
    _initializeScreen();
  }

  // En: lib/pages/screens/chatFrutia/ChatScreen.dart -> _ChatScreenState

  Future<void> _performBodyAnalysis() async {
    // 1. Abrir la galería para que el usuario elija una imagen.
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Opcional: comprime un poco la imagen
    );

    // Si el usuario cancela la selección, no hacemos nada.
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);

    // ▼▼▼ CAMBIOS CLAVE SIN DIÁLOGO ▼▼▼
    // 2. Capturar el texto que ya está escrito en el TextField.
    final String userText = _controller.text;

    // 3. Limpiar el TextField y ocultar el teclado para una mejor experiencia.
    _controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    // ▲▲▲ FIN DE LOS CAMBIOS ▲▲▲

    // 4. Crear el mensaje del usuario que contiene AMBOS, la imagen y el texto.
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatSessionId: _currentSessionId ?? -1,
      isUser: true,
      imagePath: imageFile.path,
      text: userText.isNotEmpty ? userText : null, // Guarda el texto capturado
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, userMessage);
      _isTyping = true;
    });

    // 5. Llamar al servicio, pasándole ambos datos.
    try {
      final analysisResult = await _chatService.analyzeBodyImage(
        imageFile,
        text: userText, // Pasamos el texto al servicio
      );

      // El resto de la lógica para manejar la respuesta exitosa no cambia.
      final assistantResponseMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        chatSessionId: _currentSessionId ?? -1,
        isUser: false,
        analysisData: analysisResult,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, assistantResponseMessage);
      });
    } catch (e) {
      // El manejo de errores tampoco cambia.
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        chatSessionId: _currentSessionId ?? -1,
        isUser: false,
        text: 'Lo siento, no pude analizar la imagen. Inténtalo de nuevo. 😥',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      // Leer la imagen como bytes y convertir a base64
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Obtener el usuario actual
      final currentUser = await _storageService.getUser();

      // Llamar al backend para análisis
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/analyze-body-fat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'user_id': currentUser?.id,
          'session_id': _currentSessionId,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Crear mensaje con la imagen
        final imageMessage = ChatMessage(
          id: -1,
          chatSessionId: _currentSessionId ?? -1,
          userId: currentUser?.id ?? -1,
          imagePath: pickedFile.path,
          isUser: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Crear mensaje con los resultados
        final analysisMessage = ChatMessage(
          id: -1,
          chatSessionId: _currentSessionId ?? -1,
          userId: 0, // ID del bot
          text: data['analysis'],
          isUser: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        setState(() {
          _messages.insert(0, analysisMessage);
          _messages.insert(0, imageMessage);
          _isLoading = false;
        });
      } else {
        throw Exception('Error al analizar la imagen');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  // ▼▼▼ NUEVO: Función para manejar el envío de mensajes con imagen ▼▼▼
  Future<void> _sendImageMessage(String imagePath) async {
    final currentUser = await _storageService.getUser();
    final newMessage = ChatMessage(
      id: -1,
      chatSessionId: _currentSessionId ?? -1,
      userId: currentUser?.id ?? -1,
      imagePath: imagePath, // Usamos el nuevo campo
      isUser: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, newMessage);
      _isTyping = true;
    });

    // Aquí iría la lógica para subir la imagen a tu backend
    // y obtener una respuesta del modelo de IA sobre la imagen.
    // Por ahora, simulamos una respuesta después de 2 segundos.
    await Future.delayed(const Duration(seconds: 2));

    final aiResponse = ChatMessage(
      id: -1,
      chatSessionId: _currentSessionId ?? -1,
      userId: 0,
      text: "¡Qué buena foto! Analizándola...",
      isUser: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, aiResponse);
      _isTyping = false;
    });
  }
  
 
  Widget _buildChatUI(BuildContext innerContext) {
    return Stack(
      children: [
        _FloatingParticles(),
        if (_isLoading && _messages.isEmpty)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              strokeWidth: 6.0,
            ),
          )
        else
          Column(
            children: [
              // ▼▼▼ APPBAR ACTUALIZADA CON EL DISEÑO QUE PREFIERES ▼▼▼
              AppBar(
                backgroundColor: AppColors.accent,
                elevation: 2,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => _navigateBack(innerContext),
                ),

                // Título con Avatar y subtítulo de mensajes restantes
                title: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        'F',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold),
                      ),
                      radius: 18,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Frutia",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isPremium)
                          Text(
                            '${max(0, _messageLimit - _userMessageCount)} mensajes restantes',
                            style: GoogleFonts.lato(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Botón de "Guardar Chat" visible directamente
                actions: [
                  if (!_isSaved)
                    Showcase(
                      key: _saveButtonKey,
                      title: 'Guardar Chat',
                      description:
                          'Usa este botón para guardar la conversación, si no la guardas se perderá.',
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextButton.icon(
                          icon: const Icon(Icons.save,
                              color: Colors.white, size: 22),
                          label: const Text("Guardar",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14)),
                          onPressed: _saveChat,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // ▲▲▲ FIN DE LA ACTUALIZACIÓN DEL APPBAR ▲▲▲

              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == 0) {
                      return _buildTypingIndicator();
                    }
                    final messageIndex = _isTyping ? index - 1 : index;
                    return _buildMessageBubble(_messages[messageIndex]);
                  },
                ),
              ),
              _buildInput(),
            ],
          ),
      ],
    );
  }

  /// Inicializa toda la lógica del chat una vez que se confirma que hay un plan.
  void _initializeChat() {
    _messages = widget.initialMessages?.reversed.toList() ?? [];
    _currentSessionId = widget.sessionId;
    _isSaved = widget.sessionId != null;

    _initializeSpeech();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _isTyping) {
        setState(() => _typingIndex = (_typingIndex + 1) % 3);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showShowcase();
        });
      }
    });

    if (!_initialMessageSent) {
      _initialMessageSent = true;
      if (_currentSessionId == null && _messages.isEmpty) {
        _startNewSession().then((_) {
          if (widget.initialMessage != null &&
              widget.initialMessage!.isNotEmpty) {
            _sendMessage(widget.initialMessage!);
          }
        });
      } else if (widget.initialMessage != null &&
          widget.initialMessage!.isNotEmpty) {
        _sendMessage(widget.initialMessage!);
      }
    }
  }

    

  Future<void> _initializeSpeech() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _showErrorSnackBar('Se requieren permisos de micrófono');
        return;
      }
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      if (_isSpeechAvailable) {
        setState(() {
          _isSpeechInitialized = true;
        });
        // Lista los idiomas disponibles
        final locales = await _speech.locales();
        debugPrint(
            'Available locales: ${locales.map((l) => l.localeId).toList()}');
        debugPrint('Speech initialized successfully');
      } else {
        debugPrint('Speech initialization failed');
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      _showErrorSnackBar('Error initializing speech recognition');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialMessageSent) {
      _initialMessageSent = true;
      if (_currentSessionId == null && _messages.isEmpty) {
        _startNewSession().then((_) {
          if (widget.initialMessage != null &&
              widget.initialMessage!.isNotEmpty) {
            _sendMessage(widget.initialMessage!);
          }
        });
      } else if (widget.initialMessage != null &&
          widget.initialMessage!.isNotEmpty) {
        _sendMessage(widget.initialMessage!);
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _controller.dispose();
    if (_typingTimer?.isActive == true) {
      _typingTimer!.cancel();
    }
    if (_sunController?.isAnimating == true) {
      _sunController!.dispose();
    }
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  int _countTokens(String message) {
    return message.split(RegExp(r'\s+')).length;
  }

  void _updateTokenCount(String message) {
    final tokens = _countTokens(message);
    setState(() {
      _totalTokens += tokens;
    });
    if (_totalTokens > _tokenLimit) {}
  }

  void _startNewChatWithSummary(String summary) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          inputMode: widget.inputMode,
          initialMessage: summary,
        ),
      ),
    );
  }

  Future<bool> _isUserAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _startNewSession() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final isAuthenticated = await _isUserAuthenticated();
      if (!isAuthenticated) {
        print('User not authenticated, redirecting to login');
        _showErrorSnackBar('Por favor, inicia sesión para continuar');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthCheckMain()),
        );
        return;
      }

      final currentUser = await _storageService.getUser();
      final userName = currentUser?.name ?? 'Amigú';
      final response = await _chatService.startNewSession(userName: userName);

      if (!mounted) return;

      print('Start new session response: $response');

      if (response['session_id'] == null) {
        throw Exception('No session_id received from backend');
      }

      final aiMessage = ChatMessage(
        id: -1,
        chatSessionId: response['session_id'] ?? -1,
        userId: 0,
        text: response['ai_message']?['text'] ??
            'Error: No se recibió una respuesta válida.',
        isUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _currentSessionId = response['session_id'];
        _emotionalState =
            response['ai_message']['emotional_state'] ?? 'neutral';
        _conversationLevel =
            response['ai_message']['conversation_level'] ?? 'basic';
        _messages.insert(0, aiMessage);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('Error starting new session: $e');
        _showErrorSnackBar('Error al iniciar la sesión: $e');
      }
    }
  }

  Future<void> _sendMessage(String message, {bool isTemporary = false}) async {
    if (message.trim().isEmpty) return;

    if (_currentSessionId == null && !isTemporary) {
      print('No session ID, starting new session');
      await _startNewSession();
      if (_currentSessionId == null) {
        _showErrorSnackBar('No se pudo iniciar la sesión. Inténtalo de nuevo.');
        return;
      }
    }

    final currentUser = await _storageService.getUser();
    final newMessage = ChatMessage(
      id: -1,
      chatSessionId: _currentSessionId ?? -1,
      userId: currentUser?.id ?? -1,
      text: message,
      isUser: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, newMessage);
      _isTyping = true;
      _typingIndex = 0;
      _typingTimer?.cancel(); // Reinicia el timer para evitar solapamientos
      _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted) setState(() => _typingIndex = (_typingIndex + 1) % 3);
      });
      _updateTokenCount(newMessage.text!);
    });
    _controller.clear();

    try {
      print('Sending message with session_id: $_currentSessionId');
      final response = isTemporary
          ? await _chatService.sendTemporaryMessage(
              message,
              userName: currentUser?.name ?? 'Amigú',
            )
          : await _chatService.sendMessage(
              message: message,
              sessionId: _currentSessionId,
              isTemporary: false,
              userName: currentUser?.name ?? 'Amigú',
            );

      if (!mounted) return;

      print('Received response: $response');
      final aiMessage = ChatMessage(
        id: -1,
        chatSessionId: response['session_id'] ?? _currentSessionId ?? -1,
        userId: 0,
        text: response['ai_message']['text'],
        isUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, aiMessage);
        _isTyping = false;
        _typingTimer?.cancel();

        if (!isTemporary && response['session_id'] != null) {
          _currentSessionId = response['session_id'];
        }

        // ▼▼▼ LÍNEA CLAVE ACTUALIZADA ▼▼▼
        // Actualizamos el contador con el valor real que devuelve el backend
        if (response['user_message_count'] != null) {
          _userMessageCount = response['user_message_count'];
        }

        _updateTokenCount(aiMessage.text!);
      });

      Vibration.vibrate(duration: 200);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _typingTimer?.cancel();
      });
      print('Error sending message: $e');
      _showErrorSnackBar('Error al enviar el mensaje: $e');
    }
  }

  Future<void> _saveChat() async {
    if (_messages.isEmpty) {
     // _showErrorSnackBar('noMessagesToSave'.tr());
      return;
    }

    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Guardar Conversacion para despues",
            style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: "Titulo",
            hintText: "Escribe titulo...",
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF4BB6A8), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4BB6A8)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, titleController.text.trim());
              }
            },
            child: Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    try {
      final session = await _chatService.saveChatSession(
        title: title,
        messages: _messages.reversed
            .map((m) => {
                  'text': m.text,
                  'is_user': m.isUser,
                  'image_url': m.imageUrl, // <-- Enviamos la URL de la imagen

                  'created_at': m.createdAt.toIso8601String(),
                })
            .toList(),
        sessionId: _currentSessionId,
      );

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _currentSessionId = session.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Chat guardado corrrectamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
   //   _showErrorSnackBar('errorSavingChat'.tr(args: [e.toString()]));
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    final permissionService = PermissionService();
    final micStatus =
        await permissionService.checkOrRequest(Permission.microphone);
    debugPrint('Microphone permission status: $micStatus');

    if (!micStatus.isGranted) {
      if (micStatus.isPermanentlyDenied) {
        _showErrorSnackBar(
            'Por favor habilita los permisos de micrófono en Configuración');
        await openAppSettings();
      }
      return;
    }

    if (!_isSpeechInitialized || !_isSpeechAvailable) {
      _showErrorSnackBar('El reconocimiento de voz no está disponible');
      await _initializeSpeech();
      if (!_isSpeechInitialized || !_isSpeechAvailable) {
        return;
      }
    }

    try {
      setState(() {
        _isListening = true;
        _controller.clear();
      });

      const localeId = 'es_ES'; // Valor fijo para español (España)
      debugPrint('Starting speech recognition with locale: $localeId');

      await _speech.listen(
        onResult: (result) {
          debugPrint('Recognized words: ${result.recognizedWords}');
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
          });
        },
        localeId: localeId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          debugPrint('Sound level: $level');
          setState(() {
            _soundLevel = level;
          });
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error starting speech recognition: $e\n$stackTrace');
      setState(() => _isListening = false);
      _showErrorSnackBar('Error al iniciar: $e');
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      _showErrorSnackBar('Error al detener: $e');
    }
  }

  Widget _buildVoiceVisualizer() {
    if (!_isListening) return const SizedBox.shrink();
    return WaveVisualizer(
      soundLevel: _soundLevel,
      primaryColor: Colors.grey,
      secondaryColor: Colors.black, // e.g., Color(0xFF88D5C2)
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

// In: lib/pages/screens/chatFrutia/ChatScreen.dart -> _ChatScreenState

  Widget _buildMessageBubble(ChatMessage message) {
    // This part for the analysis card is correct.
    if (message.analysisData != null) {
      return _buildAnalysisResultCard(message.analysisData!);
    }

    final time = DateFormat('HH:mm').format(message.createdAt);
    final bool isUser = message.isUser;

    // ▼▼▼ CHANGE 1: CORRECTLY IDENTIFY IMAGE MESSAGES ▼▼▼
    // An image message now has either a local path OR a network URL.
    final bool isImageMessage =
        (message.imagePath != null && message.imagePath!.isNotEmpty) ||
            (message.imageUrl != null && message.imageUrl!.isNotEmpty);
    // ▲▲▲ END OF CHANGE 1 ▲▲▲

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              if (!isImageMessage && message.text != null) {
                FlutterClipboard.copy(message.text!).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Texto copiado'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                });
              }
            },
            child: ChatBubble(
              clipper: ChatBubbleClipper1(
                type:
                    isUser ? BubbleType.sendBubble : BubbleType.receiverBubble,
              ),
              alignment: isUser ? Alignment.topRight : Alignment.topLeft,
              margin: const EdgeInsets.only(top: 10),
              backGroundColor: isUser ? user_bubble_color : bot_bubble_color,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ▼▼▼ CHANGE 2: LOGIC TO DISPLAY THE CORRECT IMAGE TYPE ▼▼▼
                    if (isImageMessage)
                      Padding(
                        padding: EdgeInsets.only(
                            bottom:
                                message.text != null && message.text!.isNotEmpty
                                    ? 8.0
                                    : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Builder(
                            builder: (context) {
                              // If there's an internet URL, use Image.network
                              if (message.imageUrl != null &&
                                  message.imageUrl!.isNotEmpty) {
                                return Image.network(
                                  message.imageUrl!,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text('Error al cargar imagen');
                                  },
                                );
                              }
                              // Otherwise, use the local file path with Image.file
                              else {
                                return Image.file(File(message.imagePath!));
                              }
                            },
                          ),
                        ),
                      ),
                    // ▲▲▲ END OF CHANGE 2 ▲▲▲

                    // This logic for displaying text is correct.
                    if (message.text != null && message.text!.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: _parseTextToSpans(message.text!,
                              isUser ? user_text_color : bot_text_color),
                          style: TextStyle(
                            color: isUser ? user_text_color : bot_text_color,
                            fontSize: 16,
                            fontFamily: 'Lora',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 10, right: 10),
            child: Text(
              time,
              style: TextStyle(
                color: AppColors.ColorFooter.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Widget para mostrar la IMAGEN y el TEXTO del usuario.
  Widget _buildUserImageBubble(ChatMessage message) {
    return ChatBubble(
      clipper: ChatBubbleClipper1(type: BubbleType.sendBubble),
      alignment: Alignment.topRight,
      margin: const EdgeInsets.only(top: 20),
      backGroundColor: user_bubble_color, // Usando tu color definido
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        // ▼▼▼ CAMBIO PRINCIPAL AQUÍ ▼▼▼
        // Usamos una Columna para apilar la imagen y el texto.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment
              .start, // Alinea el texto a la izquierda dentro de la burbuja
          children: [
            // La imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(File(message.imagePath!)),
            ),

            // El texto (solo si existe y no está vacío)
            if (message.text != null && message.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, left: 4, right: 4, bottom: 4),
                child: Text(
                  message.text!,
                  style: TextStyle(
                    color:
                        user_text_color, // Usa el color de texto que ya definiste
                    fontSize: 16,
                    fontFamily: 'Lora',
                  ),
                ),
              ),
          ],
        ),
        // ▲▲▲ FIN DEL CAMBIO ▲▲▲
      ),
    );
  }

  Widget _buildAnalysisResultCard(Map<String, dynamic> result) {
    final double percentage = result['percentage']?.toDouble() ?? 0.0;
    final String recommendation = result['recommendation'] ?? 'No disponible.';
    final List<dynamic> observations = result['observations'] ?? [];

    return ChatBubble(
      clipper: ChatBubbleClipper1(type: BubbleType.receiverBubble),
      backGroundColor: const Color(0xffE7E7ED),
      margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% Grasa Corporal',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800),
                ),
                const Text('(Estimado)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 20),
                Text('Recomendación:',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(recommendation,
                    style: GoogleFonts.lato(color: Colors.black87)),
                const SizedBox(height: 12),
                if (observations.isNotEmpty) ...[
                  Text('Observaciones:',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  ...observations
                      .map((obs) => Text('• $obs',
                          style: GoogleFonts.lato(color: Colors.black87)))
                      .toList(),
                ]
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
 
 
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ChatBubble(
        clipper: ChatBubbleClipper1(type: BubbleType.receiverBubble),
        alignment: Alignment.topLeft,
        margin: EdgeInsets.only(top: 5),
        backGroundColor: Colors.white.withOpacity(0.8),
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _typingIndex ? Colors.red : Colors.grey,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isCheckingPlan = true;
    });
    try {
      final responseData = await RachaProgresoService.getProgresoWithUser();
      if (!mounted) return;

      final user = responseData['user'];
      final profile = responseData['profile'];

      final bool planIsComplete = profile != null &&
          (profile['plan_setup_complete'] == true ||
              profile['plan_setup_complete'] == 1);

      setState(() {
        _hasActivePlan = planIsComplete;
        _isPremium = user?['subscription_status'] == 'active';
        _userMessageCount = user?['message_count'] ?? 0;
        _isCheckingPlan = false;
      });

      if (planIsComplete) {
        _initializeChat();
      }
    } catch (e) {
      // ... (tu manejo de errores)
    }
  }

  Widget _buildInput() {
    // Si el usuario no es premium y ha alcanzado el límite, muestra el paywall.
    

    // De lo contrario, muestra el input normal.
    switch (widget.inputMode) {
      case 'keyboard':
        return _buildKeyboardInput();
      case 'voice':
        return _buildVoiceInput();
      default:
        return _buildKeyboardInput();
    }
  }

  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BottomNavBar(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var slideAnimation = animation.drive(tween);
          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: frutia_background,
        body: Builder(
          builder: (innerContext) {
            if (_isCheckingPlan) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              );
            }

           

            return _buildChatUI(innerContext);
          },
        ),
      ),
    );
  }

// En: lib/pages/screens/chatFrutia/ChatScreen.dart -> _ChatScreenState
  Widget _buildKeyboardInput() {
    final bool canSend =
        _controller.text.isNotEmpty || _stagedImageFile != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_stagedImageFile != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_stagedImageFile!,
                        width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text("Imagen adjunta",
                          style: TextStyle(color: Colors.black54))),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () {
                      setState(() {
                        _stagedImageFile = null;
                      });
                    },
                  )
                ],
              ),
            ).animate().fadeIn(),
          if (_isListening) _buildVoiceVisualizer(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(
                  text: _controller.text.isEmpty ? ' ' : _controller.text,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Lora'),
                ),
                maxLines: null,
                textDirection: painting.TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth - 80);

              final lineCount = textPainter.computeLineMetrics().length;
              final baseHeight = 60.0;
              final lineHeight = 20.0;
              final calculatedHeight =
                  baseHeight + (lineCount - 1) * lineHeight;
              final textFieldHeight = calculatedHeight.clamp(baseHeight, 200.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: textFieldHeight,
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Escribe tu mensaje...",
                    hintStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.image, color: AppColors.accent),
                          onPressed: _pickAndStageImage,
                          tooltip: 'Adjuntar imagen',
                        ),
                        if (!canSend) ...[
                          Showcase(
                            key: _micButtonKey,
                            title: 'Entrada de Voz',
                            description:
                                'Si no quieres escribir, puedes tocar aqui para grabar tu mensaje o detener la grabación.',
                            tooltipBackgroundColor: AppColors.accent,
                            targetShapeBorder: const CircleBorder(),
                            titleTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            descTextStyle: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            disableMovingAnimation: true,
                            disableScaleAnimation: true,
                            child: IconButton(
                              icon: Icon(
                                _isListening
                                    ? Icons.stop_circle
                                    : Icons.mic_none,
                                color: _isListening
                                    ? Colors.red
                                    : AppColors.accent,
                                size: _isListening ? 30 : 24,
                              ),
                              tooltip: _isListening
                                  ? 'Detener grabación'
                                  : 'Iniciar grabación',
                              onPressed: () async {
                                if (_isListening) {
                                  await _stopListening();
                                } else {
                                  await _startListening();
                                }
                              },
                            ),
                          ),
                          Showcase(
                            key: _voiceChatButtonKey,
                            title: 'Chat de Voz Avanzado',
                            description:
                                'Inicia una conversación de voz fluida con la IA.',
                            tooltipBackgroundColor: AppColors.accent,
                            targetShapeBorder: const CircleBorder(),
                            titleTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            descTextStyle: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            disableMovingAnimation: true,
                            disableScaleAnimation: true,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.record_voice_over,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                                tooltip: 'Chat de voz avanzado',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VoiceChatScreen(language: "es"),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        if (canSend)
                          IconButton(
                            icon: Icon(Icons.send, color: AppColors.accent),
                            onPressed: _handleSend,
                          ),
                      ],
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {});
                  },
                  scrollController: ScrollController(),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Future<void> _pickAndStageImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() {
      _stagedImageFile = File(pickedFile.path);
    });
  }

   void _handleSend() {
     if (_stagedImageFile != null) {
     }
     else if (_controller.text.isNotEmpty) {
      _sendMessage(_controller.text); // Asumo que ya tienes esta función
    }
  }

 
 
  Widget _buildVoiceInput() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? Colors.red.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? Colors.red.withOpacity(0.4)
                        : Colors.white.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 30,
                color: _isListening ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
        if (_controller.text
            .isNotEmpty) // Usa _controller.text en lugar de _transcribedText
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              _controller.text,
              style: TextStyle(color: Colors.black87, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _FloatingParticles extends StatefulWidget {
  @override
  __FloatingParticlesState createState() => __FloatingParticlesState();
}

class __FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 10), // Reducido para movimiento más rápido
    )..repeat();

    // Generar partículas con velocidades más visibles
    for (int i = 0; i < 20; i++) {
      // Aumentar número de partículas
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 2, // Tamaños más grandes
        speed: _random.nextDouble() * 0.3 + 0.1, // Velocidades más altas
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlesPainter(_particles, _controller.value),
        );
      },
    );
  }
}

class Particle {
  double x, y, size, speed;
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  _ParticlesPainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
          .withOpacity(0.2) // Aumentar opacidad para mejor visibilidad
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = (particle.x + time * particle.speed) % 1.0 * size.width;
      final y = (particle.y + time * particle.speed * 0.5) % 1.0 * size.height;
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

*/
