import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/login/LoginScreen.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_app/utils/encryption_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _companyController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _companyController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          (_passwordController.text.trim() ==
              _confirmPasswordController.text.trim());
    });
  }

  Future<void> _register() async {
    if (!_isButtonEnabled || _isLoading) return;
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    _animationController.repeat();
    try {
      final base64Password =
          EncryptionUtils.toBase64(_passwordController.text.trim());
      // Lógica de API...
      await Future.delayed(const Duration(seconds: 3)); // Simulación
      _animationController.stop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Por favor, inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el registro: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildForm(),
                    const SizedBox(height: 24),
                    // ▼▼▼ NUEVO: Widget para los botones de login social ▼▼▼
                    _buildSocialLogins(),
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
          text: 'Registrarse con Google',
          onPressed: () {
            // TODO: Implementar la lógica de inicio de sesión con Google
            // usando paquetes como 'google_sign_in'.
            print('Registro con Google presionado');
          },
        ),
        const SizedBox(height: 12),
        // Botón de Apple
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          text: 'Registrarse con Apple',
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implementar la lógica de inicio de sesión con Apple
            // usando paquetes como 'sign_in_with_apple'.
            print('Registro con Apple presionado');
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

  // --- Widgets existentes (sin cambios funcionales) ---

  Widget _buildHeader() {
    return const Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Crea tu cuenta',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('Completa el formulario para empezar.',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
            label: 'Nombre completo',
            hint: 'Tu nombre y apellido',
            controller: _nameController),
        const SizedBox(height: 20),
        _buildTextField(
            label: 'Correo electrónico',
            hint: 'tucorreo@ejemplo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildPasswordField(
            label: 'Contraseña',
            controller: _passwordController,
            isPasswordVisible: _isPasswordVisible,
            onToggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible)),
        const SizedBox(height: 20),
        _buildPasswordField(
            label: 'Confirmar contraseña',
            controller: _confirmPasswordController,
            isPasswordVisible: _isConfirmPasswordVisible,
            onToggleVisibility: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _register : null,
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
            child: const Text('Crear cuenta',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes una cuenta? ',
            style: TextStyle(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Inicia sesión.',
              style: TextStyle(
                  color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
          top: 0,
          right: -90,
          child: Image.asset('assets/images/rectangle1.png',
              width: MediaQuery.of(context).size.width * 0.5,
              color: AppColors.primary, // Color que quieras aplicar
              colorBlendMode:
                  BlendMode.srcIn, // Aplica el color sobre la imagen
              fit: BoxFit.contain)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset('assets/images/rectangle3.png',
              color: AppColors.primary, // Color que quieras aplicar
              colorBlendMode:
                  BlendMode.srcIn, // Aplica el color sobre la imagen
              width: MediaQuery.of(context).size.width * 0.5,
              fit: BoxFit.contain))
    ]);
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller,
      TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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

  Widget _buildPasswordField(
      {required String label,
      required TextEditingController controller,
      required bool isPasswordVisible,
      required VoidCallback onToggleVisibility}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
              hintText: 'Mínimo 8 caracteres',
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
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary),
                  onPressed: onToggleVisibility)))
    ]);
  }
}
