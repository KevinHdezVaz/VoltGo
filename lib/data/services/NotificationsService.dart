import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/data/models/NotificationItem.dart';
import 'package:Voltgo_app/data/models/alert/NotificationPermissions.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';

class NotificationService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<NotificationPermissions> getNotificationPermissions() async {
    final url =
        Uri.parse('${Constants.baseUrl}/user/get-notifications-permission');

    debugPrint('[NotificationService] 🔄 Iniciando solicitud GET a: $url');

    try {
      debugPrint(
          '[NotificationService] Obteniendo headers de autenticación...');
      final headers = await _getAuthHeaders();
      debugPrint('[NotificationService] Headers a enviar:');
      headers.forEach((key, value) {
        debugPrint('  $key: ${key == 'Authorization' ? 'Bearer ***' : value}');
      });
      debugPrint('[NotificationService] Enviando solicitud GET...');
      final response = await http.get(
        url,
        headers: headers,
      );
      debugPrint('[NotificationService] 🔵 Respuesta recibida:');
      debugPrint('  Status Code: ${response.statusCode}');
      debugPrint('  Headers: ${response.headers}');
      debugPrint('  Body: ${response.body}');
      if (response.statusCode == 200) {
        try {
          final String responseBody = utf8.decode(response.bodyBytes);
          final Map<String, dynamic> data = jsonDecode(responseBody);
          debugPrint('[NotificationService] ✅ Datos parseados correctamente');
          return NotificationPermissionsResponse.fromJson(data).data;
        } catch (e) {
          debugPrint('[NotificationService] ❌ Error al parsear respuesta: $e');
          throw Exception('Error al procesar la respuesta del servidor');
        }
      } else if (response.statusCode == 401) {
        debugPrint('[NotificationService] ❌ Error 401 - Detalle completo:');
        debugPrint('  URL: $url');
        debugPrint('  Headers enviados: $headers');
        debugPrint('  Body recibido: ${response.body}');
        throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión');
      } else {
        debugPrint('[NotificationService] ❌ Error ${response.statusCode}');
        throw Exception('Error al obtener permisos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          '[NotificationService] ❌ Error en getNotificationPermissions: $e');
      rethrow;
    }
  }

  static Future<bool> updateSingleNotificationPermission({
    required String name,
    required bool value,
  }) async {
    final url =
        Uri.parse('${Constants.baseUrl}/user/change-notification-permissions');

    debugPrint(
        '[NotificationService] 🔄 Iniciando solicitud POST individual a: $url');

    try {
      final payload = {
        'name': name,
        'value': value,
      };

      debugPrint('[NotificationService] Payload individual a enviar:');
      debugPrint(jsonEncode(payload));
      final headers = await _getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      debugPrint('[NotificationService] 🔵 Respuesta recibida (individual):');
      debugPrint('  Status Code: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint(
            '[NotificationService] ✅ Permiso individual actualizado correctamente');
        return true;
      } else {
        debugPrint(
            '[NotificationService] ❌ Error ${response.statusCode} en actualización individual');
        debugPrint('  Detalle: ${response.body}');
        throw Exception(
            'Error al actualizar permiso individual: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          '[NotificationService] ❌ Error en updateSingleNotificationPermission: $e');
      rethrow;
    }
  }

  /// **1. Obtiene la lista de notificaciones (con paginación opcional).**
  ///
  /// Llama a `GET /user/get-notifications` o `GET /user/get-notifications/{page}`.
  static Future<NotificationData> getNotifications({int? page}) async {
    // Construye la URL base y añade la página si se proporciona.
    String urlString = '${Constants.baseUrl}/user/get-notifications';
    if (page != null) {
      urlString += '/$page';
    }
    final url = Uri.parse(urlString);

    debugPrint('[NotificationApiService] 🔄 Iniciando GET a: $url');

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      debugPrint('[NotificationApiService] 🔵 Respuesta de getNotifications:');
      debugPrint('  Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        debugPrint(
            '[NotificationApiService] ✅ Notificaciones obtenidas correctamente.');
        // Se parsea la respuesta usando el modelo NotificationsResponse y se devuelve el objeto 'data'
        return NotificationsResponse.fromJson(responseBody).data;
      } else if (response.statusCode == 401) {
        debugPrint('[NotificationApiService] ❌ Error 401: Sesión expirada.');
        throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión');
      } else {
        debugPrint(
            '[NotificationApiService] ❌ Error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Error al obtener las notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[NotificationApiService] ❌ Error en getNotifications: $e');
      rethrow; // Re-lanza la excepción para que sea manejada por la UI.
    }
  }

  /// **2. Obtiene el detalle de una notificación específica.**
  ///
  /// Llama a `GET /user/get-notification-detail/{id}`.
  static Future<NotificationDetail> getNotificationDetail(
      {required int notificationId}) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/user/get-notification-detail/$notificationId');

    debugPrint('[NotificationApiService] 🔄 Iniciando GET a: $url');

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      debugPrint(
          '[NotificationApiService] 🔵 Respuesta de getNotificationDetail:');
      debugPrint('  Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        debugPrint(
            '[NotificationApiService] ✅ Detalle de notificación obtenido.');
        // Se parsea la respuesta usando el modelo NotificationDetailResponse
        return NotificationDetailResponse.fromJson(responseBody).data;
      } else if (response.statusCode == 401) {
        debugPrint('[NotificationApiService] ❌ Error 401: Sesión expirada.');
        throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión');
      } else {
        debugPrint(
            '[NotificationApiService] ❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al obtener el detalle: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
          '[NotificationApiService] ❌ Error en getNotificationDetail: $e');
      rethrow;
    }
  }

  /// **3. Marca una notificación como leída.**
  ///
  /// Llama a `POST /user/set-notification-read`.
  static Future<bool> setNotificationRead({required int notificationId}) async {
    final url = Uri.parse('${Constants.baseUrl}/user/set-notification-read');

    debugPrint('[NotificationApiService] 🔄 Iniciando POST a: $url');

    try {
      final headers = await _getAuthHeaders();
      final payload =
          jsonEncode({'notification_id': notificationId.toString()});

      debugPrint('[NotificationApiService] Payload a enviar: $payload');

      final response = await http.post(
        url,
        headers: headers,
        body: payload,
      );

      debugPrint(
          '[NotificationApiService] 🔵 Respuesta de setNotificationRead:');
      debugPrint('  Status Code: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint(
            '[NotificationApiService] ✅ Notificación marcada como leída.');
        // Opcional: podrías parsear la respuesta si quisieras usar el mensaje.
        // final responseData = SetNotificationReadResponse.fromJson(response.body);
        // debugPrint(responseData.message);
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('[NotificationApiService] ❌ Error 401: Sesión expirada.');
        throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión');
      } else {
        debugPrint(
            '[NotificationApiService] ❌ Error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Error al marcar la notificación como leída: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[NotificationApiService] ❌ Error en setNotificationRead: $e');
      rethrow;
    }
  }
}
