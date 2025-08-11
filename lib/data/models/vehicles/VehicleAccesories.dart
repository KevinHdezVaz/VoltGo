// data/models/vehicles/VehicleAccessories.dart
class VehicleAccessory {
  final String key; // Numeric key (e.g., "1")
  final String name; // Accessory name (e.g., "Cerradura Randomica")
  final String status; // Status value (e.g., "Sin Datos")

  VehicleAccessory({
    required this.key,
    required this.name,
    required this.status,
  });

  factory VehicleAccessory.fromJson(Map<String, dynamic> json) {
    final key = json.keys.firstWhere((k) => k != 'value', orElse: () => '');
    return VehicleAccessory(
      key: key,
      name: json[key] as String? ?? 'Unknown',
      status: json['value'] as String? ?? 'Sin Datos',
    );
  }
}

class VehicleAccessories {
  final List<VehicleAccessory> accessories;

  VehicleAccessories({required this.accessories});

  factory VehicleAccessories.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final accessories = data.map((item) => VehicleAccessory.fromJson(item as Map<String, dynamic>)).toList();
    return VehicleAccessories(accessories: accessories);
  }

  @override
  String toString() => 'VehicleAccessories(accessories: $accessories)';
}