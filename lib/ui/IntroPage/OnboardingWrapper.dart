import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- 1. IMPORTA EL PAQUETE
import 'package:Voltgo_app/ui/IntroPage/OnboardingScreenOne.dart';
import 'package:Voltgo_app/ui/IntroPage/OnboardingScreenThree.dart';
import 'package:Voltgo_app/ui/IntroPage/OnboardingScreenTwo.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  _OnboardingWrapperState createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _onboardingPages = [
    const OnboardingScreenOne(),
    const OnboardingscreenTwo(),
    const OnboardingscreenThree(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _onboardingPages,
              ),
            ),
            _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_onboardingPages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 12.0,
                width: _currentPage == index ? 70.0 : 25.0,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primary
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(5.0),
                ),
              );
            }),
          ),
          ElevatedButton(
            // ▼▼▼ CAMBIO PRINCIPAL: El botón ahora es asíncrono ▼▼▼
            onPressed: () async {
              if (_currentPage < _onboardingPages.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // Si es la última página, guarda el estado y navega
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed', true);

                // Es buena práctica verificar que el widget sigue montado
                // antes de navegar en un contexto asíncrono.
                if (!mounted) return;

                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            // ▲▲▲ FIN DEL CAMBIO ▲▲▲
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            child: Text(
              _currentPage < _onboardingPages.length - 1
                  ? 'Continuar'
                  : 'Empezar',
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
