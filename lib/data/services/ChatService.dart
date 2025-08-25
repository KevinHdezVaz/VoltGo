import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Voltgo_User/utils/constants.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/data/models/chat/ChatMessage.dart';
import 'package:Voltgo_User/data/models/chat/ChatHistoryItem.dart';

class ChatService {
  static const String _baseUrl = Constants.baseUrl;

  // ✅ OBTENER MENSAJES CON DEBUG
  static Future<List<ChatMessage>> getChatHistory(int serviceRequestId) async {
    try {
      print('🔍 Obteniendo historial de chat para servicio: $serviceRequestId');

      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/service/$serviceRequestId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Data structure: $data');

        final messagesData = data['messages'] as List;
        print('🔍 Messages count: ${messagesData.length}');

        final messages = messagesData.map((json) {
          print('🔍 Processing message: $json');
          return ChatMessage.fromJson(json);
        }).toList();

        return messages;
      } else {
        throw Exception('Error al obtener mensajes: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getChatHistory: $e');
      rethrow;
    }
  }

  // ✅ ENVIAR MENSAJE CON DEBUG
  static Future<ChatMessage> sendMessage({
    required int serviceRequestId,
    required String message,
  }) async {
    try {
      print('📤 Enviando mensaje: $message');
      print('📤 Service ID: $serviceRequestId');

      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final body = jsonEncode({'message': message});
      print('📤 Body: $body');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/service/$serviceRequestId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('📡 Send response status: ${response.statusCode}');
      print('📡 Send response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('🔍 Message data structure: $data');

        final messageData = data['message'];
        print('🔍 Processing sent message: $messageData');

        return ChatMessage.fromJson(messageData);
      } else {
        throw Exception('Error al enviar mensaje: ${response.body}');
      }
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      rethrow;
    }
  }

  // ✅ HISTORIAL DE CHATS CON DEBUG
  static Future<List<ChatHistoryItem>> getUserChatHistory() async {
    try {
      print('🔍 Obteniendo historial de chats del usuario');

      final token = await TokenStorage.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 History response status: ${response.statusCode}');
      print('📡 History response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 History data structure: $data');

        final chatHistoryData = data['chat_history'] as List;
        return chatHistoryData
            .map((json) => ChatHistoryItem.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener historial: ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo historial de chats: $e');
      rethrow;
    }
  }
}
