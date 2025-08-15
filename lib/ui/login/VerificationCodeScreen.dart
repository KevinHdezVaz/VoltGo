import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pinput/pinput.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/login/ResetPasswordScreenUpdated.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _isNextButtonEnabled = false;
  bool _isResendButtonEnabled = false;
  bool _isLoading = false;
  Timer? _timer;
  int _countdown = 84;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_updateButtonState);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _animationController.dispose(); // 4. No olvidar desechar el controlador
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isNextButtonEnabled = _pinController.text.length == 5;
    });
  }

  void _startCountdown() {
    setState(() {
      _isResendButtonEnabled = false;
      _countdown = 84;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        if (mounted) {
          setState(() => _isResendButtonEnabled = true);
          _timer?.cancel();
        }
      }
    });
  }

  Future<void> _requestInitialCode() async {
    if (mounted) setState(() => _isLoading = true);
    _animationController.repeat(); // Inicia animación

    try {
      final response = await AuthService.requestPasswordReset(widget.email);
      await _animationController.forward(
          from: _animationController.value); // Completa la animación
      _animationController.stop();

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Código enviado')),
        );
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Error al enviar código')),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.reset();
      }
    }
  }

  Future<void> _resendCodeAndRestartTimer() async {
    if (_isLoading || !_isResendButtonEnabled) return;

    setState(() => _isLoading = true);
    _animationController.repeat(); // Inicia animación

    try {
      final response = await AuthService.requestPasswordReset(widget.email);
      await _animationController.forward(
          from: _animationController.value); // Completa la animación
      _animationController.stop();

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Código reenviado')),
        );
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message ?? 'Error al reenviar código')),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.reset();
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.repeat(); // Inicia animación

    try {
      final response = await AuthService.verifyMfaCode(
        email: widget.email,
        code: _pinController.text,
      );
      await _animationController.forward(
          from: _animationController.value); // Completa la animación
      _animationController.stop();

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Código verificado')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordScreenUpdated(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Código inválido')),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.reset();
      }
    }
  }

  String get formattedTime {
    int minutes = _countdown ~/ 60;
    int seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    _buildHeader(),
                    const SizedBox(height: 80),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text('Código de verificación',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                    ),
                    const SizedBox(height: 20),
                    _buildOtpInput(),
                    const SizedBox(height: 150),
                    _buildTimerDisplay(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40.0,
            left: 16.0,
            child: _buildBackButton(context),
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

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      icon: Image.asset(
        'assets/images/backbtn.png', // Asegúrate de tener esta imagen
        width: 50,
        height: 50,
      ),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Image.asset(
            'assets/images/rectangleForgot.png',
            width: MediaQuery.of(context).size.width * 0.7,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Image.asset(
            'assets/images/rectangle2Forgot.png',
            width: MediaQuery.of(context).size.width * 0.8,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text('Recupera tu cuenta',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        SizedBox(height: 16),
        Text(
            'Ingresa el código de verificación que enviamos a tu correo electrónico.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }

  Widget _buildOtpInput() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Pinput(
      length: 5,
      controller: _pinController,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: (value) {
        setState(() => _isNextButtonEnabled = value.length == 5);
      },
      onCompleted: (pin) {
        setState(() => _isNextButtonEnabled = true);
      },
    );
  }

  Widget _buildTimerDisplay() {
    return Text(
      formattedTime,
      style: TextStyle(
        fontSize: 16,
        color: _isResendButtonEnabled ? Colors.grey : AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isResendButtonEnabled && !_isLoading
                ? _resendCodeAndRestartTimer
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 40),
              side: BorderSide(
                  color: _isResendButtonEnabled && !_isLoading
                      ? AppColors.primary
                      : AppColors.disabled,
                  width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              disabledForegroundColor: AppColors.disabled,
            ),
            child: Text(
              'Reenviar código',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isResendButtonEnabled && !_isLoading
                    ? AppColors.primary
                    : AppColors.disabled,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isNextButtonEnabled && !_isLoading ? _verifyCode : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isNextButtonEnabled && !_isLoading
                  ? AppColors.primary
                  : AppColors.disabled,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
            child: const Text(
              'Siguiente',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
