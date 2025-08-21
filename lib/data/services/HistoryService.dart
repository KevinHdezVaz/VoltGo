import 'dart:convert';

import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';

import 'package:http/http.dart' as http;
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';

class HistoryService {
  static Future<List<ServiceRequestModel>> fetchHistory() async {
    final url = Uri.parse('${Constants.baseUrl}/service/history');
    final token = await TokenStorage.getToken();

    if (token == null)
      throw Exception('No se encontró el token de autenticación');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ServiceRequestModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar el historial: ${response.statusCode}');
    }
  }
}
