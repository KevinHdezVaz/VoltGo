// ✅ MODELO PRINCIPAL: ChatMessage
// Archivo: lib/data/models/chat/ChatMessage.dart

class ChatMessage {
  final int id;
  final int serviceRequestId;
  final int senderId;
  final String senderType; // 'user' o 'technician'
  final String senderName;
  final String message;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.serviceRequestId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.message,
    this.isRead = false,
    required this.sentAt,
    this.readAt,
  });

  // ✅ FACTORY DESDE JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      serviceRequestId: json['service_request_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderType: json['sender_type'] ?? 'user',
      senderName: json['sender_name'] ?? json['sender']?['name'] ?? 'Usuario',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  // ✅ CONVERTIR A JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'sender_id': senderId,
      'sender_type': senderType,
      'sender_name': senderName,
      'message': message,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  // ✅ MÉTODOS ÚTILES
  bool isFromUser() => senderType == 'user';
  bool isFromTechnician() => senderType == 'technician';

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${sentAt.hour}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${sentAt.day}/${sentAt.month}';
    }
  }

  // ✅ COPYSWITH PARA INMUTABILIDAD
  ChatMessage copyWith({
    int? id,
    int? serviceRequestId,
    int? senderId,
    String? senderType,
    String? senderName,
    String? message,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage{id: $id, senderType: $senderType, message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}, sentAt: $sentAt}';
  }
}

// ✅ MODELO PARA ESTADO DEL CHAT
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final bool canSendMessages;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.canSendMessages = true,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConnected,
    String? error,
    bool? canSendMessages,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      canSendMessages: canSendMessages ?? this.canSendMessages,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => messages.isEmpty;
  int get messageCount => messages.length;

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
}

// ✅ MODELO PARA CONFIGURACIÓN DEL CHAT
class ChatConfig {
  final int serviceRequestId;
  final String userType; // 'user' o 'technician'
  final String otherParticipantName;
  final bool allowImages;
  final bool allowLocation;
  final int maxMessageLength;

  const ChatConfig({
    required this.serviceRequestId,
    required this.userType,
    required this.otherParticipantName,
    this.allowImages = false,
    this.allowLocation = false,
    this.maxMessageLength = 1000,
  });

  bool get isUser => userType == 'user';
  bool get isTechnician => userType == 'technician';
}

// ✅ ENUMS PARA ESTADOS
enum ChatConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// ✅ EXTENSIONES ÚTILES
extension ChatConnectionStatusExtension on ChatConnectionStatus {
  String get displayText {
    switch (this) {
      case ChatConnectionStatus.disconnected:
        return 'Desconectado';
      case ChatConnectionStatus.connecting:
        return 'Conectando...';
      case ChatConnectionStatus.connected:
        return 'Conectado';
      case ChatConnectionStatus.error:
        return 'Error de conexión';
      case ChatConnectionStatus.reconnecting:
        return 'Reconectando...';
    }
  }

  bool get isConnected => this == ChatConnectionStatus.connected;
  bool get canSendMessages => this == ChatConnectionStatus.connected;
}

extension MessageStatusExtension on MessageStatus {
  String get displayText {
    switch (this) {
      case MessageStatus.sending:
        return 'Enviando...';
      case MessageStatus.sent:
        return 'Enviado';
      case MessageStatus.delivered:
        return 'Entregado';
      case MessageStatus.read:
        return 'Leído';
      case MessageStatus.failed:
        return 'Error al enviar';
    }
  }
}
