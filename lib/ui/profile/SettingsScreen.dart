import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.textOnPrimary,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        shadowColor: AppColors.gray300.withOpacity(0.3),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
        children: [
          // --- Sección de Cuenta ---
          _buildSectionHeader('Cuenta'),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            onTap: () {/* TODO: Navegar a la pantalla de editar perfil */},
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Seguridad y Contraseña',
            onTap: () {/* TODO: Navegar a la pantalla de seguridad */},
          ),
          _buildSettingsItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Métodos de Pago',
            onTap: () {/* TODO: Navegar a la pantalla de pagos */},
          ),
          const Divider(height: 32, color: AppColors.gray300),

          // --- Sección de Vehículo ---
          _buildSectionHeader('Vehículo'),
          _buildSettingsItem(
            icon: Icons.directions_car_outlined,
            title: 'Gestionar Vehículos',
            onTap: () {/* TODO: Navegar a la pantalla de vehículos */},
          ),
          _buildSettingsItem(
            icon: Icons.article_outlined,
            title: 'Documentos',
            onTap: () {/* TODO: Navegar a la pantalla de documentos */},
          ),
          const Divider(height: 32, color: AppColors.gray300),

          // --- Sección de Preferencias ---
          _buildSectionHeader('Preferencias'),
          _buildSwitchItem(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          _buildSwitchItem(
            icon: Icons.dark_mode_outlined,
            title: 'Modo Oscuro',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() => _darkModeEnabled = value);
              // TODO: Implementar lógica para cambiar el tema
            },
          ),
          const Divider(height: 32, color: AppColors.gray300),

          // --- Sección de Soporte ---
          _buildSectionHeader('Soporte'),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Centro de Ayuda',
            onTap: () {/* TODO: Navegar al centro de ayuda */},
          ),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'Términos y Condiciones',
            onTap: () {/* TODO: Navegar a términos y condiciones */},
          ),
          const SizedBox(height: 24),

          // --- Botón de Cerrar Sesión ---
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shadowColor: AppColors.gray300.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, color: AppColors.brandBlue, size: 28),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shadowColor: AppColors.gray300.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Icon(icon, color: AppColors.brandBlue, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
        activeTrackColor: AppColors.accent.withOpacity(0.4),
        inactiveThumbColor: AppColors.disabled,
        inactiveTrackColor: AppColors.lightGrey,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shadowColor: AppColors.error.withOpacity(0.3),
      color: AppColors.error.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Mostrar diálogo de confirmación
          print("Cerrar sesión presionado");
        },
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.logout, color: AppColors.error, size: 28),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}
