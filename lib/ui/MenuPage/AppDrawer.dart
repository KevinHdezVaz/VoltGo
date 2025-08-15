import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Voltgo_app/data/services/UserCacheService.dart';
import 'package:Voltgo_app/data/services/notification_service.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/NotificationCountService.dart';

import '../../data/models/User/UserDetail.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback? onNavigate;

  const AppDrawer({
    Key? key,
    required this.onLogout,
    this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_filled,
                    title: 'Inicio',
                    routeName: '/dashboard',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.directions_bus,
                    title: 'Móviles',
                    routeName: '/mobiles',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    routeName: '/dashboard_combined',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.insights,
                    title: 'Auditorías',
                    routeName: '/auditoria',
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    routeName: '/notifications',
                    // Envuelve el badge en un ValueListenableBuilder
                    trailing: ValueListenableBuilder<int>(
                      valueListenable:
                          NotificationCountService.unreadCountNotifier,
                      builder: (context, unreadCount, child) {
                        // Si no hay notificaciones no leídas, no muestra nada.
                        if (unreadCount == 0) {
                          return const SizedBox.shrink();
                        }
                        // Si hay, muestra el badge con el conteo actualizado.
                        return _buildNotificationBadge(unreadCount.toString());
                      },
                    ),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings,
                    title: 'Configuraciones',
                    routeName: '/settings',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            _buildDrawerItem(
              context: context,
              icon: Icons.exit_to_app,
              title: 'Cerrar sesión',
              iconColor: AppColors.ColorFooter,
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
            const Divider(height: 1, color: Colors.black12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenTile({
    required BuildContext context,
    required String title,
    required String? token,
    required IconData icon,
    required Color color,
  }) {
    final bool hasError = token == null ||
        token.contains('Error') ||
        token.contains('denegado') ||
        token.contains('No disponible');
    return ListTile(
      leading: Icon(
        hasError ? Icons.warning_amber_rounded : icon,
        color: hasError ? Colors.red : color,
      ),
      title: Text(title),
      subtitle: SelectableText(
        token ?? 'Obteniendo...',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
        maxLines: 3,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 20.0),
        tooltip: 'Copiar Token',
        onPressed: hasError
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title copiado')),
                );
              },
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return FutureBuilder<UserData?>(
      future: UserCacheService.getCachedUserData(),
      builder: (context, snapshot) {
        String userName = 'Invitado';
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            userName = snapshot.data!.name;
          } else if (snapshot.hasError) {
            userName = 'Error';
            print(
                'Error al cargar datos del usuario desde caché: ${snapshot.error}');
          }
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hola $userName!',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? routeName,
    Widget? trailing,
    Color iconColor = AppColors.ColorFooter,
    VoidCallback? onTap,
  }) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isSelected = currentRoute == routeName;
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.ColorFooter.withOpacity(0.1),
      leading: Icon(icon,
          color: isSelected ? AppColors.ColorFooter : iconColor, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.ColorFooter : Colors.black87,
        ),
      ),
      trailing: trailing,
      onTap: onTap ??
          () {
            onNavigate?.call();
            Navigator.of(context).pop();
            if (routeName != null && !isSelected) {
              Navigator.of(context).pushNamed(routeName);
            }
          },
    );
  }

  Widget _buildNotificationBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _footerLink('Términos y Condiciones'),
          const SizedBox(height: 12),
          _footerLink('Preguntas frecuentes'),
          const SizedBox(height: 12),
          _footerLink('Soporte'),
          const SizedBox(height: 12),
          _footerLink('Acerca de Voltgo Protect'),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ColorFooter,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
