import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wisetrack_app/data/models/alert/AlertModel.dart';
import 'package:wisetrack_app/utils/TokenStorage.dart';
import 'package:wisetrack_app/utils/constants.dart';

class AlertService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<bool> markAlertAsRead({
    required String plate,
    required String
        alertDate, // Usamos patente y fecha para identificar la alerta
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/alert/mark-as-read');

    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({
        'plate': plate,
        'alert_date': alertDate,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        debugPrint('AlertService: Alerta marcada como leída exitosamente.');
        return true;
      } else {
        debugPrint(
            'AlertService: Error al marcar como leída. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('AlertService: Excepción en markAlertAsRead: $e');
      return false;
    }
  }

  static Future<int> getUnreadAlertsCount() async {
    try {
      final allAlerts = await getAlerts();
      final unreadCount = allAlerts.where((alert) => alert.status == 0).length;

      debugPrint(
          'AlertService: Total de alertas: ${allAlerts.length}, No leídas: $unreadCount');
      return unreadCount;
    } catch (e) {
      debugPrint('Error en getUnreadAlertsCount: $e');
      return 0; // Si hay un error, devolvemos 0 para no romper la UI.
    }
  }

  static Future<List<AlertType>> getAlertTypes() async {
    final url = Uri.parse('${Constants.baseUrl}/alert/get-types');

    debugPrint('AlertService: Obteniendo tipos de alerta de: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'AlertService: Respuesta tipos ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final typesResponse = AlertTypesResponse.fromJson(data);
        return typesResponse.data;
      } else {
        throw Exception('Failed to load alert types: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AlertService: Error en getAlertTypes: $e');
      throw Exception('Alert types request failed: $e');
    }
  }

  static Future<List<Alertas>> getAlertsByType(int typeId) async {
    final url = Uri.parse('${Constants.baseUrl}/alert/get-by-type/$typeId');

    debugPrint('AlertService: Obteniendo alertas por tipo: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final alertsResponse = AlertsResponse.fromJson(data);
        return alertsResponse.data;
      } else {
        throw Exception(
            'Failed to load alerts by type: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AlertService: Error en getAlertsByType: $e');
      throw Exception('Alerts by type request failed: $e');
    }
  }

  static Future<List<Alertas>> getAlerts() async {
    final url = Uri.parse('${Constants.baseUrl}/alert/get');

    debugPrint('AlertService: Realizando GET a: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'AlertService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(responseBody);

        final alertsResponse = AlertsResponse.fromJson(data);
        return alertsResponse.data;
      } else {
        throw Exception(
            'Failed to load alerts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AlertService: Error en getAlerts: $e');
      throw Exception('Alerts request failed: $e');
    }
  }
}
