import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:Voltgo_app/data/models/vehicles/VehiclePositionModel.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';

class VehiclePositionService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    debugPrint('AuthService: Obteniendo token: $token');
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<VehiclePositionResponse> getVehicleCurrentPosition(
      String plate) async {
    final url = Uri.parse('${Constants.baseUrl}/vehicle/get-position/$plate');
    debugPrint(
        'VehiclePositionService: Realizando GET a: $url para la patente: $plate');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );
      debugPrint(
          'VehiclePositionService: Respuesta GET ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return VehiclePositionResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to load vehicle position: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint(
          'VehiclePositionService: Error en getVehicleCurrentPosition para $plate: $e');
      throw Exception('Vehicle position request failed: $e');
    }
  }

  static Future<VehiclePositionResponse> getVehiclesPositions(
      {String? plate}) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/vehicle/get-vehicles-position${plate != null ? '/$plate' : ''}');
    debugPrint('VehiclePositionService: Realizando GET a: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );
      debugPrint(
          'VehiclePositionService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return VehiclePositionResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to load vehicles positions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('VehiclePositionService: Error en getVehiclesPositions: $e');
      throw Exception('Vehicles positions request failed: $e');
    }
  }
}
