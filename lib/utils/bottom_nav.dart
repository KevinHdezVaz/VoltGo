import 'package:Voltgo_app/ui/HistoryScreen/HistoryScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/earnins/EarningsScreen.dart';
import 'package:Voltgo_app/ui/profile/SettingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/MenuPage/DashboardScreen.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pages = [
      DriverDashboardScreen(),
      EarningsScreen(),
      HistoryScreen(),
      _buildPlaceholderPage('Progreso'),
      SettingsScreen(),
    ];

    _animationController.forward();
    print('BottomNavBar initialized with index: $_selectedIndex');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeIndex(int index) {
    if (_selectedIndex != index && index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
      print('Navigated to index: $index');
    }
  }

  Widget _buildErrorBoundary({required Widget child}) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          print('Error rendering widget: $e\n$stackTrace');
          return Center(
            child: Text(
              'Error al cargar la página',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPlaceholderPage(String title) {
    return Center(
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.primary, // Primary background color for entire screen
      body: Container(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildErrorBoundary(child: _pages[_selectedIndex]),
            ),
            //... el resto de tu widget ...
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // AHORA LA BARRA DE NAVEGACIÓN ES EL HIJO DIRECTO
              // Se eliminaron el Container, Padding y ClipRRect que la envolvían.
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.white,
                unselectedItemColor: Colors.white70,
                backgroundColor:
                    AppColors.primary, // Este azul ahora cubrirá todo
                currentIndex: _selectedIndex,
                onTap: _changeIndex,
                elevation: 0,
                iconSize: 22,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.electric_car, size: 22),
                    ),
                    label: "Rescues",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.paid_outlined, size: 22),
                    ),
                    label: "Earnings",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.history, size: 22),
                    ),
                    label: "History",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.chat_bubble_outline, size: 22),
                    ),
                    label: "Chat",
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.settings_outlined, size: 22),
                    ),
                    label: "Settings",
                  ),
                ],
              ),
            ),
//... el resto de tu widget ...
          ],
        ),
      ),
    );
  }
}

class PlanFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const PlanFeature({required this.icon, required this.text, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const AnimatedButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: (MediaQuery.of(context).size.width - 32 - 20) / 3 - 10,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.color == AppColors.ColorFooter
                        ? AppColors.textOnPrimary
                        : AppColors.textOnPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
