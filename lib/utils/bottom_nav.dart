import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Asegúrate de que las rutas a tus pantallas y colores sean correctas ---
import 'package:Voltgo_User/ui/MenuPage/DashboardScreen.dart'; // Asegúrate que esta es la pantalla correcta
import 'package:Voltgo_User/ui/HistoryScreen/HistoryScreen.dart';
import 'package:Voltgo_User/ui/profile/SettingsScreen.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    PassengerMapScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ▼▼▼ ¡ESTA ES LA LÍNEA CLAVE QUE SOLUCIONA EL PROBLEMA! ▼▼▼
      extendBody: true,

      body: _pages[_selectedIndex],

      floatingActionButton: SizedBox(
        width: 64.0,
        height: 64.0,
        child: FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: () => _onItemTapped(0),
          backgroundColor: AppColors.primary,
          elevation: 6.0,
          shape: const CircleBorder(),
          child: const Icon(Icons.bolt, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: AppColors.primary,
        elevation: 9.0,
        shadowColor: Colors.black.withOpacity(0.3),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              icon: Icons.history,
              label: 'Historial',
              index: 1,
            ),
            const SizedBox(width: 40), // Espacio para el botón central
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Cuenta',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ... (El resto de tu código, como _buildNavItem, no necesita cambios)
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
