import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'custom_dialogs.dart';

class SecurityActionsScreen extends StatelessWidget {
  final String plate;

  const SecurityActionsScreen({
    Key? key,
    required this.plate, // El constructor ahora requiere la patente.
  }) : super(key: key);
  Future<bool> _simulateApiCall() async {
    await Future.delayed(const Duration(seconds: 2));
    return (DateTime.now().second % 10) < 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: _buildBackButton(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones de seguridad',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Vehículo: $plate', // Muestra la patente recibida
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildSectionTitle('Combustible'),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.local_gas_station_outlined,
            label: 'Corte de combustible',
            onTap: () {
              showWarningDialog(
                context,
                title: 'Cortar combustible',
                subtitle: 'Esta acción es crítica. ¿Estás seguro de continuar?',
                onConfirm: () async {
                  bool success = await _simulateApiCall();
                  if (success) {
                    showSuccessDialog(context,
                        title: 'Corte realizado',
                        subtitle: 'El combustible ha sido cortado con éxito.');
                  } else {
                    showErrorDialog(context);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.power_settings_new_outlined,
            label: 'Activar combustible',
            onTap: () {
              showWarningDialog(
                context,
                title: 'Activar combustible',
                subtitle: '¿Estás seguro de que deseas realizar esta acción?',
                onConfirm: () async {
                  bool success = await _simulateApiCall();
                  if (success) {
                    showSuccessDialog(context,
                        title: 'Combustible activado',
                        subtitle: 'La acción se ha realizado con éxito.');
                  } else {
                    showErrorDialog(context);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.password,
            label: 'Código de corte',
            onTap: () {},
          ),
          const SizedBox(height: 30),
          _buildSectionTitle('Chapa randómica'),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.lock_open_outlined,
            label: 'Destrabar chapa randómica',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.lock_outline,
            label: 'Trabar chapa randómica',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.password,
            label: 'Código de chapa randómica',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        'assets/images/backbtn.png',
        width: 40,
        height: 40,
      ),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
