import 'dart:convert';

import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;

class ServiceRequestService {
  /// Crea una nueva solicitud de servicio en el backend.
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

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      return ServiceRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear la solicitud: ${response.body}');
    }
  }

  static Future<void> cancelRequest(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/cancel');

    final token = await TokenStorage.getToken();

    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error al cancelar la solicitud: ${response.body}');
    }
  }

  /// Obtiene el estado actual de una solicitud de servicio.
  static Future<ServiceRequestModel> getRequestStatus(int requestId) async {
    // NOTA: Necesitarás crear esta ruta en tu backend
    final url = Uri.parse('${Constants.baseUrl}/service/request/$requestId');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return ServiceRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Error al obtener estado de la solicitud: ${response.body}');
    }
  }
}
