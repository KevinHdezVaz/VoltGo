import 'dart:convert';
import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ServiceRequestService {
  /// ✅ CORREGIDO: createRequest con mejor manejo de errores
  static Future<ServiceRequestModel> createRequest(LatLng location) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'request_lat': location.latitude,
      'request_lng': location.longitude,
    });

    try {
      print(
          '🚀 Creating request at: ${location.latitude}, ${location.longitude}');
      final response = await http.post(url, headers: headers, body: body);

      print('📡 Create request response status: ${response.statusCode}');
      print('📡 Create request response body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ServiceRequestModel.fromJson(jsonData);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'No hay técnicos disponibles');
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error del servidor'};
        throw Exception(errorData['message'] ??
            'Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in createRequest: $e');
      rethrow;
    }
  }

  static Future<void> cancelRequest(int requestId) async {
    // ✅ CAMBIO PRINCIPAL: Usar la ruta correcta que coincide con el backend
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/cancel');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Sending cancel request to: $url');
      final response = await http.post(url, headers: headers);

      print('📡 Cancel request response status: ${response.statusCode}');
      print('📡 Cancel request response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Solicitud cancelada exitosamente');
        return;
      } else {
        // Manejar diferentes códigos de error
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};

        String errorMessage =
            errorData['message'] ?? 'Error al cancelar la solicitud';

        // Agregar información específica según el código de error
        switch (response.statusCode) {
          case 403:
            errorMessage =
                'No tienes autorización para cancelar esta solicitud';
            break;
          case 404:
            errorMessage = 'La solicitud no fue encontrada';
            break;
          case 409:
            errorMessage = 'Ya no es posible cancelar esta solicitud';
            break;
          default:
            errorMessage = 'Error del servidor: ${response.statusCode}';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error in cancelRequest: $e');
      rethrow;
    }
  }

  /// ✅ CORREGIDO: getRequestStatus usando la ruta correcta
  static Future<ServiceRequestModel> getRequestStatus(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/status');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Getting status for request: $requestId');
      final response = await http.get(url, headers: headers);

      print('📡 Get status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ServiceRequestModel.fromJson(jsonData);
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error al obtener estado'};
        throw Exception(
            errorData['message'] ?? 'Error al obtener estado de la solicitud');
      }
    } catch (e) {
      print('❌ Error in getRequestStatus: $e');
      rethrow;
    }
  }

  /// ✅ CORREGIDO: getTechnicianLocation
  static Future<LatLng?> getTechnicianLocation(int requestId) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/request/$requestId/technician-location');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LatLng(
          double.parse(data['current_lat'].toString()),
          double.parse(data['current_lng'].toString()),
        );
      } else if (response.statusCode == 404) {
        print('ℹ️ Technician location not available');
        return null;
      }
      return null;
    } catch (e) {
      print('❌ Error getting technician location: $e');
      return null;
    }
  }

  static Future<List<ServiceRequestModel>> getServiceHistory() async {
    final url = Uri.parse('${Constants.baseUrl}/service/history');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Getting service history');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((json) => ServiceRequestModel.fromJson(json))
            .toList();
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error al obtener historial'};
        throw Exception(errorData['message'] ?? 'Error al obtener historial');
      }
    } catch (e) {
      print('❌ Error getting service history: $e');
      rethrow;
    }
  }

// ✅ NUEVO: Método en ServiceRequestService para verificar servicios cerca de expirar
  static Future<List<Map<String, dynamic>>> getServicesNearExpiration() async {
    final url = Uri.parse('${Constants.baseUrl}/service/near-expiration');
    final token = await TokenStorage.getToken();
    if (token == null) return [];

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data['services_near_expiration'] ?? []);
      }
    } catch (e) {
      print('Error getting services near expiration: $e');
    }

    return [];
  }

// En ServiceRequestService.dart - reemplazar el método existente:
  static Future<ServiceRequestModel?> getActiveService() async {
    final url = Uri.parse('${Constants.baseUrl}/service/active');
    final token = await TokenStorage.getToken();
    if (token == null) {
      print('❌ Token no encontrado para getActiveService');
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Getting active services from: $url');
      final response = await http.get(url, headers: headers);

      print('📡 Active services response: ${response.statusCode}');
      print('📡 Active services body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['has_active_services'] == true &&
            data['active_services'] != null &&
            data['active_services'].isNotEmpty) {
          final List<dynamic> activeServices = data['active_services'];
          final activeServiceData = activeServices.first;

          print('✅ Servicio activo encontrado en servidor');
          return ServiceRequestModel.fromJson(activeServiceData);
        } else {
          print('ℹ️ No hay servicios activos según el servidor');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ No active services (404)');
        return null;
      } else {
        print(
            '❌ Error getting active services: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting active service: $e');
      return null;
    }
  }

  static Future<bool> hasActiveService() async {
    try {
      final history = await getServiceHistory();

      // Buscar solicitudes activas
      final activeServices = history
          .where(
            (request) => [
              'pending',
              'accepted',
              'en_route',
              'on_site',
              'charging'
            ].contains(request.status),
          )
          .toList();

      return activeServices.isNotEmpty;
    } catch (e) {
      print('❌ Error checking for active service: $e');
      return false;
    }
  }

  /// Obtiene información detallada del estado de la solicitud incluyendo ubicación del técnico.
  static Future<Map<String, dynamic>> getDetailedRequestStatus(
      int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/status');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener estado detallado: ${response.body}');
    }
  }
}
