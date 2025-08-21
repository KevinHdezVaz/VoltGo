// data/services/vehicle_service.dart

import 'dart:convert';

import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';

import 'package:http/http.dart' as http;

class VehicleService {
  static Future<void> addVehicle({
    required String make,
    required String model,
    required int year,
    required String connectorType,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/vehicles');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'make': make,
      'model': model,
      'year': year,
      'connector_type': connectorType,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 201) {
      // Si el servidor devuelve un error, lo lanzamos para que la UI lo capture.
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to add vehicle');
    }
  }
}
