import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Voltgo_app/data/models/dashboard/BalanceResponse.dart';
import 'package:Voltgo_app/data/models/dashboard/DashboardData.dart'; // Importa el nuevo modelo
import 'package:Voltgo_app/data/models/dashboard/DashboardDetailModel.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';

class DashboardService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<BalanceResponse> getUserBalance() async {
    final url = Uri.parse('${Constants.baseUrl}/user/get-balance');

    debugPrint('BalanceService: Realizando GET a: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint('BalanceService: Respuesta GET ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);
        return BalanceResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load balance data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('BalanceService: Error en getUserBalance: $e');
      throw Exception('Balance request failed: $e');
    }
  }

  static Future<DashboardDetailData> getDashboardDetailData({
    required int rangeInHours,
    required String dataType,
  }) async {
    final now = DateTime.now();
    final formattedEndDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final url = Uri.parse(
        '${Constants.baseUrl}/vehicle/get-dashboard-data/$formattedEndDate/$rangeInHours/$dataType');

    debugPrint('DashboardService: Realizando GET a: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint('DashboardService: Respuesta GET ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return DashboardDetailData.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception(
            'Fallo al cargar los datos de detalle: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DashboardService: Error en getDashboardDetailData: $e');
      throw Exception('La petición de detalle del dashboard falló: $e');
    }
  }

  static Future<DashboardData> getDashboardData(
      {required int rangeInHours}) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/vehicle/get-dashboard-data/$rangeInHours');

    debugPrint('DashboardService: Realizando GET a: $url');

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(),
      );

      debugPrint('DashboardService: Respuesta GET ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);
        return DashboardDataResponse.fromJson(jsonData).data;
      } else {
        throw Exception(
            'Fallo al cargar los datos del dashboard: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DashboardService: Error en getDashboardData: $e');
      throw Exception('La petición de datos del dashboard falló: $e');
    }
  }
}
