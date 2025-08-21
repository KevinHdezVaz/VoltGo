import 'package:intl/intl.dart';

class ServiceRequestModel {
  final int id;
  final int? technicianId;
  final String status;
  final double finalCost;
  final DateTime requestedAt;
  final String locationDescription;

  ServiceRequestModel({
    required this.id,
    this.technicianId,
    required this.status,
    required this.finalCost,
    required this.requestedAt,
    required this.locationDescription,
  });

  // ▼▼▼ ESTE ES EL CONSTRUCTOR CORREGIDO Y SEGURO ▼▼▼
  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] ?? 0, // Si el id es nulo, usa 0
      technicianId: json['technician_id'], // Ya es nullable, está bien

      // Si 'status' es nulo, usa 'desconocido' como valor por defecto
      status: json['status'] ?? 'desconocido',

      // Convierte el costo de forma segura, si es nulo o inválido, usa 0.0
      finalCost: double.tryParse(json['final_cost'].toString()) ?? 0.0,

      // Si la fecha es nula, usa la fecha y hora actual
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'])
          : DateTime.now(),

      // Crea una descripción segura, incluso si las coordenadas son nulas
      locationDescription: "Asistencia en Lat: ${json['request_lat'] ?? 'N/A'}",
    );
  }
  // ▲▲▲ FIN DE LA CORRECCIÓN ▲▲▲

  // Tus helpers para formatear la fecha no cambian
  String get formattedTime {
    return DateFormat('h:mm a', 'es_ES').format(requestedAt);
  }

  String get formattedDate {
    return DateFormat('EEEE, d \'de\' MMMM', 'es_ES').format(requestedAt);
  }
}
