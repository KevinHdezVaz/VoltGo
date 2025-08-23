import 'dart:convert';
import 'package:Voltgo_User/data/models/User/UserVehicle.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Voltgo_User/data/models/vehicles/Vehicle.dart'; // Importa tus modelos de Vehicle
import 'package:Voltgo_User/data/models/vehicles/VehicleAccesories.dart';
import 'package:Voltgo_User/data/models/vehicles/VehicleDetail.dart';
import 'package:Voltgo_User/data/models/vehicles/VehicleHistoryPoint.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart'; // Tu clase TokenStorage

class VehicleService {
// En tu VehicleService.dart

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    // No necesitas el debugPrint aquí si ya lo tienes en otros lados

    if (token == null) {
      // Es buena práctica manejar el caso en que el token no exista
      throw Exception('Token no encontrado. Inicia sesión de nuevo.');
    }

    return {
      // ✅ CAMBIO REALIZADO AQUÍ
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<List<Vehicle>> getAllVehicles() async {
    final url = Uri.parse('${Constants.baseUrl}/vehicle/get');
    debugPrint('VehicleService: Realizando GET a: $url'); // Log de la URL
    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}'); // Log de la respuesta

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final vehicleResponse =
            VehicleResponse.fromJson(data); // Usa VehicleResponse para parsear
        return vehicleResponse.data;
      } else {
        throw Exception(
            'Failed to load vehicles: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint(
          'VehicleService: Error en getAllVehicles: $e'); // Log del error
      throw Exception('Vehicle request failed: $e');
    }
  }

  // data/services/vehicles_service.dart (relevant method)
  static Future<VehicleAccessories> getVehicleAccessories(String plate) async {
    final url =
        Uri.parse('${Constants.baseUrl}/vehicle/get-accessories/$plate');
    debugPrint(
        'VehicleService: Realizando GET a: $url para accesorios de placa: $plate');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        return VehicleAccessories.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load vehicle accessories: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint(
          'VehicleService: Error en getVehicleAccessories para $plate: $e');
      throw Exception('Vehicle accessories request failed: $e');
    }
  }

  static Future<VehicleDetail> getVehicleDetail(String plate) async {
    final url = Uri.parse('${Constants.baseUrl}/vehicle/get/$plate');
    debugPrint('VehicleService: Realizando GET a: $url para placa: $plate');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        return VehicleDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load vehicle details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en getVehicleDetail para $plate: $e');
      throw Exception('Vehicle detail request failed: $e');
    }
  }

  static Future<List<VehiclePosition>> getVehiclesPositions(
      {String? plate}) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/vehicle/get-vehicles-position${plate != null ? '/$plate' : ''}');
    debugPrint(
        'VehicleService: Realizando GET a: $url para posiciones'); // Log de la URL
    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}'); // Log de la respuesta

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VehiclePosition.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load positions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint(
          'VehicleService: Error en getVehiclesPositions: $e'); // Log del error
      throw Exception('Position request failed: $e');
    }
  }

  static Future<List<HistoryPoint>> getVehicleHistory({
    required String plate,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final formattedStart = DateFormat("yyyy-MM-dd").format(startDate);
    final formattedEnd = DateFormat("yyyy-MM-dd").format(endDate);
    final baseUrl =
        '${Constants.baseUrl}/vehicle/get-history/$formattedStart/$formattedEnd';
    final url = Uri.parse(baseUrl).replace(
      queryParameters: {'plate': plate},
    );

    debugPrint('VehicleService: Realizando GET a: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final historyResponse =
            HistoryResponse.fromJson(jsonDecode(response.body));
        return historyResponse.data;
      } else {
        throw Exception(
            'Failed to load history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en getVehicleHistory: $e');
      throw Exception('History request failed: $e');
    }
  }

  static Future<bool> setVehicleType({
    required String plate,
    required String type,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/vehicle/set-vehicle-type');
    final body = jsonEncode({'plate': plate, 'type': type});
    debugPrint(
        'VehicleService: Realizando POST a: $url con body: $body'); // Log de la URL y cuerpo
    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: body,
      );

      debugPrint(
          'VehicleService: Respuesta POST ${response.statusCode}: ${response.body}'); // Log de la respuesta

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
          'VehicleService: Error en setVehicleType: $e'); // Log del error
      throw Exception('Set type failed: $e');
    }
  }

  static Future<void> updateUserVehicle({
    required int vehicleId,
    required String make,
    required String model,
    required int year,
    required String connectorType,
    String? plate,
    String? color,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/vehicles/$vehicleId');

    try {
      final headers = await _getAuthHeaders();

      final body = jsonEncode({
        'make': make,
        'model': model,
        'year': year,
        'connector_type': connectorType,
        if (plate != null && plate.isNotEmpty) 'plate': plate,
        if (color != null && color.isNotEmpty) 'color': color,
      });

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error al actualizar el vehículo');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en updateUserVehicle: $e');
      throw Exception('Error al actualizar el vehículo: $e');
    }
  }

  // Obtener vehículos del usuario
  static Future<List<UserVehicle>> getUserVehicles() async {
    final url = Uri.parse('${Constants.baseUrl}/user/vehicles');

    try {
      final response = await http.get(url, headers: await _getAuthHeaders());

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> vehiclesJson = data['vehicles'];
        return vehiclesJson.map((json) => UserVehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user vehicles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en getUserVehicles: $e');
      throw Exception('Error al obtener vehículos: $e');
    }
  }

  static Future<void> addVehicle({
    required String make,
    required String model,
    required int year,
    required String connectorType,
    String? plate,
    String? color,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/vehicles');

    try {
      final headers = await _getAuthHeaders();

      final body = jsonEncode({
        'make': make,
        'model': model,
        'year': year,
        'connector_type': connectorType,
        if (plate != null && plate.isNotEmpty) 'plate': plate,
        if (color != null && color.isNotEmpty) 'color': color,
      });

      debugPrint('VehicleService: Registrando vehículo de usuario en: $url');
      debugPrint('VehicleService: Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      debugPrint(
          'VehicleService: Respuesta POST ${response.statusCode}: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('VehicleService: Vehículo registrado exitosamente');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error al registrar el vehículo');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en addVehicle: $e');
      throw Exception('Error al registrar el vehículo: $e');
    }
  }

  static Future<List<VehicleType>> getVehicleTypes() async {
    final url = Uri.parse(
        '${Constants.baseUrl}/vehicle/get-types'); // Asumiendo que esta es la ruta
    debugPrint('VehicleService: Realizando GET a: $url');

    try {
      final headers = await _getAuthHeaders();
      headers['Accept-Charset'] = 'utf-8'; // Agregar header para soporte UTF-8

      final response = await http.get(
        url,
        headers: headers,
      );

      debugPrint(
          'VehicleService: Respuesta GET ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
            utf8.decode(response.bodyBytes)); // Decodificar como UTF-8
        final typesResponse = VehicleTypesResponse.fromJson(data);
        return typesResponse.data;
      } else {
        throw Exception(
            'Failed to load vehicle types: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en getVehicleTypes: $e');
      throw Exception('Vehicle types request failed: $e');
    }
  }

  static Future<List<HistoryPoint>> getVehicleHistoryByRange({
    required String plate,
    required DateTime endDate,
    required int rangeInHours,
  }) async {
    final formattedEndDate = DateFormat('yyyy-MM-dd HH:mm').format(endDate);
    final url = Uri.parse(
        '${Constants.baseUrl}/vehicle/get-history/$formattedEndDate/$rangeInHours');

    debugPrint('VehicleService: Realizando GET a: $url');

    try {
      final request = http.Request('GET', url)
        ..headers.addAll(await _getAuthHeaders())
        ..body = jsonEncode({'plate': plate});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('VehicleService: Respuesta GET ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final historyResponse =
            HistoryResponse.fromJson(jsonDecode(responseBody));
        return historyResponse.data;
      } else {
        throw Exception(
            'Fallo al cargar historial por rango: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('VehicleService: Error en getVehicleHistoryByRange: $e');
      throw Exception('La petición de historial por rango falló: $e');
    }
  }
}
