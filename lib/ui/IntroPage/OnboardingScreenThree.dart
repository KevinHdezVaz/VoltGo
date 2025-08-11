import 'package:flutter/material.dart';
import 'package:wisetrack_app/ui/color/app_colors.dart';
import 'package:wisetrack_app/utils/Preferences.dart';

class OnboardingscreenThree extends StatelessWidget {
  final PageController pageController;

  const OnboardingscreenThree({Key? key, required this.pageController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackground(context),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/images/rectangle3.png',
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            'assets/images/rectangle1.png',
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Image.asset(
              'assets/images/introPage3.png',
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            const Spacer(flex: 1),
            const Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Infórmate sobre los diferentes eventos.',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
            _buildNavigation(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            _buildIndicator(isActive: false, width: 20.0),
            const SizedBox(width: 8),
            _buildIndicator(isActive: false, width: 20.0),
            const SizedBox(width: 8),
            _buildIndicator(isActive: true, width: 80.0),
          ],
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await Preferences.setOnboardingSeen();
            } catch (e) {
              print('Error setting onboarding status: $e');
            }
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 5,
          ),
          child: const Text(
            'Continuar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator({required bool isActive, double width = 8.0}) {
    return Container(
      width: width,
      height: 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}
