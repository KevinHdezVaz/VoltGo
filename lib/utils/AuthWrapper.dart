import 'package:flutter/material.dart';
import 'package:wisetrack_app/utils/Preferences.dart';
import 'package:wisetrack_app/data/services/auth_api_service.dart';
import 'package:wisetrack_app/utils/AnimatedTruckProgress.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), 
    );
    _checkSessionAndRedirect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndRedirect() async {
    _animationController.repeat(); // Start animation
    await Future.delayed(const Duration(milliseconds: 100)); // Small delay

    final bool isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) {
      _animationController.stop();
      return;
    }

    if (isLoggedIn) {
      _animationController.stop(); // Stop animation
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      bool hasSeenOnboarding = false;
      try {
        hasSeenOnboarding = await Preferences.hasSeenOnboarding();
      } catch (e) {
        print('Error checking onboarding status: $e');
        hasSeenOnboarding = false;
      }

      if (!mounted) {
        _animationController.stop();
        return;
      }

      _animationController.stop(); // Stop animation
      if (hasSeenOnboarding) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
    _animationController.reset(); // Reset animation after navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedTruckProgress(
          animation: _animationController,
        ),
      ),
    );
  }
}