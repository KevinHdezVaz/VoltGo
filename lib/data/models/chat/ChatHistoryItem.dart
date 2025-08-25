// Archivo: lib/data/models/chat/ChatHistoryItem.dart

class ChatHistoryItem {
  final int serviceId;
  final ChatParticipant? otherParticipant;
  final LastMessage? lastMessage;
  final String serviceDate;

  ChatHistoryItem({
    required this.serviceId,
    this.otherParticipant,
    this.lastMessage,
    required this.serviceDate,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      // ✅ CONVERSIÓN SEGURA DE SERVICE_ID
      serviceId: json['service_id'] is String
          ? int.parse(json['service_id'])
          : json['service_id'] ?? 0,

      otherParticipant: json['other_participant'] != null
          ? ChatParticipant.fromJson(json['other_participant'])
          : null,

      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(json['last_message'])
          : null,

      serviceDate: json['service_date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'other_participant': otherParticipant?.toJson(),
      'last_message': lastMessage?.toJson(),
      'service_date': serviceDate,
    };
  }
}

class ChatParticipant {
  final int id;
  final String name;
  final String? email;

  ChatParticipant({
    required this.id,
    required this.name,
    this.email,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
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

class LastMessage {
  final String message;
  final String sentAt;

  LastMessage({
    required this.message,
    required this.sentAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      message: json['message']?.toString() ?? '',
      sentAt: json['sent_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'sent_at': sentAt,
    };
  }
}
