import 'package:flutter/material.dart';

class AppColors {
  // Evita que esta clase pueda ser instanciada.
  AppColors._();

  // --- BRAND COLORS ---
  /// Azul oscuro del logo. Es el color principal de la marca.
  static const Color primary = Color(0xFF19478A);

  static const Color brandBlue = Color(0xFF19478A);
  static const Color ColorFooter = Color.fromARGB(255, 107, 146, 203);

  static const Color gray300 = Color(0xFFE0E0E0);

  /// Verde eléctrico del logo. Se usa para botones, acentos y elementos que deben resaltar.
  static const Color accent = Color(0xFF76FF03);

  // --- UI & THEME COLORS ---
  /// Un color para elementos secundarios o enlaces, derivado del tema original.
  static const Color secondaryLink = Color(0xFF008C95);

  // --- NEUTRAL & TEXT COLORS ---
  /// Color principal para textos oscuros.
  static const Color textPrimary = Color(0xFF212121); // gray900

  /// Color para textos secundarios o menos importantes.
  static const Color textSecondary = Color(0xFF757575); // gray500

  /// Color de texto sobre fondos oscuros (como el primario).
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Color de texto sobre fondos claros.
  static const Color textOnLight = Color(0xFF000000);

  /// Blanco puro.
  static const Color white = Color(0xFFFFFFFF);

  /// Negro puro.
  static const Color black = Color(0xFF000000);

  /// Gris para bordes o divisores.
  static const Color border = Color(0xFFE0E0E0); // gray300

  /// Gris claro para fondos de inputs o elementos deshabilitados.
  static const Color lightGrey = Color(0xFFF5F5F5); // Un gris muy claro

  static const Color textDark =
      Color.fromARGB(255, 77, 77, 77); // Un gris muy claro

  static const Color disabled =
      Color.fromARGB(255, 175, 175, 175); // Un gris muy claro

  // --- SEMANTIC COLORS ---
  /// Color para indicar éxito.
  static const Color success = Color(0xFF4CAF50);

  /// Color para indicar advertencias.
  static const Color warning = Color(0xFFFFC107);

  /// Color para indicar errores.
  static const Color error = Color(0xFFF44336);

  /// Color para mensajes informativos.
  static const Color info = Color(0xFF2196F3);

  // --- BACKGROUND COLORS ---
  /// Color de fondo principal para las pantallas.
  static const Color background = white;
}
