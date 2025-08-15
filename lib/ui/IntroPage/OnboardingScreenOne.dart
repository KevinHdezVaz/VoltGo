import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreenOne extends StatelessWidget {
  const OnboardingScreenOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo de la página 1 (no cambia)
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            'assets/images/rectangle1.png',
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
          ),
        ),
        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ▼▼▼ CAMBIO PRINCIPAL ▼▼▼
                // La animación ahora ocupa el espacio disponible de forma flexible.
                Expanded(
                  flex: 2, // Le damos el doble de prioridad de espacio
                  child: Lottie.asset(
                    'assets/images/animation11.json',
                    // Ya no necesitamos 'height' porque Expanded maneja el tamaño.
                  ),
                ),
                // ▲▲▲ FIN DEL CAMBIO ▲▲▲

                // Agrupamos el texto en otro Expanded para que ocupe el espacio restante.
                const Expanded(
                  flex: 1, // Ocupa la mitad de espacio que la animación
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Alinea el texto arriba
                    children: const [
                      Text(
                        '¿Emergencia en el camino?',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Solicita un tecnico y sigue su trayeccto en tiempo real',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
