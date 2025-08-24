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

// ✅ CLASE ACTUALIZADA
class TechnicianProfile {
  final int userId;
  final String status;
  final double? currentLat;
  final double? currentLng;
  final double? averageRating; // Corregido de 'rating'
  final VehicleDetails?
      vehicleDetails; // Corregido de 'vehicleInfo' y ahora es un objeto
  final List<String>? availableConnectors; // Corregido de 'connectorTypes'

  TechnicianProfile({
    required this.userId,
    required this.status,
    this.currentLat,
    this.currentLng,
    this.averageRating,
    this.vehicleDetails,
    this.availableConnectors,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    // Lógica para decodificar vehicle_details si es un string
    VehicleDetails? vehicleData;
    if (json['vehicle_details'] is String) {
      try {
        // Intenta decodificar el string a un mapa
        var decodedJson = jsonDecode(json['vehicle_details']);
        // Si el resultado sigue siendo un string (doble codificación), decodifica de nuevo
        if (decodedJson is String) {
          decodedJson = jsonDecode(decodedJson);
        }
        vehicleData = VehicleDetails.fromJson(decodedJson);
      } catch (e) {
        print("Error decodificando vehicle_details: $e");
        vehicleData = null;
      }
    } else if (json['vehicle_details'] is Map<String, dynamic>) {
      vehicleData = VehicleDetails.fromJson(json['vehicle_details']);
    }

    return TechnicianProfile(
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? 'offline',
      currentLat: json['current_lat'] != null
          ? double.tryParse(json['current_lat'].toString())
          : null,
      currentLng: json['current_lng'] != null
          ? double.tryParse(json['current_lng'].toString())
          : null,
      averageRating: json['average_rating'] != null // Corregido
          ? double.tryParse(json['average_rating'].toString())
          : 5.0,
      vehicleDetails: vehicleData, // Asigna el objeto decodificado
      availableConnectors: json['available_connectors'] != null // Corregido
          ? List<String>.from(json['available_connectors'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'average_rating': averageRating,
      'vehicle_details': vehicleDetails?.toJson(),
      'available_connectors': availableConnectors,
    };
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
