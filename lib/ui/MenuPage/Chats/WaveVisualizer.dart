import 'package:flutter/material.dart';

class WaveVisualizer extends StatefulWidget {
  final double soundLevel;
  final Color primaryColor;
  final Color secondaryColor;

  const WaveVisualizer({
    Key? key,
    required this.soundLevel,
    this.primaryColor = const Color(0xFF4ECDC4),
    this.secondaryColor = const Color(0xFF88D5C2),
  }) : super(key: key);

  @override
  _WaveVisualizerState createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _soundLevels = List.filled(30, 0.0); // Historial de niveles de sonido
  int _currentIndex = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Rápido para transiciones responsivas
    );
  }

  @override
  void didUpdateWidget(covariant WaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualiza el historial de soundLevel
    _soundLevels[_currentIndex] = widget.soundLevel;
    _currentIndex = (_currentIndex + 1) % _soundLevels.length;

    // Detecta si hay habla
    final isSpeaking = widget.soundLevel.abs() > 0.5; // Umbral para habla
    if (isSpeaking != _isSpeaking) {
      setState(() {
        _isSpeaking = isSpeaking;
      });
      if (isSpeaking) {
        _controller.repeat(reverse: true); // Suave oscilación para efecto dinámico
      } else {
        _controller.stop();
        _controller.reset();
        _soundLevels.fillRange(0, _soundLevels.length, 0.0); // Limpia el historial
        _currentIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: EqualizerPainter(
              soundLevels: _soundLevels,
              currentIndex: _currentIndex,
              animationValue: _controller.value,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              isSpeaking: _isSpeaking,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

class EqualizerPainter extends CustomPainter {
  final List<double> soundLevels;
  final int currentIndex;
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isSpeaking;

  EqualizerPainter({
    required this.soundLevels,
    required this.currentIndex,
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isSpeaking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 20; // Número de barras
    final barWidth = size.width / (barCount * 1.5); // Ancho de cada barra
    final maxBarHeight = size.height * 0.7; // Altura máxima de las barras
    final spacing = barWidth * 0.5; // Espacio entre barras

    final gradient = LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Dibujar barras
    for (int i = 0; i < barCount; i++) {
      // Mapear la posición de la barra al historial de soundLevels
      final index = (currentIndex - (barCount - i - 1) * (soundLevels.length ~/ barCount)).clamp(0, soundLevels.length - 1);
      final soundLevel = soundLevels[index].abs();
      final normalizedLevel = (soundLevel / 50).clamp(0.0, 1.0);

      // Calcular la altura de la barra
      final baseHeight = isSpeaking ? normalizedLevel * maxBarHeight : 2.0; // Mínima altura cuando no habla
      final animatedHeight = baseHeight * (0.8 + 0.2 * (isSpeaking ? animationValue : 0)); // Suave oscilación

      // Posición de la barra
      final x = i * (barWidth + spacing) + spacing / 2;
      final yTop = size.height / 2 - animatedHeight / 2;
      final yBottom = size.height / 2 + animatedHeight / 2;

      // Dibujar sombra/glow
      if (isSpeaking && animatedHeight > 2.0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x, yTop - 2, x + barWidth, yBottom + 2),
            const Radius.circular(4),
          ),
          glowPaint,
        );
      }

      // Dibujar barra
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x, yTop, x + barWidth, yBottom),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EqualizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.soundLevels != soundLevels ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.isSpeaking != isSpeaking;
  }
}