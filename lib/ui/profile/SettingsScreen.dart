import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:Voltgo_User/data/services/auth_api_service.dart';
import 'package:Voltgo_User/ui/login/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;

  late Future<UserModel?> _userFuture;

  bool _darkModeEnabled = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // ▼▼▼ 3. LLAMA AL SERVICIO CUANDO LA PANTALLA SE INICIA ▼▼▼
    _userFuture = AuthService.fetchUserProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.textOnPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: AppColors.gray300.withOpacity(0.4),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.lightGrey.withOpacity(0.5)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0)
              .copyWith(bottom: 130.0),
          children: [
            FutureBuilder<UserModel?>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Muestra un loader mientras carga
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  // Muestra un estado de error si algo falla
                  return _buildProfileHeader(
                      name: 'Error', email: 'No se pudo cargar el perfil');
                }
                // Si todo sale bien, muestra los datos del usuario
                final user = snapshot.data!;
                return _buildProfileHeader(name: user.name, email: user.email);
              },
            ),
            const SizedBox(height: 24),
            // Account Section
            _buildSectionHeader('Cuenta'),
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: 'Editar Perfil',
              onTap: () {
                // TODO: Navigate to edit profile screen
              },
            ),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Seguridad y Contraseña',
              onTap: () {
                // TODO: Navigate to security screen
              },
            ),
            _buildSettingsItem(
              icon: Icons.chat,
              title: 'Mensajes',
              onTap: () {
                // TODO: Navigate to payments screen
              },
            ),

            _buildSettingsItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Métodos de Pago',
              onTap: () {
                // TODO: Navigate to payments screen
              },
            ),
            const Divider(height: 32, color: AppColors.gray300),
            // Vehicle Section
            _buildSectionHeader('Vehículo'),
            _buildSettingsItem(
              icon: Icons.directions_car_outlined,
              title: 'Gestionar Vehículos',
              onTap: () {
                // TODO: Navigate to vehicles screen
              },
            ),
            _buildSettingsItem(
              icon: Icons.article_outlined,
              title: 'Documentos',
              onTap: () {
                // TODO: Navigate to documents screen
              },
            ),
            // Preferences Section

            const Divider(height: 32, color: AppColors.gray300),
            const SizedBox(height: 24),
            // Logout Button
            _buildLogoutButton(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to edit profile or primary action
          HapticFeedback.lightImpact();
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.edit, color: AppColors.textOnPrimary),
        elevation: 4,
        tooltip: 'Editar Perfil',
      ),
    );
  }

  Widget _buildProfileHeader({required String name, required String email}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightGrey, AppColors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child:
                  Icon(Icons.person, size: 32, color: AppColors.textOnPrimary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, // Usa el nombre del parámetro
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email, // Usa el email del parámetro
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shadowColor: AppColors.gray300.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Icon(icon, color: AppColors.brandBlue, size: 28),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: AppColors.gray300.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            secondary: Icon(icon, color: AppColors.brandBlue, size: 28),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withOpacity(0.5),
            inactiveThumbColor: AppColors.disabled,
            inactiveTrackColor: AppColors.lightGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () async {
        HapticFeedback.mediumImpact();
        await AuthService.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 3,
          shadowColor: AppColors.error.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 50,
                ),
                leading: Icon(Icons.logout, color: AppColors.error, size: 28),
                title: Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
