class UserModel {
  final int id;
  final String name;
  final String email;
  final String userType;
  final bool hasRegisteredVehicle;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.hasRegisteredVehicle,
  });

  // Este 'factory constructor' crea un UserModel a partir de un JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'user',
      // Laravel devuelve 0 o 1 para booleanos, por eso la comparación
      hasRegisteredVehicle: json['has_registered_vehicle'] == 1,
    );
  }
}
