import 'dart:convert';

VehiclePositionResponse vehiclePositionResponseFromJson(String str) =>
    VehiclePositionResponse.fromJson(json.decode(str));

class VehiclePositionResponse {
  final List<VehicleCurrentPosition> data;

  VehiclePositionResponse({
    required this.data,
  });

  factory VehiclePositionResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>?;

    return VehiclePositionResponse(
      data: list != null
          ? List<VehicleCurrentPosition>.from(list.map((item) =>
              VehicleCurrentPosition.fromJson(item as Map<String, dynamic>)))
          : [], // Si 'data' no existe o es nulo, devuelve una lista vacía
    );
  }
}

class VehicleCurrentPosition {
  final double latitude;
  final double longitude;
  final double speed;
  final int direction;
  final bool ignitionStatus;
  final String
      vehiclePlate; // Renombrado de 'vehicle' a 'vehiclePlate' para mayor claridad

  VehicleCurrentPosition({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.direction,
    required this.ignitionStatus,
    required this.vehiclePlate,
  });

  factory VehicleCurrentPosition.fromJson(Map<String, dynamic> json) {
    return VehicleCurrentPosition(
      latitude: double.tryParse(json['latitude'] as String? ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude'] as String? ?? '0.0') ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'] as int? ?? 0,
      ignitionStatus: json['ignition_status'] as bool? ?? false,
      vehiclePlate: json['vehicle'] as String? ?? '',
    );
  }
}
