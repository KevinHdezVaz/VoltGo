import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'VoltGo',
      'searchingTechnician': 'Searching for technician',
      'technicianArriving': 'Technician arriving in',
      'minutes': 'minutes',
      'estimated': 'Estimated',
      'arrival': 'Arrival',
      'connector': 'Connector',
      'estimatedTime': 'Estimated time',
      'estimatedCost': 'Estimated cost',
      'cancelSearch': 'Cancel search',
      'technicianConfirmed': 'Technician confirmed',
      'serviceInProgress': 'Service in progress',
      'chargingVehicle': 'Charging your vehicle',
      'requestCharge': 'Request Charge',
      'viewActiveService': 'View Active Service',
      'youHaveActiveService': 'You have an active service',
      'tapToFindTechnician': 'Tap to find a technician',
      'cancel': 'Cancel',
      'cancelService': 'Cancel Service',
      'followRealTime': 'Follow in real time',
      'serviceCompleted': 'Service Completed!',
      'howWasExperience': 'How was your experience?',
      'addComment': 'Add comment (optional)',
      'skip': 'Skip',
      'send': 'Send',
      'locationRequired': 'Location Required',
      'locationNeeded':
          'To request a service we need access to your location. Please enable location services.',
      'activate': 'Activate',
      'permissionDenied': 'Permission Denied',
      'cannotContinue':
          'We cannot continue without access to your location. Please grant the necessary permissions in the app settings.',
      'goToSettings': 'Go to Settings',
      'vehicleRegistration': 'Vehicle Registration',
      'vehicleNeeded':
          'To use VoltGo you need to register your electric vehicle.',
      'whyNeeded': 'Why is it necessary?',
      'whyNeededDetails': '• Identify the required connector type\n'
          '• Calculate accurate charging times\n'
          '• Assign specialized technicians\n'
          '• Provide the best personalized service',
      'registerVehicle': 'Register Vehicle',
      'activeService': 'Active Service',
      'youHaveActiveServiceDialog': 'You already have an active service:',
      'request': 'Request',
      'status': 'Status',
      'requested': 'Requested',
      'whatToDo': 'What would you like to do?',
      'viewService': 'View Service',
      'timeExpired': 'Time Expired',
      'cannotCancelNow': 'It is no longer possible to cancel this service.',
      'technicianOnWay':
          'The technician is already on the way to your location. Please wait for their arrival.',
      'understood': 'Understood',
      'cancellationFee': 'Cancellation fee',
      'feeApplied':
          'A fee of \${fee} will be applied because the technician was already assigned to the service.',
      'technicianAssigned': 'Technician Assigned!',
      'technicianAccepted':
          'A technician has accepted your request and is on the way.',
      'seeProgress': 'You can see the technician\'s progress on the map.',
      'serviceExpired': 'Service Expired',
      'serviceAutoCancelled': 'Your service has been automatically cancelled.',
      'timeLimitExceeded': 'Time limit exceeded',
      'serviceActiveHour':
          'The service has been active for more than 1 hour without being completed. For your protection, we have automatically cancelled it.',
      'noChargesApplied': 'No charges applied',
      'requestNew': 'Request New',
      'technicianCancelled': 'Technician Cancelled',
      'technicianHasCancelled': 'The technician has cancelled the service.',
      'dontWorry': 'Don\'t worry',
      'technicianCancellationReason':
          'This can happen due to emergencies or technical issues. No charges will be applied to you.',
      'nextStep': 'Next step',
      'requestImmediately':
          'You can request a new service immediately. We will connect you with another available technician.',
      'findAnotherTechnician': 'Find Another Technician',
      'timeWarning': 'Time Warning',
      'serviceWillExpire': 'The service will expire in',
      'viewDetails': 'View Details',
      'finalWarning': 'Final Warning!',
      'serviceExpireMinutes':
          'Your service will expire in {minutes} minutes and will be automatically cancelled.',
      'contactTechnician': 'Contact Technician',
      'timeDetails': 'Time Details',
      'timeRemaining': 'Time remaining',
      'systemInfo': 'System information',
      'serviceInfo': '• Services are automatically cancelled after 1 hour\n'
          '• This protects both the customer and the technician\n'
          '• No charges are applied for automatic cancellations\n'
          '• You can request a new service immediately',
    },
    'es': {
      'appTitle': 'VoltGo',
      'searchingTechnician': 'Buscando técnico',
      'technicianArriving': 'Técnico llegando en',
      'minutes': 'minutos',
      'estimated': 'Estimado',
      'arrival': 'Llegada',
      'connector': 'Conector',
      'estimatedTime': 'Tiempo estimado',
      'estimatedCost': 'Costo estimado',
      'cancelSearch': 'Cancelar búsqueda',
      'technicianConfirmed': 'Técnico confirmado',
      'serviceInProgress': 'Servicio en progreso',
      'chargingVehicle': 'Cargando tu vehículo',
      'requestCharge': 'Solicitar Carga',
      'viewActiveService': 'Ver Servicio Activo',
      'youHaveActiveService': 'Tienes un servicio en curso',
      'tapToFindTechnician': 'Toca para buscar un técnico',
      'cancel': 'Cancelar',
      'cancelService': 'Cancelar Servicio',
      'followRealTime': 'Seguir en tiempo real',
      'serviceCompleted': '¡Servicio Completado!',
      'howWasExperience': '¿Cómo fue tu experiencia?',
      'addComment': 'Agregar comentario (opcional)',
      'skip': 'Omitir',
      'send': 'Enviar',
      'locationRequired': 'Ubicación Necesaria',
      'locationNeeded':
          'Para solicitar un servicio necesitamos acceder a tu ubicación. Por favor, activa los servicios de ubicación.',
      'activate': 'Activar',
      'permissionDenied': 'Permiso Denegado',
      'cannotContinue':
          'No podemos continuar sin acceso a tu ubicación. Por favor, otorga los permisos necesarios en la configuración de la aplicación.',
      'goToSettings': 'Ir a Configuración',
      'vehicleRegistration': 'Registra tu Vehículo',
      'vehicleNeeded':
          'Para utilizar VoltGo necesitas registrar tu vehículo eléctrico.',
      'whyNeeded': '¿Por qué es necesario?',
      'whyNeededDetails': '• Identificar el tipo de conector necesario\n'
          '• Calcular tiempos de carga precisos\n'
          '• Asignar técnicos especializados\n'
          '• Brindar el mejor servicio personalizado',
      'registerVehicle': 'Registrar Vehículo',
      'activeService': 'Servicio Activo',
      'youHaveActiveServiceDialog': 'Ya tienes un servicio en curso:',
      'request': 'Solicitud',
      'status': 'Estado',
      'requested': 'Solicitado',
      'whatToDo': '¿Qué deseas hacer?',
      'viewService': 'Ver Servicio',
      'timeExpired': 'Tiempo Expirado',
      'cannotCancelNow': 'Ya no es posible cancelar este servicio.',
      'technicianOnWay':
          'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
      'understood': 'Entendido',
      'cancellationFee': 'Tarifa de cancelación',
      'feeApplied':
          'Se aplicará una tarifa de \${fee} debido a que el técnico ya estaba asignado al servicio.',
      'technicianAssigned': '¡Técnico asignado!',
      'technicianAccepted':
          'Un técnico ha aceptado tu solicitud y está en camino.',
      'seeProgress': 'Puedes ver el progreso del técnico en el mapa.',
      'serviceExpired': 'Servicio Expirado',
      'serviceAutoCancelled': 'Tu servicio ha sido cancelado automáticamente.',
      'timeLimitExceeded': 'Tiempo límite excedido',
      'serviceActiveHour':
          'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
      'noChargesApplied': 'Sin cargos aplicados',
      'requestNew': 'Solicitar Nuevo',
      'technicianCancelled': 'Técnico Canceló',
      'technicianHasCancelled': 'El técnico ha cancelado el servicio.',
      'dontWorry': 'No te preocupes',
      'technicianCancellationReason':
          'Esto puede suceder por emergencias o problemas técnicos. No se te aplicará ningún cargo.',
      'nextStep': 'Siguiente paso',
      'requestImmediately':
          'Puedes solicitar un nuevo servicio inmediatamente. Te conectaremos con otro técnico disponible.',
      'findAnotherTechnician': 'Buscar Otro Técnico',
      'timeWarning': 'Advertencia de Tiempo',
      'serviceWillExpire': 'El servicio expirará en',
      'viewDetails': 'Ver Detalles',
      'finalWarning': '¡Último Aviso!',
      'serviceExpireMinutes':
          'Tu servicio expirará en {minutes} minutos y será cancelado automáticamente.',
      'contactTechnician': 'Contactar Técnico',
      'timeDetails': 'Detalles del Tiempo',
      'timeRemaining': 'Tiempo restante',
      'systemInfo': 'Información del sistema',
      'serviceInfo':
          '• Los servicios se cancelan automáticamente después de 1 hora\n'
              '• Esto protege tanto al cliente como al técnico\n'
              '• No se aplican cargos por cancelaciones automáticas\n'
              '• Puedes solicitar un nuevo servicio inmediatamente',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get searchingTechnician =>
      _localizedValues[locale.languageCode]!['searchingTechnician']!;
  String get technicianArriving =>
      _localizedValues[locale.languageCode]!['technicianArriving']!;
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get estimated => _localizedValues[locale.languageCode]!['estimated']!;
  String get arrival => _localizedValues[locale.languageCode]!['arrival']!;
  String get connector => _localizedValues[locale.languageCode]!['connector']!;
  String get estimatedTime =>
      _localizedValues[locale.languageCode]!['estimatedTime']!;
  String get estimatedCost =>
      _localizedValues[locale.languageCode]!['estimatedCost']!;
  String get cancelSearch =>
      _localizedValues[locale.languageCode]!['cancelSearch']!;
  String get technicianConfirmed =>
      _localizedValues[locale.languageCode]!['technicianConfirmed']!;
  String get serviceInProgress =>
      _localizedValues[locale.languageCode]!['serviceInProgress']!;
  String get chargingVehicle =>
      _localizedValues[locale.languageCode]!['chargingVehicle']!;
  String get requestCharge =>
      _localizedValues[locale.languageCode]!['requestCharge']!;
  String get viewActiveService =>
      _localizedValues[locale.languageCode]!['viewActiveService']!;
  String get youHaveActiveService =>
      _localizedValues[locale.languageCode]!['youHaveActiveService']!;
  String get tapToFindTechnician =>
      _localizedValues[locale.languageCode]!['tapToFindTechnician']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get cancelService =>
      _localizedValues[locale.languageCode]!['cancelService']!;
  String get followRealTime =>
      _localizedValues[locale.languageCode]!['followRealTime']!;
  String get serviceCompleted =>
      _localizedValues[locale.languageCode]!['serviceCompleted']!;
  String get howWasExperience =>
      _localizedValues[locale.languageCode]!['howWasExperience']!;
  String get addComment =>
      _localizedValues[locale.languageCode]!['addComment']!;
  String get skip => _localizedValues[locale.languageCode]!['skip']!;
  String get send => _localizedValues[locale.languageCode]!['send']!;
  String get locationRequired =>
      _localizedValues[locale.languageCode]!['locationRequired']!;
  String get locationNeeded =>
      _localizedValues[locale.languageCode]!['locationNeeded']!;
  String get activate => _localizedValues[locale.languageCode]!['activate']!;
  String get permissionDenied =>
      _localizedValues[locale.languageCode]!['permissionDenied']!;
  String get cannotContinue =>
      _localizedValues[locale.languageCode]!['cannotContinue']!;
  String get goToSettings =>
      _localizedValues[locale.languageCode]!['goToSettings']!;
  String get vehicleRegistration =>
      _localizedValues[locale.languageCode]!['vehicleRegistration']!;
  String get vehicleNeeded =>
      _localizedValues[locale.languageCode]!['vehicleNeeded']!;
  String get whyNeeded => _localizedValues[locale.languageCode]!['whyNeeded']!;
  String get whyNeededDetails =>
      _localizedValues[locale.languageCode]!['whyNeededDetails']!;
  String get registerVehicle =>
      _localizedValues[locale.languageCode]!['registerVehicle']!;
  String get activeService =>
      _localizedValues[locale.languageCode]!['activeService']!;
  String get youHaveActiveServiceDialog =>
      _localizedValues[locale.languageCode]!['youHaveActiveServiceDialog']!;
  String get request => _localizedValues[locale.languageCode]!['request']!;
  String get status => _localizedValues[locale.languageCode]!['status']!;
  String get requested => _localizedValues[locale.languageCode]!['requested']!;
  String get whatToDo => _localizedValues[locale.languageCode]!['whatToDo']!;
  String get viewService =>
      _localizedValues[locale.languageCode]!['viewService']!;
  String get timeExpired =>
      _localizedValues[locale.languageCode]!['timeExpired']!;
  String get cannotCancelNow =>
      _localizedValues[locale.languageCode]!['cannotCancelNow']!;
  String get technicianOnWay =>
      _localizedValues[locale.languageCode]!['technicianOnWay']!;
  String get understood =>
      _localizedValues[locale.languageCode]!['understood']!;
  String cancellationFee(String fee) =>
      _localizedValues[locale.languageCode]!['cancellationFee']!
          .replaceAll('{fee}', fee);
  String feeApplied(String fee) =>
      _localizedValues[locale.languageCode]!['feeApplied']!
          .replaceAll('{fee}', fee);
  String get technicianAssigned =>
      _localizedValues[locale.languageCode]!['technicianAssigned']!;
  String get technicianAccepted =>
      _localizedValues[locale.languageCode]!['technicianAccepted']!;
  String get seeProgress =>
      _localizedValues[locale.languageCode]!['seeProgress']!;
  String get serviceExpired =>
      _localizedValues[locale.languageCode]!['serviceExpired']!;
  String get serviceAutoCancelled =>
      _localizedValues[locale.languageCode]!['serviceAutoCancelled']!;
  String get timeLimitExceeded =>
      _localizedValues[locale.languageCode]!['timeLimitExceeded']!;
  String get serviceActiveHour =>
      _localizedValues[locale.languageCode]!['serviceActiveHour']!;
  String get noChargesApplied =>
      _localizedValues[locale.languageCode]!['noChargesApplied']!;
  String get requestNew =>
      _localizedValues[locale.languageCode]!['requestNew']!;
  String get technicianCancelled =>
      _localizedValues[locale.languageCode]!['technicianCancelled']!;
  String get technicianHasCancelled =>
      _localizedValues[locale.languageCode]!['technicianHasCancelled']!;
  String get dontWorry => _localizedValues[locale.languageCode]!['dontWorry']!;
  String get technicianCancellationReason =>
      _localizedValues[locale.languageCode]!['technicianCancellationReason']!;
  String get nextStep => _localizedValues[locale.languageCode]!['nextStep']!;
  String get requestImmediately =>
      _localizedValues[locale.languageCode]!['requestImmediately']!;
  String get findAnotherTechnician =>
      _localizedValues[locale.languageCode]!['findAnotherTechnician']!;
  String get timeWarning =>
      _localizedValues[locale.languageCode]!['timeWarning']!;
  String get serviceWillExpire =>
      _localizedValues[locale.languageCode]!['serviceWillExpire']!;
  String get viewDetails =>
      _localizedValues[locale.languageCode]!['viewDetails']!;
  String get finalWarning =>
      _localizedValues[locale.languageCode]!['finalWarning']!;
  String serviceExpireMinutes(String minutes) =>
      _localizedValues[locale.languageCode]!['serviceExpireMinutes']!
          .replaceAll('{minutes}', minutes);
  String get contactTechnician =>
      _localizedValues[locale.languageCode]!['contactTechnician']!;
  String get timeDetails =>
      _localizedValues[locale.languageCode]!['timeDetails']!;
  String get timeRemaining =>
      _localizedValues[locale.languageCode]!['timeRemaining']!;
  String get systemInfo =>
      _localizedValues[locale.languageCode]!['systemInfo']!;
  String get serviceInfo =>
      _localizedValues[locale.languageCode]!['serviceInfo']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
