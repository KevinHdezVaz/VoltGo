// ✅ MODELO PARA EL HISTORIAL DE CHATS
import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/models/chat/ChatMessage.dart';

class ChatHistoryItem {
  final int serviceId;
  final String serviceStatus;
  final UserData otherParticipant;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String userType;
  final bool canChat;
  final DateTime serviceDate;

  ChatHistoryItem({
    required this.serviceId,
    required this.serviceStatus,
    required this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
    required this.userType,
    this.canChat = false,
    required this.serviceDate,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      serviceId: json['service_id'] ?? 0,
      serviceStatus: json['service_status'] ?? 'unknown',
      otherParticipant: UserData.fromJson(json['other_participant'] ?? {}),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      userType: json['user_type'] ?? 'user',
      canChat: json['can_chat'] ?? false,
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'])
          : DateTime.now(),
    );
  }

  String getStatusText() {
    switch (serviceStatus) {
      case 'pending':
        return 'Buscando técnico';
      case 'accepted':
        return 'Técnico asignado';
      case 'en_route':
        return 'En camino';
      case 'on_site':
        return 'En sitio';
      case 'charging':
        return 'Cargando';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return serviceStatus;
    }
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(serviceDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}
