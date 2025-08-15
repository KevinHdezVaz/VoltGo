import 'dart:convert';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/ui/MenuPage/DashboardScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/login/ForgotPasswordScreen.dart';
import 'package:Voltgo_app/ui/login/RegisterScreen.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_app/utils/encryption_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _companyController.addListener(_updateButtonState);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _companyController.text.trim().isNotEmpty;
    });
  }

  Future<void> _login() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      final base64Password =
          EncryptionUtils.toBase64(_passwordController.text.trim());

      final loginResponse = await AuthService.login(
        username: _usernameController.text.trim(),
        password: base64Password,
        company: _companyController.text.trim(),
      );
      _animationController.stop();
      if (!mounted) return;

      if (loginResponse.token.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      } else {
        // ... (Tu manejo de errores existente)
        String errorMessage = 'Usuario, contraseña o empresa incorrectos';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Error de conexión: No se pudo conectar con el servidor'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    // ▼▼▼ MODIFICADO: Espaciado ajustado ▼▼▼
                    const SizedBox(height: 24),
                    // ▼▼▼ NUEVO: Widget para los botones de login social ▼▼▼
                    _buildSocialLogins(),
                    // ▼▼▼ MODIFICADO: Espaciado ajustado ▼▼▼
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: AnimatedTruckProgress(
                animation: _animationController,
              ),
            ),
        ],
      ),
    );
  }

  // ▼▼▼ NUEVO: Widget para mostrar botones de Google y Apple ▼▼▼
  Widget _buildSocialLogins() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'O',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        // Botón de Google
        _buildSocialButton(
          assetName: 'assets/images/gugel.png',
          text: 'Iniciar sesión con Google',
          onPressed: () {
            print('Login con Google presionado');
          },
        ),
        const SizedBox(height: 12),
        // Botón de Apple
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          // MODIFICADO: Texto del botón
          text: 'Iniciar sesión con Apple',
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implementar la lógica de inicio de sesión con Apple
            print('Login con Apple presionado');
          },
        ),
      ],
    );
  }

  // ▼▼▼ NUEVO: Helper para crear botones de login social genéricos ▼▼▼
  Widget _buildSocialButton({
    required String assetName,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Image.asset(assetName, height: 22, width: 22),
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: BorderSide(color: AppColors.gray300),
        ),
      ),
    );
  }

  // --- Widgets existentes (con pequeñas modificaciones) ---

  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
        top: 0,
        right: -90,
        child: Image.asset(
          'assets/images/rectangle1.png',
          width: MediaQuery.of(context).size.width * 0.5,
          fit: BoxFit.contain,
          color: AppColors.primary, // Color que quieras aplicar
          colorBlendMode: BlendMode.srcIn, // Aplica el color sobre la imagen
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Image.asset(
          'assets/images/rectangle3.png',
          width: MediaQuery.of(context).size.width * 0.5,
          fit: BoxFit.contain,
          color: AppColors.primary, // Color que quieras aplicar
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/logoapp.jpg', // Asegúrate de tener esta imagen en tus assets
            height: 120, // Ajusta el tamaño según tu logo
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenido',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Correo electrónico',
          hint: 'Ingresa',
          controller: _usernameController,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(controller: _passwordController),
        const SizedBox(height: 20),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _login : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled && !_isLoading
                    ? AppColors.brandBlue
                    : AppColors.gray300,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 0),
            child: const Text('Iniciar sesión',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿No tienes una cuenta? ',
                style: TextStyle(color: AppColors.textSecondary)),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('Créala aquí.',
                  style: TextStyle(
                      color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavBar()),
            );
          },
          child: const Text('Recupera tu cuenta.',
              style: TextStyle(
                  color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                      color: AppColors.brandBlue, width: 1.5))))
    ]);
  }

  Widget _buildPasswordField({required TextEditingController controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Contraseña',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
              hintText: 'Ingresa tu contraseña',
              filled: true,
              fillColor: AppColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: AppColors.brandBlue, width: 1.5)),
              suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  })))
    ]);
  }
}
