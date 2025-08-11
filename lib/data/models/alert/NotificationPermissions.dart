class NotificationPermissions {
  final bool allowNotification;
  final AlertPermissions alertPermissions;

  NotificationPermissions({
    required this.allowNotification,
    required this.alertPermissions,
  });

  factory NotificationPermissions.fromJson(Map<String, dynamic> json) {
    return NotificationPermissions(
      allowNotification: json['allow_notification'] ?? false,
      alertPermissions:
          AlertPermissions.fromJson(json['alert_permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_notification': allowNotification,
      'alert_permissions': alertPermissions.toJson(),
    };
  }

  NotificationPermissions copyWith({
    bool? allowNotification,
    AlertPermissions? alertPermissions,
  }) {
    return NotificationPermissions(
      allowNotification: allowNotification ?? this.allowNotification,
      alertPermissions: alertPermissions ?? this.alertPermissions,
    );
  }
}

class AlertPermissions {
  final bool shortBreak;
  final bool maxSpeed;
  final bool noArrivalAtDestination;
  final bool tenHoursDriving;
  final bool continuousDriving;
  final bool test; // <-- Propiedad añadida

  AlertPermissions({
    required this.shortBreak,
    required this.maxSpeed,
    required this.noArrivalAtDestination,
    required this.tenHoursDriving,
    required this.continuousDriving,
        required this.test, // <-- Añadido al constructor

  });

  factory AlertPermissions.fromJson(Map<String, dynamic> json) {
    return AlertPermissions(
      shortBreak: json['descanso corto'] ?? false,
      maxSpeed: json['Velocidad Maxima'] ?? false,
      noArrivalAtDestination: json['No presentación en destino'] ?? false,
      tenHoursDriving: json['conduccion 10 Horas'] ?? false,
      continuousDriving: json['conduccion continua'] ?? false,
            test: json['Test'] ?? false, // <-- Mapeo del JSON

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descanso corto': shortBreak,
      'Velocidad Maxima': maxSpeed,
      'No presentación en destino': noArrivalAtDestination,
      'conduccion 10 Horas': tenHoursDriving,
      'conduccion continua': continuousDriving,
            'Test': test, // <-- Añadido al JSON

    };
  }

  AlertPermissions copyWith({
    bool? shortBreak,
    bool? maxSpeed,
    bool? noArrivalAtDestination,
    bool? tenHoursDriving,
    bool? continuousDriving,
        bool? test, // <-- Añadido a copyWith

  }) {
    return AlertPermissions(
      shortBreak: shortBreak ?? this.shortBreak,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      noArrivalAtDestination:
          noArrivalAtDestination ?? this.noArrivalAtDestination,
      tenHoursDriving: tenHoursDriving ?? this.tenHoursDriving,
      continuousDriving: continuousDriving ?? this.continuousDriving,
            test: test ?? this.test,

    );
  }

  bool get anyAlertEnabled =>
      shortBreak ||
      maxSpeed ||
      noArrivalAtDestination ||
      tenHoursDriving ||
      continuousDriving;
}

class NotificationPermissionsResponse {
  final NotificationPermissions data;

  NotificationPermissionsResponse({required this.data});

  factory NotificationPermissionsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationPermissionsResponse(
      data: NotificationPermissions.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
    };
  }
}
