/*

 import 'package:Voltgo_app/data/models/chat/ChatSession,dart';
import 'package:Voltgo_app/data/services/ChatServiceApi.dart';
import 'package:Voltgo_app/ui/MenuPage/Chats/ChatScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ChatServiceApi _chatService = ChatServiceApi();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Color tiffanyColor = Colors.white;
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color darkTextColor = Colors.black87;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    try {
      setState(() => _isLoading = true);
      final sessions = await _chatService.getSessions(saved: true);
      setState(() {
        _sessions = sessions
         //   .where((session) => session.deletedAt == null && session.isSaved)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar las conversaciones: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  List<ChatSession> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;

    return _sessions
        .where((session) =>
            session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            _formatDate(session.createdAt)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _deleteSession(int id) async {
    try {
      await _chatService.deleteSession(id);
      setState(() {
        _sessions.removeWhere((session) => session.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversación eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Error al eliminar la conversación: $e');
    }
  }

  void _startNewConversation({required String inputMode}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(
          initialMessages: [],
          inputMode: inputMode,
          sessionId: null,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tiffanyColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.ColorFooter],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Tus chats con Frutia',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: darkTextColor, size: 28),
            onPressed: _fetchSessions,
            tooltip: 'Recargar',
          ),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: FloatingActionButton(
          onPressed: () => _startNewConversation(inputMode: 'keyboard'),
          backgroundColor: AppColors.accent,
          child: Icon(Icons.add, color: Colors.white),
          tooltip: 'Nueva Conversación',
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(
                    20.0), // Aumenté el padding externo a 20 para mejor espaciado
                child: Column(
                  children: [
                    Card(
                      color: Colors.white,
                      elevation:
                          6, // Aumenté la elevation a 6 para una sombra más pronunciada
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1), // Añadí un borde sutil
                      ),
                      margin: const EdgeInsets.all(
                          8.0), // Añadí padding interno al Card
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar conversaciones...',
                          hintStyle: GoogleFonts.poppins(
                              color: darkTextColor.withOpacity(0.5)),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.accent),
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        style: GoogleFonts.poppins(
                            color: darkTextColor, fontSize: 16),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    if (_filteredSessions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0), // Aumenté el padding superior a 20
                        child: _buildNewChatButtons(),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 3,
                        ),
                      )
                    : _filteredSessions.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppColors.accent,
                            onRefresh: _fetchSessions,
                            child: ListView.builder(
                              padding: EdgeInsets.only(
                                  bottom: 80, left: 16, right: 16),
                              itemCount: _filteredSessions.length,
                              itemBuilder: (context, index) {
                                final session = _filteredSessions[index];
                                return _buildSessionCard(session);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, ivoryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: AppColors.accent.withOpacity(0.2),
            child: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          title: Text(
            session.title,
            style: GoogleFonts.poppins(
              color: darkTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(session.createdAt),
            style: GoogleFonts.poppins(
              color: darkTextColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline,
                color: AppColors.accent, size: 24),
            onPressed: () => _showDeleteDialog(session.id),
          ),
          onTap: () => _openChat(session),
        ),
      ),
    );
  }

  void _showDeleteDialog(int sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.2).animate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: AppColors.accent, size: 48),
              ),
              SizedBox(height: 16),
              Text(
                'Eliminar Conversación',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '¿Estás seguro de que quieres eliminar esta conversación?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: darkTextColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ivoryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: darkTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSession(sessionId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Eliminar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(ChatSession session) async {
    try {
      final messages = await _chatService.getSessionMessages(session.id);
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChatScreen(
            initialMessages: messages,
            inputMode: 'keyboard',
            sessionId: session.id,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 700),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Error al abrir la conversación: $e');
    }
  }

  Widget _buildNewChatButtons() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Adaptamos el diseño según el ancho disponible
      final bool isWide = constraints.maxWidth > 600; // Tablet o pantallas anchas
      final double buttonPadding = isWide ? 24.0 : 16.0;
      final double iconSize = isWide ? 24.0 : 20.0;
      final double fontSize = isWide ? 18.0 : 16.0;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
         child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChatButton(
              context,
              icon: Icons.message,
              label: 'Chat Normal',
              backgroundColor: AppColors.accent,
              textColor: Colors.white,
              iconColor: Colors.white,
              onPressed: () => _startNewConversation(inputMode: 'keyboard'),
              padding: buttonPadding,
              iconSize: iconSize,
              fontSize: fontSize,
            ),
            SizedBox(height: 30),
             
          ],
        ),
      );
    },
  );
}

Widget _buildChatButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color backgroundColor,
  required Color textColor,
  required Color iconColor,
  Color? borderColor,
  required VoidCallback onPressed,
  required double padding,
  required double iconSize,
  required double fontSize,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null 
          ? BorderSide(color: borderColor, width: 1)
          : BorderSide.none,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: padding, 
        vertical: 12,
      ),
      elevation: 2,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, 
            fontSize: fontSize,
          ),
        ),
      ],
    ),
  );
}
 

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                    parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: AppColors.accent.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡No hay conversaciones aún!',
              style: GoogleFonts.poppins(
                color: darkTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Empieza una nueva conversación con Frutia, ya sea por texto o voz.',
              style: GoogleFonts.poppins(
                color: darkTextColor.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildNewChatButtons(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final formattedTime = _formatTime(date);

    if (dateOnly == today) {
      return 'Hoy a las $formattedTime';
    } else if (dateOnly == yesterday) {
      return 'Ayer a las $formattedTime';
    } else {
      return '${date.day}/${date.month}/${date.year} $formattedTime';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

*/
