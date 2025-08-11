import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona el estado de "leído" de las notificaciones localmente en el dispositivo.
class ReadStatusManager {
  // Nueva clave para los IDs numéricos de las notificaciones.
  static const _readNotificationsKey = 'read_notification_ids';

  // El método getUniqueId ya no es necesario y se ha eliminado.

  /// Obtiene el conjunto de IDs de notificaciones que han sido marcadas como leídas.
  ///
  /// Devuelve un `Set<int>` para un rendimiento de búsqueda óptimo (O(1)).
  static Future<Set<int>> getReadNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Los IDs se guardan como una lista de strings.
    final List<String> readIdsAsString = prefs.getStringList(_readNotificationsKey) ?? [];
    
    // Se convierten a un Set de enteros para su uso en la app.
    return readIdsAsString.map((id) => int.tryParse(id) ?? 0).toSet();
  }

  /// Marca una notificación como leída guardando su ID numérico.
  ///
  /// [notificationId] es el ID único de la notificación proveniente de la API.
  static Future<void> markNotificationAsRead(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Se obtiene la lista actual de IDs (como strings).
    final List<String> readIdsAsString = prefs.getStringList(_readNotificationsKey) ?? [];
    final String idString = notificationId.toString();

    // Se añade el nuevo ID solo si no existe previamente.
    if (!readIdsAsString.contains(idString)) {
      readIdsAsString.add(idString);
      await prefs.setStringList(_readNotificationsKey, readIdsAsString);
    }
  }
}