import 'dart:convert';

class HistoryResponse {
  final List<HistoryPoint> data;

  HistoryResponse({
    required this.data,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ?? [];
    return HistoryResponse(
      data: list
          .map((item) => HistoryPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HistoryPoint {
  final String plate;
  final DateTime? timestamp;
  final double latitude;
  final double longitude;
  final double speed;
  final int direction;
  final String status;
  final String dataOrigin;
  final String nmea;
  final DateTime? insertTimestamp;
  final double? analogSensor1;
  final double? analogSensor2;
  final double? analogSensor3;
  final bool digitalSensor1;
  final bool digitalSensor2;
  final bool digitalSensor3;
  final bool digitalSensor4;
  final bool digitalSensor5;
  final bool digitalSensor6;
  final int eventNumber;
  final String mjId;
  final bool ignitionStatus;
  final int? hdop;
  final int? dataAge;
  final int? satellites;
  final double? altitude;
  final double? mobileBatteryVoltage;
  final double? mobileBatteryAmps;
  final double? equipmentBatteryVoltage;
  final double? equipmentBatteryAmps;
  final double? equipmentBatteryPercentage;
  final int? gsmSignal;
  final int? rssi;
  final String? mcc;
  final String? mnc;
  final String? lac;
  final String? cellId;
  final String? ib;
  final double? odometer;
  final String? gsmStatus;
  final String? inputStatus;
  final double? equipmentIgnitionVoltage;
  final String? gpsConnectionStatus;
  final String? gprsConnectionStatus;
  final double? returnTemperature;
  final double? dischargeTemperature;
  final double? setpointTemperature;
  final double? evaporatorTemperature;
  final String? operationStatus;
  final String? alarmCode;

  HistoryPoint({
    required this.plate,
    this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.direction,
    required this.status,
    required this.dataOrigin,
    required this.nmea,
    this.insertTimestamp,
    this.analogSensor1,
    this.analogSensor2,
    this.analogSensor3,
    required this.digitalSensor1,
    required this.digitalSensor2,
    required this.digitalSensor3,
    required this.digitalSensor4,
    required this.digitalSensor5,
    required this.digitalSensor6,
    required this.eventNumber,
    required this.mjId,
    required this.ignitionStatus,
    this.hdop,
    this.dataAge,
    this.satellites,
    this.altitude,
    this.mobileBatteryVoltage,
    this.mobileBatteryAmps,
    this.equipmentBatteryVoltage,
    this.equipmentBatteryAmps,
    this.equipmentBatteryPercentage,
    this.gsmSignal,
    this.rssi,
    this.mcc,
    this.mnc,
    this.lac,
    this.cellId,
    this.ib,
    this.odometer,
    this.gsmStatus,
    this.inputStatus,
    this.equipmentIgnitionVoltage,
    this.gpsConnectionStatus,
    this.gprsConnectionStatus,
    this.returnTemperature,
    this.dischargeTemperature,
    this.setpointTemperature,
    this.evaporatorTemperature,
    this.operationStatus,
    this.alarmCode,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    double? safeParseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? safeParseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return HistoryPoint(
      plate: json['mov_codigo'] as String? ?? '',
      timestamp: (json['mopo_fechahora'] is String)
          ? DateTime.tryParse(json['mopo_fechahora'])
          : null,
      latitude: safeParseDouble(json['mopo_lat']) ?? 0.0,
      longitude: safeParseDouble(json['mopo_lon']) ?? 0.0,
      speed: (json['mopo_vel'] as num?)?.toDouble() ?? 0.0,
      direction: json['mopo_dir'] as int? ?? 0,
      status: json['mopo_estado'] as String? ?? '',
      dataOrigin: json['mopo_origendata'] as String? ?? '',
      nmea: json['mopo_nmea'] as String? ?? '',
      insertTimestamp: (json['mopo_fechains'] is String)
          ? DateTime.tryParse(json['mopo_fechains'])
          : null,
      analogSensor1: safeParseDouble(json['mopo_sensora1']),
      analogSensor2: safeParseDouble(json['mopo_sensora2']),
      analogSensor3: safeParseDouble(json['mopo_sensora3']),
      digitalSensor1: json['mopo_sensord1'] as bool? ?? false,
      digitalSensor2: json['mopo_sensord2'] as bool? ?? false,
      digitalSensor3: json['mopo_sensord3'] as bool? ?? false,
      digitalSensor4: json['mopo_sensord4'] as bool? ?? false,
      digitalSensor5: json['mopo_sensord5'] as bool? ?? false,
      digitalSensor6: json['mopo_sensord6'] as bool? ?? false,
      eventNumber: json['moev_numeroevento'] as int? ?? 0,
      mjId: json['mopo_mjid'] as String? ?? '',
      ignitionStatus: json['mopo_estado_ignicion'] as bool? ?? false,
      hdop: safeParseInt(json['hdop']),
      dataAge: safeParseInt(json['edaddato']),
      satellites: safeParseInt(json['satelites']),
      altitude: safeParseDouble(json['altitud']),
      mobileBatteryVoltage: safeParseDouble(json['movilbateriavolt']),
      mobileBatteryAmps: safeParseDouble(json['movilbateriaamp']),
      equipmentBatteryVoltage: safeParseDouble(json['equipobateriavolt']),
      equipmentBatteryAmps: safeParseDouble(json['equipobateriaamp']),
      equipmentBatteryPercentage: safeParseDouble(json['equipobateriaporcent']),
      gsmSignal: safeParseInt(json['gsmsenal']),
      rssi: safeParseInt(json['rssi']),
      mcc: json['mcc'] as String?,
      mnc: json['mnc'] as String?,
      lac: json['lac'] as String?,
      cellId: json['cellid'] as String?,
      ib: json['ib'] as String?,
      odometer: safeParseDouble(json['odometro']),
      gsmStatus: json['estadogsm'] as String?,
      inputStatus: json['estadoentradas'] as String?,
      equipmentIgnitionVoltage: safeParseDouble(json['equipovoltignicion']),
      gpsConnectionStatus: json['estadoconexiongps'] as String?,
      gprsConnectionStatus: json['estadoconexiongprs'] as String?,
      returnTemperature: safeParseDouble(json['mopo_temp_retorno']),
      dischargeTemperature: safeParseDouble(json['mopo_temp_descarga']),
      setpointTemperature: safeParseDouble(json['mopo_temp_setpoint']),
      evaporatorTemperature: safeParseDouble(json['mopo_temp_evaporador']),
      operationStatus: json['mopo_estado_operacion'] as String?,
      alarmCode: json['mopo_cod_alarma'] as String?,
    );
  }
}
