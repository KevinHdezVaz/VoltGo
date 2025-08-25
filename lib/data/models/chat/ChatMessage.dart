// Archivo: lib/data/models/chat/ChatMessage.dart

class ChatMessage {
  final int id;
  final int serviceRequestId;
  final int senderId;
  final String message;
  final DateTime createdAt;
  final ChatSender? sender;

  ChatMessage({
    required this.id,
    required this.serviceRequestId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      // ✅ CONVERSIÓN SEGURA DE ID
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,

      // ✅ CONVERSIÓN SEGURA DE SERVICE_REQUEST_ID
      serviceRequestId: json['service_request_id'] is String
          ? int.parse(json['service_request_id'])
          : json['service_request_id'] ?? 0,

      // ✅ CONVERSIÓN SEGURA DE SENDER_ID
      senderId: json['sender_id'] is String
          ? int.parse(json['sender_id'])
          : json['sender_id'] ?? 0,

      message: json['message']?.toString() ?? '',

      // ✅ PARSING SEGURO DE FECHA
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),

      // ✅ PARSING SEGURO DEL SENDER
      sender:
          json['sender'] != null ? ChatSender.fromJson(json['sender']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt.toIso8601String(), // ✅ CORRECCIÓN AQUÍ
      'sender': sender?.toJson(),
    };
  }

  // ✅ GETTER PARA SABER SI ES MENSAJE PROPIO
  bool isFromCurrentUser(int currentUserId) {
    return senderId == currentUserId;
  }

  // ✅ GETTER PARA FORMATEAR TIEMPO
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }
}

// ✅ CLASE PARA EL SENDER
class ChatSender {
  final int id;
  final String name;
  final String? email;

  ChatSender({
    required this.id,
    required this.name,
    this.email,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      // ✅ CONVERSIÓN SEGURA DE ID
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Usuario',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
