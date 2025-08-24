// ✅ SERVICIO DE CHAT
// Archivo: lib/data/services/ChatService.dart

import 'dart:convert';
import 'dart:io';
import 'package:Voltgo_User/data/models/chat/ChatHistoryItem.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_User/utils/constants.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/data/models/chat/ChatMessage.dart';

class ChatService {
  static const String _baseUrl = Constants.baseUrl;

  // ✅ OBTENER HISTORIAL DE MENSAJES DE UN SERVICIO
  static Future<List<ChatMessage>> getChatHistory(int serviceRequestId) async {
    try {
      print('🔍 Obteniendo historial de chat para servicio: $serviceRequestId');

      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/service/$serviceRequestId');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);
      print('📡 Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messagesData = data['messages'] as List;

        final messages = messagesData
            .map((messageJson) => ChatMessage.fromJson(messageJson))
            .toList();

        print('✅ Historial obtenido: ${messages.length} mensajes');
        return messages;
      } else if (response.statusCode == 403) {
        throw Exception('No autorizado para ver este chat');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio no encontrado');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener historial');
      }
    } catch (e) {
      print('❌ Error obteniendo historial: $e');
      rethrow;
    }
  }

  // ✅ ENVIAR MENSAJE
  static Future<ChatMessage> sendMessage({
    required int serviceRequestId,
    required String message,
  }) async {
    try {
      print(
          '📤 Enviando mensaje: ${message.substring(0, message.length.clamp(0, 50))}...');

      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/service/$serviceRequestId');
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'message': message.trim(),
      });

      final response = await http.post(url, headers: headers, body: body);
      print('📡 Respuesta de envío: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sentMessage = ChatMessage.fromJson(data['message']);

        print('✅ Mensaje enviado exitosamente: ${sentMessage.id}');
        return sentMessage;
      } else if (response.statusCode == 403) {
        throw Exception('No autorizado para enviar mensajes en este chat');
      } else if (response.statusCode == 409) {
        throw Exception('El chat no está disponible para este servicio');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Mensaje inválido');
      } else if (response.statusCode == 429) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Demasiados mensajes. ${errorData['message'] ?? 'Espera un momento.'}');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al enviar mensaje');
      }
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      rethrow;
    }
  }

  // ✅ MARCAR MENSAJES COMO LEÍDOS
  static Future<void> markAsRead(int serviceRequestId) async {
    try {
      print(
          '👀 Marcando mensajes como leídos para servicio: $serviceRequestId');

      final token = await TokenStorage.getToken();
      if (token == null) return;

      final url = Uri.parse('$_baseUrl/chat/service/$serviceRequestId/read');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.patch(url, headers: headers);

      if (response.statusCode == 200) {
        print('✅ Mensajes marcados como leídos');
      } else {
        print('⚠️ Error marcando como leído: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marcando como leído: $e');
      // No lanzar excepción, es una operación secundaria
    }
  }

  // ✅ OBTENER HISTORIAL COMPLETO DE CHATS DEL USUARIO
  static Future<List<ChatHistoryItem>> getUserChatHistory() async {
    try {
      print('🔍 Obteniendo historial completo de chats del usuario');

      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final url = Uri.parse('$_baseUrl/chat/history');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);
      print('📡 Respuesta del historial: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatHistoryData = data['chat_history'] as List;

        final chatHistory = chatHistoryData
            .map((chatJson) => ChatHistoryItem.fromJson(chatJson))
            .toList();

        print(
            '✅ Historial de chats obtenido: ${chatHistory.length} conversaciones');
        return chatHistory;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error al obtener historial de chats');
      }
    } catch (e) {
      print('❌ Error obteniendo historial de chats: $e');
      rethrow;
    }
  }

  // ✅ OBTENER CONTADOR DE MENSAJES NO LEÍDOS
  static Future<int> getUnreadCount() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) return 0;

      final url = Uri.parse('$_baseUrl/chat/unread');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final unreadCount = data['unread_count'] ?? 0;
        print('📊 Mensajes no leídos: $unreadCount');
        return unreadCount;
      } else {
        print('⚠️ Error obteniendo contador: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('❌ Error obteniendo contador de no leídos: $e');
      return 0;
    }
  }

  // ✅ VERIFICAR SI UN SERVICIO PUEDE CHATEAR
  static Future<bool> canChatForService(int serviceRequestId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) return false;

      final url =
          Uri.parse('$_baseUrl/service/request/$serviceRequestId/status');
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['chat_available'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error verificando disponibilidad de chat: $e');
      return false;
    }
  }
}
