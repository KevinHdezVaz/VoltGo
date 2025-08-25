import 'dart:convert'; // Import necesario para json.decode

class ServiceRequestModel {
  final int id;
  final int userId;
  final int? technicianId;
  final int? offeredToTechnicianId;
  final String status;
  final double requestLat;
  final double requestLng;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  // Datos del técnico (cuando está asignado)
  final TechnicianData? technician;
  final UserData? user;

  ServiceRequestModel({
    required this.id,
    required this.userId,
    this.technicianId,
    this.offeredToTechnicianId,
    required this.status,
    required this.requestLat,
    required this.requestLng,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.technician,
    this.user,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      technicianId: json['technician_id'],
      offeredToTechnicianId: json['offered_to_technician_id'],
      status: json['status'] ?? 'pending',
      requestLat: double.parse((json['request_lat'] ?? 0.0).toString()),
      requestLng: double.parse((json['request_lng'] ?? 0.0).toString()),
      requestedAt: DateTime.parse(json['requested_at'] ??
          json['created_at'] ??
          DateTime.now().toIso8601String()),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      technician: json['technician'] != null
          ? TechnicianData.fromJson(json['technician'])
          : null,
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'offered_to_technician_id': offeredToTechnicianId,
      'status': status,
      'request_lat': requestLat,
      'request_lng': requestLng,
      'requested_at': requestedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'technician': technician?.toJson(),
      'user': user?.toJson(),
    };
  }

  // ✅ NUEVO MÉTODO: Para verificar si el chat está disponible
  bool canChat() {
    // Solo puede chatear cuando el servicio está activo (aceptado hasta completado)
    return ['accepted', 'en_route', 'on_site', 'charging'].contains(status);
  }
}

class TechnicianData {
  final int id;
  final String name;
  final String? email;
  final TechnicianProfile? profile;

  TechnicianData({
    required this.id,
    required this.name,
    this.email,
    this.profile,
  });

  factory TechnicianData.fromJson(Map<String, dynamic> json) {
    return TechnicianData(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Técnico',
      email: json['email'],
      profile: json['technician_profile'] != null
          ? TechnicianProfile.fromJson(json['technician_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'technician_profile': profile?.toJson(),
    };
  }
}

// En TechnicianProfile.dart

class TechnicianProfile {
  final int userId;
  final String? status;
  final String? currentLat;
  final String? currentLng;
  final String? averageRating;
  final Map<String, dynamic>?
      vehicleDetails; // ✅ CAMBIAR DE String? a Map<String, dynamic>?
  final String? availableConnectors;
  final String? licenseNumber;

  TechnicianProfile({
    required this.userId,
    this.status,
    this.currentLat,
    this.currentLng,
    this.averageRating,
    this.vehicleDetails,
    this.availableConnectors,
    this.licenseNumber,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      userId: json['user_id'] ?? 0,
      status: json['status']?.toString(),
      currentLat: json['current_lat']?.toString(),
      currentLng: json['current_lng']?.toString(),
      averageRating: json['average_rating']?.toString(),
      // ✅ MANEJAR vehicle_details como Map en lugar de String
      vehicleDetails: json['vehicle_details'] is Map<String, dynamic>
          ? json['vehicle_details']
          : null,
      availableConnectors: json['available_connectors']?.toString(),
      licenseNumber: json['license_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'average_rating': averageRating,
      'vehicle_details': vehicleDetails, // ✅ Ya es Map, no necesita conversión
      'available_connectors': availableConnectors,
      'license_number': licenseNumber,
    };
  }

  // ✅ MÉTODOS HELPER PARA ACCEDER A LOS DETALLES DEL VEHÍCULO
  String? get vehicleMake => vehicleDetails?['make']?.toString();
  String? get vehicleModel => vehicleDetails?['model']?.toString();
  String? get vehicleYear => vehicleDetails?['year']?.toString();
  String? get vehiclePlate => vehicleDetails?['plate']?.toString();
  String? get vehicleColor => vehicleDetails?['color']?.toString();
  String? get vehicleConnectorType =>
      vehicleDetails?['connector_type']?.toString();

  // ✅ MÉTODO PARA OBTENER UNA DESCRIPCIÓN COMPLETA DEL VEHÍCULO
  String get vehicleDescription {
    if (vehicleDetails == null || vehicleDetails!.isEmpty) {
      return 'Vehículo no especificado';
    }

    final parts = <String>[];

    if (vehicleYear != null) parts.add(vehicleYear!);
    if (vehicleMake != null) parts.add(vehicleMake!);
    if (vehicleModel != null) parts.add(vehicleModel!);
    if (vehicleColor != null) parts.add('(${vehicleColor!})');

    return parts.isNotEmpty ? parts.join(' ') : 'Vehículo no especificado';
  }
}

// ✅ NUEVA CLASE PARA LOS DETALLES DEL VEHÍCULO
class VehicleDetails {
  final String make;
  final String model;
  final String year;
  final String plate;
  final String color;
  final String connectorType;

  VehicleDetails({
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.connectorType,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? '',
      plate: json['plate'] ?? '',
      color: json['color'] ?? '',
      connectorType: json['connector_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'plate': plate,
      'color': color,
      'connector_type': connectorType,
    };
  }
}

class UserData {
  final int id;
  final String name;
  final String? email;

  UserData({
    required this.id,
    required this.name,
    this.email,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Usuario',
      email: json['email'],
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
