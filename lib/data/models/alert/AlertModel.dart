import 'dart:convert';
import 'package:intl/intl.dart';

// Response wrapper for notifications (not used directly by new API, but kept for potential future use)
class AlertsResponse {
  final List<Alertas> data;

  AlertsResponse({required this.data});

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ?? [];
    return AlertsResponse(
      data: list
          .map((item) => Alertas.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Alertas {
  final String id; // Added to match API's id field
  final String name;
  final String plate;
  final DateTime? alertDate;
  final double? speed; // Not provided by API, kept as nullable
  final double? latitude; // Provided in get-notification-detail
  final double? longitude; // Provided in get-notification-detail
  final String driverName;
  final String? geofenceName; // Not provided by API, kept as nullable
  final int status; // Not provided by API, default to 0
  final AlertType alertType;
  final AlertVehicle vehicle;
  final bool read; // Added to track read status from get-notification-detail

  Alertas({
    required this.id,
    required this.name,
    required this.plate,
    this.alertDate,
    this.speed,
    this.latitude,
    this.longitude,
    required this.driverName,
    this.geofenceName,
    required this.status,
    required this.alertType,
    required this.vehicle,
    required this.read,
  });

  factory Alertas.fromJson(Map<String, dynamic> json) {
    double? safeParseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? safeParseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Extract plate from body if present (e.g., "El Vehiculo RKWV - 10, ...")
    final body = json['body'] as String? ?? json['message_body'] as String? ?? '';
    final plateMatch = RegExp(r'El Vehiculo (\w+ - \d+)').firstMatch(body);
    final plate = plateMatch != null ? plateMatch.group(1) ?? 'Unknown' : 'Unknown';

    return Alertas(
      id: (json['id'] as int?)?.toString() ?? '0',
      name: json['name'] as String? ?? json['type'] as String? ?? json['message_title'] as String? ?? 'Alerta desconocida',
      plate: plate,
      alertDate: safeParseDateTime(json['date']) ?? _parseHour(json['hour']),
      speed: safeParseDouble(json['speed']), // Not provided by API
      latitude: safeParseDouble(json['latitude']),
      longitude: safeParseDouble(json['longitude']),
      driverName: json['driver_name'] as String? ?? json['driver'] as String? ?? 'Sin conductor',
      geofenceName: json['geofence_name'] as String?, // Not provided by API
      status: json['status'] as int? ?? 0, // Default to 0
      alertType: AlertType.fromJson(
        json['alert_type'] as Map<String, dynamic>? ??
            {
              'id': json['id'] ?? 0,
              'name': json['type'] ?? json['message_title'] ?? 'Unknown',
            },
      ),
      vehicle: AlertVehicle.fromJson(
        json['vehicle'] as Map<String, dynamic>? ?? {'plate': plate},
      ),
      read: json['read'] as bool? ?? false,
    );
  }

  static DateTime? _parseHour(String? hour) {
    if (hour == null) return null;
    try {
      final now = DateTime.now();
      final time = DateFormat('HH:mm:ss').parse(hour);
      return DateTime(now.year, now.month, now.day, time.hour, time.minute, time.second);
    } catch (e) {
      return null;
    }
  }
}

class AlertType {
  final int id;
  final String name;

  AlertType({
    required this.id,
    required this.name,
  });

  factory AlertType.fromJson(Map<String, dynamic> json) {
    return AlertType(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class AlertVehicle {
  final String plate;

  AlertVehicle({required this.plate});

  factory AlertVehicle.fromJson(Map<String, dynamic> json) {
    return AlertVehicle(
      plate: json['plate'] as String? ?? '',
    );
  }
}

class AlertTypesResponse {
  final List<AlertType> data;

  AlertTypesResponse({required this.data});

  factory AlertTypesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ?? [];
    return AlertTypesResponse(
      data: list
          .map((item) => AlertType.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}