import 'package:flutter/material.dart';

class VehicleDetail {
  final String plate;
  final String position;
  final String connection;
  final String status;
  final DateTime? lastReport;
  final String location;
  final double? batteryVolt;
  final String fuelCutoff;
  final Map<String, String>? accessories; // New field for accessories

  VehicleDetail({
    required this.plate,
    required this.position,
    required this.connection,
    required this.status,
    this.lastReport,
    required this.location,
    this.batteryVolt,
    required this.fuelCutoff,
    this.accessories, // Added to constructor
  });

  factory VehicleDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    double? safeParseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    DateTime? safeParseDateTime(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, String>? safeParseAccessories(dynamic value) {
      if (value is Map<String, dynamic>) {
        try {
          return value.map(
              (key, value) => MapEntry(key, value?.toString() ?? 'Sin dato'));
        } catch (e) {
          debugPrint('Error parsing accessories: $e');
          return null;
        }
      }
      return null;
    }

    return VehicleDetail(
      plate: data['plate'] as String? ?? '',
      position: data['position'] as String? ?? 'Inválida',
      connection: data['connection'] as String? ?? 'Offline',
      status: data['status'] as String? ?? 'Apagado',
      lastReport: safeParseDateTime(data['last_report']),
      location: data['location'] as String? ?? 'Sin ubicación',
      batteryVolt: safeParseDouble(data['battery_volt']),
      fuelCutoff: data['fuel_cutoff'] as String? ?? 'Sin datos',
      accessories: json['accessories'] != null
          ? safeParseAccessories(json['accessories']['data'])
          : null,
    );
  }
}
