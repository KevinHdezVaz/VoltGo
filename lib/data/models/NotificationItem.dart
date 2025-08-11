import 'dart:convert';

// -----------------------------------------------------------------------------
// Modelos para:
// GET /user/get-notifications
// GET /user/get-notifications/{page}
// -----------------------------------------------------------------------------

/// Representa la respuesta completa de la API de notificaciones.
class NotificationsResponse {
    final NotificationData data;

    NotificationsResponse({
        required this.data,
    });

    factory NotificationsResponse.fromJson(String str) => NotificationsResponse.fromMap(json.decode(str));

    factory NotificationsResponse.fromMap(Map<String, dynamic> json) => NotificationsResponse(
        data: NotificationData.fromMap(json["data"]),
    );
}

/// Contiene las listas de notificaciones de hoy y anteriores.
class NotificationData {
    final List<Notification> todayNotifications;
    final List<Notification> previousNotifications;

    NotificationData({
        required this.todayNotifications,
        required this.previousNotifications,
    });

    factory NotificationData.fromMap(Map<String, dynamic> json) => NotificationData(
        todayNotifications: List<Notification>.from(json["today_notifications"].map((x) => Notification.fromMap(x))),
        previousNotifications: List<Notification>.from(json["previous_notifications"].map((x) => Notification.fromMap(x))),
    );
}

/// Representa una notificación individual en las listas.
class Notification {
    final int id;
    final String title;
    final String body;
    final String type;
    final String hour;

    Notification({
        required this.id,
        required this.title,
        required this.body,
        required this.type,
        required this.hour,
    });

    factory Notification.fromMap(Map<String, dynamic> json) => Notification(
        id: json["id"],
        title: json["title"],
        body: json["body"],
        type: json["type"],
        hour: json["hour"],
    );
}


// -----------------------------------------------------------------------------
// Modelo para:
// GET /user/get-notification-detail/{id}
// -----------------------------------------------------------------------------

/// Representa la respuesta completa del detalle de una notificación.
class NotificationDetailResponse {
    final NotificationDetail data;

    NotificationDetailResponse({
        required this.data,
    });

    factory NotificationDetailResponse.fromJson(String str) => NotificationDetailResponse.fromMap(json.decode(str));

    factory NotificationDetailResponse.fromMap(Map<String, dynamic> json) => NotificationDetailResponse(
        data: NotificationDetail.fromMap(json["data"]),
    );
}

/// Contiene los detalles específicos de una notificación.
class NotificationDetail {
    final int id;
    final String messageTitle;
    final String messageBody;
    final Alert alert;
    final bool read;
    final DateTime date;

    NotificationDetail({
        required this.id,
        required this.messageTitle,
        required this.messageBody,
        required this.alert,
        required this.read,
        required this.date,
    });

    factory NotificationDetail.fromMap(Map<String, dynamic> json) => NotificationDetail(
        id: json["id"],
        messageTitle: json["message_title"],
        messageBody: json["message_body"],
        alert: Alert.fromMap(json["alert"]),
        read: json["read"],
        date: DateTime.parse(json["date"]),
    );
}

/// Representa la información de la alerta asociada a un detalle de notificación.
class Alert {
    final dynamic latitude;
    final dynamic longitude;
    final String driver;

    Alert({
        this.latitude,
        this.longitude,
        required this.driver,
    });

    factory Alert.fromMap(Map<String, dynamic> json) => Alert(
        latitude: json["latitude"],
        longitude: json["longitude"],
        driver: json["driver"],
    );
}


// -----------------------------------------------------------------------------
// Modelo para:
// POST /user/set-notification-read
// -----------------------------------------------------------------------------

/// Representa la respuesta al marcar una notificación como leída.
class SetNotificationReadResponse {
    final String message;

    SetNotificationReadResponse({
        required this.message,
    });

    factory SetNotificationReadResponse.fromJson(String str) => SetNotificationReadResponse.fromMap(json.decode(str));

    factory SetNotificationReadResponse.fromMap(Map<String, dynamic> json) => SetNotificationReadResponse(
        message: json["message"],
    );
}