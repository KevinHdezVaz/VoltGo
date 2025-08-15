import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:lottie/lottie.dart';

class OnboardingscreenThree extends StatelessWidget {
  const OnboardingscreenThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(context),
        Center(
          child: _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    // This widget remains unchanged
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
    return Padding(
      // Add vertical padding for better spacing
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        children: [
          // Animation now uses Expanded for flexible sizing
          Expanded(
            flex: 2, // Takes up 2/3 of the available space
            child: Lottie.asset(
              'assets/images/animation3.json', // Make sure this path is correct
            ),
          ),

          // Text content also uses Expanded
          const Expanded(
            flex: 1, // Takes up 1/3 of the available space
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                SizedBox(height: 20),
                Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Infórmate sobre promociones, eventos y noticias relevantes de la app.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
