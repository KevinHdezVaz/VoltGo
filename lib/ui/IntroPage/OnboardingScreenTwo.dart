import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:lottie/lottie.dart';

class OnboardingscreenTwo extends StatelessWidget {
  const OnboardingscreenTwo({Key? key}) : super(key: key);

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
    // Este widget no necesita cambios.
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          right: 0,
          child: Transform.rotate(
            angle: 0.0,
            child: Image.asset(
              'assets/images/rectangle2_2.png',
              width: MediaQuery.of(context).size.width * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Image.asset(
            'assets/images/rectangle2.png',
            width: MediaQuery.of(context).size.width * 0.55,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    // ▼▼▼ CAMBIO PRINCIPAL: Se aplica la misma estructura con Expanded ▼▼▼
    return Padding(
      // Añadimos un poco de padding vertical para que no quede pegado a los bordes
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        children: [
          // La animación ahora ocupa el espacio flexible superior
          Expanded(
            flex: 2, // Ocupa 2/3 del espacio disponible
            child: Lottie.asset(
              'assets/images/animation22.json', // Asegúrate de que la ruta sea correcta
              // Ya no se necesita 'height', Expanded lo controla
            ),
          ),

          // El texto ocupa el espacio flexible inferior
          const Expanded(
            flex: 1, // Ocupa 1/3 del espacio disponible
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Alinea el texto hacia arriba
              children: const [
                SizedBox(height: 20), // Espacio para separar de la animación
                Text(
                  'Profesionales capacitados y verificados.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Contamos con personal capacitado para tu tipo de vehiculo y con certificaciones.',
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
    // ▲▲▲ FIN DEL CAMBIO ▲▲▲
  }
}
