import 'package:flutter/foundation.dart';
import 'package:Voltgo_app/data/models/NotificationItem.dart';
import 'package:Voltgo_app/data/models/alert/NotificationPermissions.dart';
import 'package:Voltgo_app/data/services/NotificationsService.dart'; // Servicio de permisos
import 'package:Voltgo_app/utils/ReadStatusManager.dart';

/// Gestiona el estado del contador de notificaciones no leídas.
class NotificationCountService {
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Actualiza el contador obteniendo todos los datos y aplicando los permisos del usuario.
  static Future<void> updateCount() async {
    try {
      // 1. Obtiene toda la información necesaria en paralelo.
      final results = await Future.wait([
        NotificationService.getNotifications(),
        ReadStatusManager.getReadNotificationIds(),
        NotificationService
            .getNotificationPermissions(), // <-- AÑADIDO: Obtiene los permisos
      ]);

      final notificationData = results[0] as NotificationData;
      final readIds = results[1] as Set<int>;
      final permissions = results[2] as NotificationPermissions;

      final allNotifications = [
        ...notificationData.todayNotifications,
        ...notificationData.previousNotifications
      ];

      // 2. Si las notificaciones generales están desactivadas, el contador es 0.
      if (!permissions.allowNotification) {
        unreadCountNotifier.value = 0;
        return;
      }

      // 3. Calcula el contador aplicando los filtros de permisos.
      int unreadCount = 0;
      for (var notification in allNotifications) {
        final bool isUnread = !readIds.contains(notification.id);
        final bool isAllowedByType =
            _isNotificationTypeAllowed(notification, permissions);

        // Solo cuenta si no está leída Y si su tipo está permitido por el usuario.
        if (isUnread && isAllowedByType) {
          unreadCount++;
        }
      }

      // 4. Actualiza el valor del notificador.
      unreadCountNotifier.value = unreadCount;
    } catch (e) {
      debugPrint("Error al actualizar el contador de notificaciones: $e");
    }
  }

  /// Función auxiliar para verificar si un tipo de notificación está activado.
  static bool _isNotificationTypeAllowed(
      Notification notification, NotificationPermissions permissions) {
    final alertPermissions = permissions.alertPermissions;
    switch (notification.type) {
      case 'Velocidad Maxima':
        return alertPermissions.maxSpeed;
      case 'descanso corto':
        return alertPermissions.shortBreak;
      case 'No presentación en destino':
        return alertPermissions.noArrivalAtDestination;
      case 'conduccion 10 Horas':
        return alertPermissions.tenHoursDriving;
      case 'conduccion continua':
        return alertPermissions.continuousDriving;
      default:
        return true; // Si el tipo no coincide, por defecto se permite.
    }
  }

  /// Decrementa el contador en uno (no necesita cambios).
  static void decrementCount() {
    if (unreadCountNotifier.value > 0) {
      unreadCountNotifier.value--;
    }
  }
}
