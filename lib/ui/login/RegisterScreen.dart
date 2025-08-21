import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/ui/login/add_vehicle_screen.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:Voltgo_User/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_User/utils/encryption_utils.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Controlador para el número

  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _fullPhoneNumber; // Para guardar LADA + NÚMERO

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  // En _RegisterScreenState
  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState); // <-- AÑADE ESTA LÍNEA
    // _companyController.addListener(_updateButtonState); // <-- PUEDES BORRAR ESTA
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

  // En _RegisterScreenState
  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty && // <-- CAMBIA ESTA LÍNEA
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          (_passwordController.text.trim() ==
              _confirmPasswordController.text.trim());
    });
  }

  Future<void> _register() async {
    if (!_isButtonEnabled || _isLoading) return;
    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      final response = await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _fullPhoneNumber,
        userType: 'user',
      );

      _animationController.stop();
      if (!mounted) return;

      if (response.success && response.token != null && response.user != null) {
        await TokenStorage.saveToken(response.token!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido! Registro exitoso.'),
            backgroundColor: Colors.green,
          ),
        );
        // Llama a la función de navegación
        _navigateAfterAuth(response.user!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Ocurrió un error')),
        );
      }
    } catch (e) {
      // ... tu manejo de errores
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Añade esta función dentro de tu _RegisterScreenState y _LoginScreenState

  void _navigateAfterAuth(UserModel user) {
    if (user.hasRegisteredVehicle) {
      // Si ya tiene vehículo, va a la pantalla principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } else {
      // Si NO tiene vehículo, muestra la pantalla de registro de vehículo
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => AddVehicleScreen(
            onVehicleAdded: () {
              // Este callback se ejecuta cuando el usuario guarda el vehículo
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const BottomNavBar()),
                (route) => false,
              );
            },
          ),
        ),
        (route) => false,
      );
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

  // En _RegisterScreenState, añade este nuevo método
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Teléfono móvil',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Número de teléfono',
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
          ),
          initialCountryCode: 'MX', // Código de país inicial (ej. México)
          onChanged: (phone) {
            // phone.completeNumber contiene la lada + el número (ej. +525512345678)
            setState(() {
              _fullPhoneNumber = phone.completeNumber;
            });
            _updateButtonState(); // Actualiza el estado del botón
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
        _buildPhoneField(), // <-- AÑADE EL NUEVO CAMPO AQUÍ

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
