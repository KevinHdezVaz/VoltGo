class UserVehicle {
  final int id;
  final int userId;
  final String make;
  final String model;
  final int year;
  final String connectorType;
  final String? plate;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserVehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.connectorType,
    this.plate,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserVehicle.fromJson(Map<String, dynamic> json) {
    return UserVehicle(
      id: json['id'],
      userId: json['user_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      connectorType: json['connector_type'],
      plate: json['plate'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'make': make,
      'model': model,
      'year': year,
      'connector_type': connectorType,
      'plate': plate,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método para mostrar información del vehículo
  String get displayName => '$make $model ($year)';

  // Método para mostrar el conector
  String get displayConnector => connectorType;
}
