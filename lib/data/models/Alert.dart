class Alert {
  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  final String? vehiclePlate;
  final bool read;

  Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.vehiclePlate,
    this.read = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      type: json['type'] ?? 'alert',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      vehiclePlate: json['vehicle_plate'],
      read: json['read'] ?? false,
    );
  }
  @override
  String toString() {
    return 'Alert[$type]: $message (${timestamp.toLocal()})';
  }
}
