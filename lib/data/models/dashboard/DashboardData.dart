import 'dart:convert';

class DashboardDataResponse {
  final DashboardData data;

  DashboardDataResponse({required this.data});

  factory DashboardDataResponse.fromJson(Map<String, dynamic> json) {
    return DashboardDataResponse(
      data: DashboardData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class DashboardData {
  final Map<String, int> vehicleTypes;
  final Map<String, int> vehicleStatus;
  final Map<String, int> alertPlan;
  final int totalVehicles;
  final int totalAlerts;
  final int totalOnline;

  DashboardData({
    required this.vehicleTypes,
    required this.vehicleStatus,
    required this.alertPlan,
    required this.totalVehicles,
    required this.totalAlerts,
    required this.totalOnline,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    Map<String, int> _parseMap(Map<String, dynamic>? data) {
      if (data == null) return {};
      return data
          .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
    }

    return DashboardData(
      vehicleTypes: _parseMap(json['d_vehicles_type'] as Map<String, dynamic>?),
      vehicleStatus:
          _parseMap(json['d_vehicles_status'] as Map<String, dynamic>?),
      alertPlan: _parseMap(json['d_alert_plan'] as Map<String, dynamic>?),
      totalVehicles: json['total_vehicles'] as int? ?? 0,
      totalAlerts: json['total_alerts'] as int? ?? 0,
      totalOnline: json['total_online'] as int? ?? 0,
    );
  }
}
