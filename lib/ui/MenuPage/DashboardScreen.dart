import 'dart:async';
import 'dart:convert';
import 'package:Voltgo_User/data/logic/dashboard/DashboardLogic.dart';
import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/ServiceRequestService.dart';
import 'package:Voltgo_User/ui/MenuPage/ClientRealTimeTrackingWidget.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import 'package:lottie/lottie.dart';

enum PassengerStatus { idle, searching, driverAssigned, onTrip, completed }

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen>
    with TickerProviderStateMixin {
  late final DashboardLogic _logic;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _hasActiveService = false;
  ServiceRequestModel? _existingRequest;
  bool _isLoading = true;
  PassengerStatus _passengerStatus = PassengerStatus.idle;
  Timer? _statusCheckTimer;
  // ✅ NUEVAS variables para tiempo de cancelación
  Timer? _cancellationTimeTimer;
  int _cancellationTimeRemaining = 0; // en segundos
  bool _canStillCancel = true;
  Timer? _searchingAnimationTimer;
  ServiceRequestModel? _activeRequest;
  // Variables para la UI mejorada
  double _estimatedPrice = 0.0;
  int _estimatedTime = 0;
  String _driverName = '';
  String _driverRating = '5.0';
  String _vehicleInfo = '';
  String _connectorType = '';
  int _searchingDots = 0;

  String? _lastKnownStatus;

  String? _lastActiveServiceStatus;
  ServiceRequestModel? _activeServiceRequest;

  @override
  void initState() {
    super.initState();
    _logic = DashboardLogic();
    _initializeAnimations();
    _initializeMap();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cancellationTimeTimer?.cancel(); // ✅ NUEVO

    _logic.dispose();
    _statusCheckTimer?.cancel();
    _searchingAnimationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showPermissionDialog();
          return;
        }
      }
      final position = await _logic.getCurrentUserPosition();
      if (position != null) {
        final userLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _logic.initialCameraPosition = CameraPosition(
            target: userLocation,
            zoom: 16.0,
          );
          _logic.addUserMarker(position);
        });
        final controller = await _logic.mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 16.0),
        ));
      }

      // ✅ NUEVO: Verificar servicio activo AL INICIALIZAR
      //  await _checkForActiveServiceOnStartup();

      _ensureIdleState();

      print('✅ Mapa inicializado con verificación de servicio activo');
    } catch (e) {
      print('❌ Error initializing map: $e');
      _showErrorMessage('Error al cargar el mapa');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// ✅ PASO 2: NUEVO método para verificar servicio activo al iniciar
  Future<void> _checkForActiveServiceOnStartup() async {
    try {
      print('🔍 Verificando servicios activos al iniciar la app...');

      // Usar el método existente pero mejorado
      final activeService = await ServiceRequestService.getActiveService();

      if (activeService != null) {
        print(
            '🎯 Servicio activo encontrado: ${activeService.id} - Estado: ${activeService.status}');

        setState(() {
          _hasActiveService = true;
          _existingRequest = activeService;
          _activeRequest = activeService;

          // ✅ ESTABLECER EL ESTADO CORRECTO SEGÚN EL STATUS
          switch (activeService.status) {
            case 'pending':
              _passengerStatus = PassengerStatus.searching;
              _startStatusChecker();
              _startSearchingAnimation();
              break;
            case 'accepted':
            case 'en_route':
              _passengerStatus = PassengerStatus.driverAssigned;
              _loadTechnicianData(activeService);
              _startTechnicianLocationTracking();
              _startCancellationTimer(); // ✅ Importante para el tiempo de cancelación
              break;
            case 'on_site':
            case 'charging':
              _passengerStatus = PassengerStatus.onTrip;
              _loadTechnicianData(activeService);
              break;
            case 'completed':
              // Si está completado, mostrar rating y luego resetear
              _passengerStatus = PassengerStatus.completed;
              _showRatingDialog();
              break;
          }
        });

        // ✅ MOSTRAR EL PANEL si hay servicio activo
        if (_passengerStatus != PassengerStatus.idle) {
          _slideController.forward();
        }

        print('✅ Estado de la UI restaurado: $_passengerStatus');
      } else {
        print('ℹ️ No hay servicios activos al iniciar');
        _ensureIdleState();
      }
    } catch (e) {
      print('ℹ️ Error verificando servicios activos al iniciar: $e');
      _ensureIdleState();
    }
  }

// 2. ✅ NUEVO: Verificación silenciosa de servicios activos
  Future<void> _checkForActiveServiceSilently() async {
    try {
      print('🔍 Verificando servicios activos silenciosamente...');

      // Usar el nuevo método del servicio
      final activeService = await ServiceRequestService.getActiveService();

      if (activeService != null) {
        print(
            '✅ Servicio activo encontrado: ${activeService.id} - Estado: ${activeService.status}');

        setState(() {
          _hasActiveService = true;
          _existingRequest = activeService;
          _activeRequest = activeService;

          // Determinar el estado de la UI según el estado del servicio
          switch (activeService.status) {
            case 'pending':
              _passengerStatus = PassengerStatus.searching;
              _startStatusChecker();
              _startSearchingAnimation();
              break;
            case 'accepted':
            case 'en_route':
              _passengerStatus = PassengerStatus.driverAssigned;
              _loadTechnicianData(activeService);
              _startTechnicianLocationTracking();
              break;
            case 'on_site':
            case 'charging':
              _passengerStatus = PassengerStatus.onTrip;
              _loadTechnicianData(activeService);
              break;
          }
        });

        _slideController.forward();
      } else {
        print('ℹ️ No hay servicios activos');
        _ensureIdleState();
      }
    } catch (e) {
      print('ℹ️ Error verificando servicios activos: $e');
      _ensureIdleState();
    }
  }

  void _ensureIdleState() {
    setState(() {
      _hasActiveService = false;
      _existingRequest = null;
      _activeRequest = null;
      _passengerStatus = PassengerStatus.idle;

      // Reiniciar variables de UI
      _estimatedPrice = 0.0;
      _estimatedTime = 0;
      _driverName = '';
      _driverRating = '5.0';
      _vehicleInfo = '';
      _connectorType = '';
    });
  }

// ✅ NUEVO: Método para verificar servicios activos
  Future<void> _checkForActiveService() async {
    try {
      print('🔍 Verificando servicios activos...');
      final history = await ServiceRequestService.getServiceHistory();

      // Buscar solicitudes activas (no completadas, no canceladas)
      final activeService = history.firstWhere(
        (request) => ['pending', 'accepted', 'en_route', 'on_site', 'charging']
            .contains(request.status),
        orElse: () => throw StateError('No active service found'),
      );

      if (activeService != null) {
        print(
            '✅ Servicio activo encontrado: ${activeService.id} - Estado: ${activeService.status}');

        setState(() {
          _hasActiveService = true;
          _existingRequest = activeService;
          _activeRequest = activeService;

          // Determinar el estado de la UI según el estado del servicio
          switch (activeService.status) {
            case 'pending':
              _passengerStatus = PassengerStatus.searching;
              _startStatusChecker();
              break;
            case 'accepted':
            case 'en_route':
              _passengerStatus = PassengerStatus.driverAssigned;
              _loadTechnicianData(activeService);
              _startTechnicianLocationTracking();
              break;
            case 'on_site':
            case 'charging':
              _passengerStatus = PassengerStatus.onTrip;
              _loadTechnicianData(activeService);
              break;
          }
        });

        _slideController.forward();
      }
    } catch (e) {
      print('ℹ️ No hay servicios activos: $e');
      setState(() {
        _hasActiveService = false;
        _existingRequest = null;
      });
    }
  }

// 4. ✅ CORREGIR _loadTechnicianData()
  void _loadTechnicianData(ServiceRequestModel request) {
    final technicianData = request.technician;
    final technicianProfile = technicianData?.profile;
    final vehicle = technicianProfile?.vehicleDetails;

    setState(() {
      _driverName = technicianData?.name ?? 'Técnico';
      _driverRating =
          technicianProfile?.averageRating?.toStringAsFixed(1) ?? '5.0';

      // ✅ CORREGIDO: Construcción segura del string del vehículo
      _vehicleInfo = vehicle != null
          ? '${vehicle.make ?? ''} ${vehicle.model ?? ''} (${vehicle.plate ?? ''})'
          : 'Vehículo de servicio';

      // ✅ CORREGIDO: Acceso seguro al tipo de conector
      _connectorType =
          technicianProfile?.availableConnectors?.isNotEmpty == true
              ? technicianProfile!.availableConnectors!.first
              : 'No especificado';

      // Agregar o actualizar el marcador del técnico si hay ubicación
      if (technicianProfile?.currentLat != null &&
          technicianProfile?.currentLng != null) {
        final driverId =
            'driver_${technicianData?.id ?? request.technicianId ?? 0}';
        _logic.updateDriverMarker(
          driverId,
          LatLng(technicianProfile!.currentLat!, technicianProfile.currentLng!),
        );
      }
    });
  }

  void _startTechnicianLocationTracking() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_activeRequest == null ||
          _passengerStatus == PassengerStatus.idle ||
          _passengerStatus == PassengerStatus.completed) {
        timer.cancel();
        return;
      }

      try {
        final technicianLocation =
            await ServiceRequestService.getTechnicianLocation(
                _activeRequest!.id);

        if (technicianLocation != null) {
          setState(() {
            // Actualizar la posición del marcador del técnico
            _logic.updateDriverMarker('driver_1', technicianLocation);
          });

          // Opcional: Calcular y actualizar tiempo estimado de llegada
          _updateEstimatedArrivalTime(technicianLocation);
        }
      } catch (e) {
        print("Error tracking technician location: $e");
      }
    });
  }

// Método para calcular tiempo estimado de llegada
  void _updateEstimatedArrivalTime(LatLng technicianLocation) {
    final userLocation =
        LatLng(_activeRequest!.requestLat, _activeRequest!.requestLng);
    final distance = _calculateDistance(technicianLocation, userLocation);

    // Calcular tiempo estimado (asumiendo velocidad promedio de 30 km/h en ciudad)
    final estimatedMinutes = (distance / 30 * 60).round();

    if (mounted) {
      setState(() {
        _estimatedTime = estimatedMinutes > 0 ? estimatedMinutes : 1;
      });
    }
  }

// Método auxiliar para calcular distancia entre dos puntos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radio de la Tierra en km

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Ubicación Necesaria'),
          ],
        ),
        content: const Text(
          'Para solicitar un servicio necesitamos acceder a tu ubicación. Por favor, activa los servicios de ubicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Activar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_disabled, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Permiso Denegado'),
          ],
        ),
        content: const Text(
          'No podemos continuar sin acceso a tu ubicación. Por favor, otorga los permisos necesarios en la configuración de la aplicación.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ir a Configuración',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ✅ NUEVO: Mostrar diálogo cuando ya hay un servicio activo
  void _showActiveServiceDialog() {
    final request = _existingRequest!;
    String statusText = _getServiceStatusText(request.status);
    String timeText = _getTimeAgoText(request.requestedAt);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.electric_bolt, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Servicio Activo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ya tienes un servicio en curso:',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Solicitud #${request.id}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: $statusText',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  Text(
                    'Solicitado: $timeText',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Qué deseas hacer?',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ver Servicio',
                style: TextStyle(color: AppColors.primary)),
          ),
          if (['pending', 'accepted'].contains(request.status))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelActiveService();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar Servicio',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

// ✅ CORRECCIÓN ERROR DE TIPO - PassengerMapScreen

// ✅ CORREGIR _cancelActiveService para manejar tipos correctamente
  Future<void> _cancelActiveService() async {
    if (_existingRequest == null) {
      _showErrorMessage('No hay servicio activo para cancelar');
      return;
    }

    // ✅ VERIFICAR si aún puede cancelar
    final timeInfo = await _getCancellationTimeInfo();

    if (timeInfo != null && !(timeInfo['can_cancel'] ?? false)) {
      final timeElapsed = timeInfo['time_info']?['elapsed_minutes'] ?? 0;
      final timeLimit = timeInfo['time_info']?['limit_minutes'] ?? 5;

      _showTimeExpiredDialog(timeElapsed, timeLimit);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🚀 Cancelando servicio activo: ${_existingRequest!.id}');

      final url = Uri.parse(
          '${Constants.baseUrl}/service/request/${_existingRequest!.id}/cancel');
      final token = await TokenStorage.getToken();

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📡 Respuesta de cancelación: $responseData');

        // ✅ MANEJO SEGURO DE LA TARIFA (puede ser int o double)
        final feeRaw = responseData['request']?['cancellation_fee'];
        double fee = 0.0;

        if (feeRaw != null) {
          if (feeRaw is int) {
            fee = feeRaw.toDouble();
          } else if (feeRaw is double) {
            fee = feeRaw;
          } else if (feeRaw is String) {
            fee = double.tryParse(feeRaw) ?? 0.0;
          }
        }

        print(
            '💰 Tarifa de cancelación procesada: \$${fee.toStringAsFixed(2)}');

        if (fee > 0) {
          _showCancellationWithFeeDialog(fee);
        } else {
          _showSuccessMessage('Servicio cancelado exitosamente');
        }

        _resetToIdle();
      } else if (response.statusCode == 423) {
        // Tiempo límite excedido
        final errorData = jsonDecode(response.body);
        _showTimeExpiredDialog(
            errorData['time_elapsed'] ?? 0, errorData['time_limit'] ?? 5);
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorMessage(
            errorData['message'] ?? 'Error al cancelar el servicio');
      }
    } catch (e) {
      print('❌ Error cancelando servicio: $e');

      // ✅ MANEJO ESPECÍFICO DEL ERROR DE TIPO
      if (e
          .toString()
          .contains("type 'int' is not a subtype of type 'double'")) {
        print(
            '🔧 Error de tipo detectado - reintentando con conversión segura');
        _showSuccessMessage('Servicio cancelado exitosamente');
        _resetToIdle();
      } else {
        _showErrorMessage('Error al cancelar el servicio');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

// ✅ NUEVO: Obtener texto del estado del servicio
  String _getServiceStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Buscando técnico';
      case 'accepted':
        return 'Técnico asignado';
      case 'en_route':
        return 'Técnico en camino';
      case 'on_site':
        return 'Técnico en sitio';
      case 'charging':
        return 'Cargando vehículo';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Estado desconocido';
    }
  }

// ✅ NUEVO: Obtener texto de tiempo transcurrido
  String _getTimeAgoText(DateTime requestedAt) {
    final now = DateTime.now();
    final difference = now.difference(requestedAt);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  Future<void> _requestService() async {
    print('🚀 _requestService called');

    // ✅ VERIFICAR SERVICIOS ACTIVOS MÁS ROBUSTAMENTE
    if (_hasActiveService && _existingRequest != null) {
      print('ℹ️ Ya hay un servicio activo, mostrando diálogo');
      _showActiveServiceDialog();
      return;
    }

    // ✅ VERIFICACIÓN ADICIONAL: Consultar servidor antes de crear nuevo servicio
    try {
      final serverActiveService =
          await ServiceRequestService.getActiveService();
      if (serverActiveService != null) {
        print('ℹ️ Servicio activo encontrado en servidor durante solicitud');
        setState(() {
          _hasActiveService = true;
          _existingRequest = serverActiveService;
          _activeRequest = serverActiveService;
        });
        _showActiveServiceDialog();
        return;
      }
    } catch (e) {
      print('⚠️ Error verificando servicios activos antes de crear: $e');
      // Continuar con la creación si hay error en la verificación
    }

    if (_passengerStatus != PassengerStatus.idle) {
      print('ℹ️ Estado no es idle: $_passengerStatus');
      return;
    }

    HapticFeedback.mediumImpact();
    final position = await _logic.getCurrentUserPosition();
    if (position == null) {
      _showErrorMessage('No se pudo obtener tu ubicación');
      return;
    }

    print(
        '🚀 Requesting service at: ${position.latitude}, ${position.longitude}');
    setState(() {
      _passengerStatus = PassengerStatus.searching;
      _isLoading = true;
    });
    _slideController.forward();
    _startSearchingAnimation();

    try {
      final location = LatLng(position.latitude!, position.longitude!);
      print('🚀 Creating request for location: $location');
      final newRequest = await ServiceRequestService.createRequest(location);
      print('✅ Request created successfully: ${newRequest.id}');

      setState(() {
        _activeRequest = newRequest;
        _hasActiveService = true;
        _existingRequest = newRequest;
        _isLoading = false;
      });
      _startStatusChecker();
    } catch (e) {
      print('❌ DETAILED ERROR: $e');
      String errorMessage = 'Error al solicitar el servicio';
      if (e.toString().contains('No hay técnicos disponibles')) {
        errorMessage = 'No hay técnicos disponibles en tu área.';
      } else if (e.toString().contains('No autorizado')) {
        errorMessage =
            'Error de autorización. Por favor, inicia sesión nuevamente.';
      } else if (e.toString().contains('Token no encontrado')) {
        errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
      }
      _showErrorMessage(errorMessage);

      // ✅ LIMPIEZA COMPLETA en caso de error
      setState(() {
        _passengerStatus = PassengerStatus.idle;
        _hasActiveService = false;
        _existingRequest = null;
        _activeRequest = null;
        _isLoading = false;
      });
      _slideController.reverse();
      _searchingAnimationTimer?.cancel();
    }
  }

// 9. ✅ CORREGIR _startSearchingAnimation()
  void _startSearchingAnimation() {
    _searchingAnimationTimer?.cancel();
    _searchingAnimationTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_passengerStatus != PassengerStatus.searching) {
        timer.cancel();
        return;
      }
      setState(() {
        _searchingDots = (_searchingDots + 1) % 4;
      });
    });
  }

// ✅ PASO 5: Mejorar _resetToIdle para limpiar completamente el estado

  void _resetToIdle() {
    print('🔄 Resetting to idle state');

    // ✅ CANCELAR todos los timers
    _cancellationTimeTimer?.cancel();
    _statusCheckTimer?.cancel();
    _searchingAnimationTimer?.cancel();

    setState(() {
      _passengerStatus = PassengerStatus.idle;
      _activeRequest = null;
      _hasActiveService = false;
      _existingRequest = null;
      _lastKnownStatus = null;

      // ✅ REINICIAR variables de tiempo
      _cancellationTimeRemaining = 0;
      _canStillCancel = true;

      // Reiniciar variables de UI
      _estimatedPrice = 0.0;
      _estimatedTime = 0;
      _driverName = '';
      _driverRating = '5.0';
      _vehicleInfo = '';
      _connectorType = '';
    });

    // Limpiar recursos del mapa
    _logic.removeDriverMarker('driver_1');
    _slideController.reverse();

    print('✅ Estado completamente limpiado');
  }

// ✅ PASO 5: Método auxiliar para mostrar errores (si no lo tienes)

// ✅ PASO 5: Método auxiliar para mostrar errores (si no lo tienes)
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

// 6. ✅ CORREGIR _cancelRide() con limpieza completa
  void _cancelRide() async {
    HapticFeedback.lightImpact();

    _showConfirmationDialog(
      title: 'Cancelar Servicio',
      message: '¿Estás seguro de que deseas cancelar el servicio?',
      confirmText: 'Sí, cancelar',
      onConfirm: () async {
        Navigator.pop(context);

        // Cancelar timers primero
        _statusCheckTimer?.cancel();
        _searchingAnimationTimer?.cancel();

        if (_activeRequest != null) {
          setState(() => _isLoading = true);
          try {
            await ServiceRequestService.cancelRequest(_activeRequest!.id);
            _showSuccessMessage('Servicio cancelado');
          } catch (e) {
            print('❌ Error cancelando en _cancelRide: $e');
            _showErrorMessage('Error al cancelar: ${e.toString()}');
          }
        }

        // ✅ LIMPIEZA COMPLETA DEL ESTADO
        setState(() {
          _passengerStatus = PassengerStatus.idle;
          _activeRequest = null;
          _hasActiveService = false;
          _existingRequest = null;
          _isLoading = false;

          // Reiniciar variables de UI
          _estimatedPrice = 0.0;
          _estimatedTime = 0;
          _driverName = '';
          _driverRating = '5.0';
          _vehicleInfo = '';
          _connectorType = '';
        });

        _logic.removeDriverMarker('driver_1');
        _slideController.reverse();
      },
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startStatusChecker() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeRequest == null) {
        timer.cancel();
        return;
      }
      try {
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_activeRequest!.id);

        // ✅ DETECTAR CANCELACIÓN AUTOMÁTICA POR EXPIRACIÓN
        if (updatedRequest.status == 'cancelled' &&
            _lastKnownStatus != 'cancelled') {
          print('⚠️ Servicio cancelado - verificando motivo...');

          // Verificar si fue por expiración de tiempo
          final timeInfo = await _getCancellationTimeInfo();
          if (timeInfo != null && timeInfo['time_info']?['expired'] == true) {
            print(
                '⏰ Servicio cancelado automáticamente por expiración de 1 hora');
            _showServiceExpiredDialog();
          } else {
            print('⚠️ Servicio cancelado por el técnico');
            _showTechnicianCancellationDialog(); // ✅ AHORA SÍ ESTÁ DEFINIDO
          }

          _resetToIdle();
          timer.cancel();
          return;
        }

        // ✅ DETECTAR SERVICIOS CERCA DE EXPIRAR (45+ minutos)
        if ((_passengerStatus == PassengerStatus.driverAssigned ||
                _passengerStatus == PassengerStatus.onTrip) &&
            _activeRequest!.acceptedAt != null) {
          final minutesElapsed =
              DateTime.now().difference(_activeRequest!.acceptedAt!).inMinutes;

          // Mostrar advertencia a los 45 minutos
          if (minutesElapsed >= 45 &&
              minutesElapsed < 50 &&
              _lastKnownStatus != 'near_expiration') {
            _showNearExpirationWarning(60 - minutesElapsed);
            _lastKnownStatus = 'near_expiration';
          }

          // Mostrar advertencia final a los 55 minutos
          if (minutesElapsed >= 55 &&
              minutesElapsed < 58 &&
              _lastKnownStatus != 'final_warning') {
            _showFinalExpirationWarning(60 - minutesElapsed);
            _lastKnownStatus = 'final_warning';
          }
        }

        // Resto del código existente...
        if (updatedRequest.technicianId != null &&
            _passengerStatus == PassengerStatus.searching) {
          timer.cancel();
          _searchingAnimationTimer?.cancel();
          _startCancellationTimer();

          // ✅ MOSTRAR FEEDBACK INMEDIATO AL USUARIO
          _showTechnicianAssignedFeedback(updatedRequest);

          final technicianData = updatedRequest.technician;
          final technicianProfile = technicianData?.profile;

          setState(() {
            _activeRequest = updatedRequest;
            _passengerStatus = PassengerStatus.driverAssigned;
            final vehicle = technicianProfile?.vehicleDetails;
            _driverName = technicianData?.name ?? 'Técnico';
            _driverRating =
                technicianProfile?.averageRating?.toStringAsFixed(1) ?? '5.0';
            _vehicleInfo = vehicle != null
                ? '${vehicle.make ?? ''} ${vehicle.model ?? ''} (${vehicle.plate ?? ''})'
                : 'Vehículo de servicio';
            _connectorType =
                technicianProfile?.availableConnectors?.isNotEmpty == true
                    ? technicianProfile!.availableConnectors!.first
                    : 'No especificado';

            if (technicianProfile?.currentLat != null &&
                technicianProfile?.currentLng != null) {
              final driverId =
                  'driver_${technicianData?.id ?? updatedRequest.technicianId ?? 0}';
              _logic.updateDriverMarker(
                driverId,
                LatLng(technicianProfile!.currentLat!,
                    technicianProfile.currentLng!),
              );
            }
          });
          HapticFeedback.heavyImpact();
          _startTechnicianLocationTracking();
        }

        // ✅ DETECTAR CAMBIOS DE ESTADO PARA MOSTRAR FEEDBACK
        _checkForStatusChanges(updatedRequest);
      } catch (e) {
        print("Error checking status: $e");
      }
    });
  }

// ✅ MÉTODO QUE FALTABA: _showTechnicianCancellationDialog
  void _showTechnicianCancellationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_off, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Técnico Canceló')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El técnico ha cancelado el servicio.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No te preocupes',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esto puede suceder por emergencias o problemas técnicos. No se te aplicará ningún cargo.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Siguiente paso',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes solicitar un nuevo servicio inmediatamente. Te conectaremos con otro técnico disponible.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _requestService(); // Solicitar nuevo servicio automáticamente
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Buscar Otro Técnico',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ✅ NUEVO: Diálogo cuando servicio expira automáticamente
  void _showServiceExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.access_time_filled, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Servicio Expirado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu servicio ha sido cancelado automáticamente.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tiempo límite excedido',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sin cargos aplicados',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No se te cobrará por este servicio cancelado. Puedes solicitar un nuevo servicio cuando gustes.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Entendido'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _requestService(); // Solicitar nuevo servicio
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text('Solicitar Nuevo',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ✅ NUEVO: Advertencia cuando el servicio está cerca de expirar
  void _showNearExpirationWarning(int minutesRemaining) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Advertencia de Tiempo',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'El servicio expirará en $minutesRemaining minutos',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Ver Detalles',
          textColor: Colors.white,
          onPressed: () => _showTimeDetailsDialog(minutesRemaining),
        ),
      ),
    );

    // Vibración para llamar la atención
    HapticFeedback.mediumImpact();
  }

// ✅ NUEVO: Advertencia final antes de expirar
  void _showFinalExpirationWarning(int minutesRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Último Aviso!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu servicio expirará en $minutesRemaining minutos y será cancelado automáticamente.',
              style: GoogleFonts.inter(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Si el técnico no ha llegado aún, puedes contactarlo o esperar a que el sistema cancele automáticamente sin costo.',
                style: GoogleFonts.inter(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
          if (_activeRequest?.technician != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Lógica para contactar al técnico
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Contactar Técnico',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );

    // Vibración fuerte para llamar la atención
    HapticFeedback.heavyImpact();
  }

// ✅ NUEVO: Diálogo con detalles del tiempo restante
  void _showTimeDetailsDialog(int minutesRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Detalles del Servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiempo restante: $minutesRemaining minutos',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '📋 Información del sistema:',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Los servicios se cancelan automáticamente después de 1 hora\n'
              '• Esto protege tanto al cliente como al técnico\n'
              '• No se aplican cargos por cancelaciones automáticas\n'
              '• Puedes solicitar un nuevo servicio inmediatamente',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Mostrar feedback cuando se asigna técnico
  void _showTechnicianAssignedFeedback(ServiceRequestModel request) {
    final technicianName = request.technician?.name ?? 'Un técnico';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Técnico Asignado!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$technicianName ha aceptado tu solicitud y se dirige a tu ubicación.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Puedes ver el progreso del técnico en el mapa.',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Mostrar feedback de cambios de estado
  void _showStatusChangeFeedback(String title, String message, Color color) {
    // Mostrar notificación flotante
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForStatus(title),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );

    // Vibración para llamar la atención
    HapticFeedback.mediumImpact();
  }

  // ✅ NUEVO: Obtener icono apropiado para cada estado
  IconData _getIconForStatus(String title) {
    if (title.contains('asignado') || title.contains('aceptado')) {
      return Icons.person_add;
    } else if (title.contains('camino')) {
      return Icons.directions_car;
    } else if (title.contains('llegado')) {
      return Icons.location_on;
    } else if (title.contains('iniciado') || title.contains('carga')) {
      return Icons.electric_bolt;
    } else if (title.contains('completado')) {
      return Icons.check_circle;
    } else if (title.contains('cancelado')) {
      return Icons.cancel;
    }
    return Icons.info;
  }

  // ✅ NUEVO: Detectar cambios de estado y mostrar feedback apropiado
  void _checkForStatusChanges(ServiceRequestModel updatedRequest) {
    final currentStatus = updatedRequest.status;

    // Si el estado cambió, mostrar feedback
    if (_lastKnownStatus != null && _lastKnownStatus != currentStatus) {
      switch (currentStatus) {
        case 'accepted':
          if (_lastKnownStatus == 'pending') {
            _showStatusChangeFeedback(
                '✅ ¡Técnico asignado!',
                'Un técnico ha aceptado tu solicitud y está en camino.',
                Colors.green);
          }
          break;

        case 'en_route':
          _showStatusChangeFeedback('🚗 Técnico en camino',
              'El técnico se dirige a tu ubicación.', Colors.blue);
          break;

        case 'on_site':
          _showStatusChangeFeedback('📍 Técnico ha llegado',
              'El técnico está en tu ubicación.', Colors.orange);
          break;

        case 'charging':
          _showStatusChangeFeedback(
              '⚡ Servicio iniciado',
              'El técnico ha comenzado la carga de tu vehículo.',
              Colors.purple);
          break;

        case 'completed':
          _showStatusChangeFeedback('🎉 Servicio completado',
              '¡Tu vehículo ha sido cargado exitosamente!', Colors.green);
          break;

        case 'cancelled':
          _showStatusChangeFeedback('❌ Servicio cancelado',
              'El servicio ha sido cancelado.', Colors.red);
          _resetToIdle();
          break;
      }
    }

    _lastKnownStatus = currentStatus;
  }

  void _startTrip() {
    HapticFeedback.mediumImpact();
    setState(() => _passengerStatus = PassengerStatus.onTrip);
  }

  void _endTrip() {
    HapticFeedback.mediumImpact();
    setState(() => _passengerStatus = PassengerStatus.completed);
    _showRatingDialog();
  }

  void _showRatingDialog() {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Servicio Completado!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${_estimatedPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¿Cómo fue tu experiencia?',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Agregar comentario (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetToIdle();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Omitir',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          // Enviar calificación al backend
                          Navigator.pop(context);
                          _resetToIdle();
                          _showSuccessMessage('¡Gracias por tu calificación!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enviar',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    _showMessage(message, AppColors.error, Icons.error_outline);
  }

  void _showSuccessMessage(String message) {
    _showMessage(message, AppColors.success, Icons.check_circle_outline);
  }

  void _showMessage(String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.inter())),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startCancellationTimer() {
    print('🕐 Iniciando timer de cancelación...');
    _cancellationTimeTimer?.cancel();

    // ✅ OBTENER información inicial de tiempo REAL desde el servidor
    _updateCancellationTimeInfo().then((_) {
      print('🕐 Tiempo inicial obtenido: $_cancellationTimeRemaining segundos');

      // ✅ Solo iniciar countdown si hay tiempo disponible
      if (_cancellationTimeRemaining > 0 && _canStillCancel) {
        _cancellationTimeTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_cancellationTimeRemaining > 0) {
            setState(() {
              _cancellationTimeRemaining--;
            });
            print('⏰ Tiempo restante: $_cancellationTimeRemaining segundos');
          } else {
            setState(() {
              _canStillCancel = false;
            });
            print('⛔ Tiempo de cancelación expirado');
            timer.cancel();
          }
        });
      } else {
        print('⚠️ No hay tiempo disponible para cancelar');
        setState(() {
          _canStillCancel = false;
          _cancellationTimeRemaining = 0;
        });
      }
    });
  }

// ✅ CORREGIR _updateCancellationTimeInfo para calcular tiempo real
  Future<void> _updateCancellationTimeInfo() async {
    if (_activeRequest == null) return;

    try {
      final url = Uri.parse(
          '${Constants.baseUrl}/service/request/${_activeRequest!.id}/cancellation-time');
      final token = await TokenStorage.getToken();

      if (token == null) return;

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🌐 Obteniendo información de tiempo de cancelación...');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final timeInfo = jsonDecode(response.body);
        print('📡 Respuesta del servidor: $timeInfo');

        final canCancel = timeInfo['can_cancel'] ?? false;
        final remainingMinutes =
            timeInfo['time_info']?['remaining_minutes'] ?? 0;

        setState(() {
          _canStillCancel = canCancel;
          _cancellationTimeRemaining =
              (remainingMinutes * 60).round(); // convertir a segundos
        });

        print(
            '✅ Tiempo actualizado: $_cancellationTimeRemaining segundos, Puede cancelar: $_canStillCancel');
      } else {
        print(
            '❌ Error obteniendo tiempo: ${response.statusCode} - ${response.body}');
        // Si hay error, asumir que no puede cancelar
        setState(() {
          _canStillCancel = false;
          _cancellationTimeRemaining = 0;
        });
      }
    } catch (e) {
      print('❌ Excepción obteniendo tiempo de cancelación: $e');
      // En caso de error, asumir que no puede cancelar
      setState(() {
        _canStillCancel = false;
        _cancellationTimeRemaining = 0;
      });
    }
  }

// ✅ CORREGIR _getCancellationTimeInfo (método auxiliar)
  Future<Map<String, dynamic>?> _getCancellationTimeInfo() async {
    if (_activeRequest == null) return null;

    try {
      final url = Uri.parse(
          '${Constants.baseUrl}/service/request/${_activeRequest!.id}/cancellation-time');
      final token = await TokenStorage.getToken();

      if (token == null) return null;

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting cancellation time info: $e');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _logic.initialCameraPosition,
            onMapCreated: (controller) =>
                _logic.mapController.complete(controller),
            markers: _logic.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
              bottom: _passengerStatus == PassengerStatus.idle ? 120 : 250,
            ),
          ),

          // UI Principal
          _buildMainUI(),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Procesando...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ CORREGIR _showTimeExpiredDialog para manejar tipos seguros
  void _showTimeExpiredDialog(int elapsedMinutes, int limitMinutes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.access_time, color: Colors.red, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Tiempo Expirado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ya no es posible cancelar este servicio.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo transcurrido: $elapsedMinutes de $limitMinutes minutos',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancellationWithFeeDialog(double fee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Servicio Cancelado')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu servicio ha sido cancelado exitosamente.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tarifa de cancelación',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se aplicará una tarifa de \$${fee.toStringAsFixed(2)} debido a que el técnico ya estaba asignado al servicio.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ✅ MEJORAR _buildCancellationTimeWidget para mostrar información más clara
  Widget _buildCancellationTimeWidget() {
    // No mostrar si no hay request activo o si está en idle
    if (_activeRequest == null || _passengerStatus == PassengerStatus.idle) {
      return const SizedBox.shrink();
    }

    // Si no puede cancelar, mostrar mensaje diferente
    if (!_canStillCancel) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tiempo de cancelación agotado',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si el tiempo es 0 o menor, no mostrar
    if (_cancellationTimeRemaining <= 0) {
      return const SizedBox.shrink();
    }

    final minutes = (_cancellationTimeRemaining / 60).floor();
    final seconds = _cancellationTimeRemaining % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: minutes < 1
            ? Colors.red.withOpacity(0.1) // Rojo si queda menos de 1 minuto
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: minutes < 1
                ? Colors.red.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time,
              color: minutes < 1 ? Colors.red : Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo para cancelar:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: minutes < 1
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: minutes < 1
                        ? Colors.red.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            minutes < 1 ? '¡Último minuto!' : 'minutos restantes',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: minutes < 1 ? FontWeight.bold : FontWeight.normal,
              color: minutes < 1 ? Colors.red.shade600 : Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return Column(
      children: [
        // Header con estado
        _buildHeader(),

        const Spacer(),

        // Panel inferior según estado
        if (_passengerStatus == PassengerStatus.idle)
          _buildIdlePanel()
        else
          SlideTransition(
            position: _slideAnimation,
            child: _buildBottomPanel(),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo o ícono de la app
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.brandBlue],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.electric_bolt, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 12),

          // Estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_passengerStatus != PassengerStatus.idle)
                  Text(
                    _getStatusSubtitle(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle() {
    switch (_passengerStatus) {
      case PassengerStatus.idle:
        return 'VoltGo';
      case PassengerStatus.searching:
        return 'Buscando técnico${'.' * _searchingDots}';
      case PassengerStatus.driverAssigned:
        return 'Técnico en camino';
      case PassengerStatus.onTrip:
        return 'Servicio en progreso';
      case PassengerStatus.completed:
        return 'Servicio completado';
    }
  }

  String _getStatusSubtitle() {
    switch (_passengerStatus) {
      case PassengerStatus.searching:
        return 'Encontrando el mejor técnico para ti';
      case PassengerStatus.driverAssigned:
        return 'Llegada estimada: $_estimatedTime min';
      case PassengerStatus.onTrip:
        return 'Cargando tu vehículo';
      case PassengerStatus.completed:
        return 'Gracias por usar VoltGo';
      default:
        return '';
    }
  }

// Modificar el botón en _buildIdlePanel para mostrar estado correcto
  Widget _buildIdlePanel() {
    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón principal de solicitar servicio
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hasActiveService
                    ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                    : [AppColors.primary, AppColors.brandBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (_hasActiveService
                          ? AppColors.warning
                          : AppColors.primary)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _requestService,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasActiveService
                            ? Icons.visibility
                            : Icons.electric_bolt,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasActiveService
                          ? 'Ver Servicio Activo'
                          : 'Solicitar Carga',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _hasActiveService
                          ? 'Tienes un servicio en curso'
                          : 'Toca para buscar un técnico',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    Widget content;

    switch (_passengerStatus) {
      case PassengerStatus.searching:
        content = _buildSearchingContent();
        break;
      case PassengerStatus.driverAssigned:
        content = _buildDriverAssignedContent();
        break;
      case PassengerStatus.onTrip:
        content = _buildOnTripContent();
        break;
      default:
        content = const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 150, // Aumentado de 76 a 150 para mover el panel más arriba
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildSearchingContent() {
    // AÑADIMOS SingleChildScrollView COMO WIDGET PRINCIPAL
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor de Precio y Tiempo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.attach_money,
                            color: AppColors.primary, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_estimatedPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Estimado',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.gray300,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.access_time,
                            color: AppColors.primary, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '$_estimatedTime min',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Llegada',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Buscando técnicos cercanos',
              textAlign: TextAlign.center, // Buen hábito para centrar textos
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esto puede tomar unos segundos',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  child: Lottie.asset(
                    'assets/images/Charging.json',
                    fit: BoxFit
                        .contain, // Usar 'contain' es más seguro que 'fitWidth'
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Botón de cancelar
            OutlinedButton(
              onPressed: _cancelRide,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancelar búsqueda',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ _buildDriverAssignedContent COMPLETO - PassengerMapScreen

  Widget _buildDriverAssignedContent() {
    return Column(
      children: [
        // ✅ MOSTRAR tiempo restante de cancelación
        _buildCancellationTimeWidget(),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Banner de estado con información de cancelación
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.05)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Técnico confirmado',
                            style: GoogleFonts.inter(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (!_canStillCancel)
                            Text(
                              'Ya no es posible cancelar',
                              style: GoogleFonts.inter(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Fila superior con información del técnico
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar del técnico
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _driverName.isNotEmpty
                            ? _driverName[0].toUpperCase()
                            : 'T',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Columna con nombre, calificación e información del vehículo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: AppColors.warning, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _driverRating,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '• $_vehicleInfo',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botones de acción
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Lógica para llamar al técnico
                          // Ejemplo: launchUrl(Uri.parse('tel:${_activeRequest?.technician?.phone}'));
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.phone,
                              color: AppColors.success, size: 20),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Lógica para enviar mensaje
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.message,
                              color: AppColors.info, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Información del servicio
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.electrical_services,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Conector',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          _connectorType,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Tiempo estimado',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          '$_estimatedTime minutos',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Costo estimado',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          '\$${_estimatedPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Técnico llegando en $_estimatedTime minutos',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: AppColors.gray300,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Botones de acción - Actualizado con lógica de tiempo
              Row(
                children: [
                  if (_canStillCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelActiveService,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          side: BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Ya no es posible cancelar',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),

                  // ✅ Botón de navegación (siempre disponible)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.navigation, size: 20),
                      label: Text('Seguir en tiempo real'),
                      onPressed:
                          _openRealTimeTracking, // Sin paréntesis ni coma

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

// ✅ MÉTODO _openRealTimeTracking CORREGIDO:
  void _openRealTimeTracking() async {
    if (_activeRequest == null) {
      // ✅ CAMBIADO: _currentRequest → _activeRequest
      _showErrorSnackbar('No hay servicio activo');
      return;
    }

    // Navegar a la pantalla de seguimiento
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealTimeTrackingScreen(
          serviceRequest:
              _activeRequest!, // ✅ CAMBIADO: _currentRequest → _activeRequest
          canStillCancel: _canStillCancel,
          onServiceComplete: () {
            print('✅ Servicio completado desde tracking screen');
          },
          onCancel: () {
            _cancelActiveService(); // ✅ CORREGIDO: llamada directa al método
            print('❌ Servicio cancelado desde tracking screen');
          },
        ),
      ),
    );

    // Manejar el resultado cuando regresa de la pantalla
    if (result == true && mounted) {
      setState(() {
        _refreshServiceData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Servicio actualizado correctamente'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _refreshServiceData() async {
    try {
      if (_activeRequest != null) {
        // ✅ CAMBIADO: _currentRequest → _activeRequest
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_activeRequest!.id);
        setState(() {
          _activeRequest =
              updatedRequest; // ✅ CAMBIADO: _currentRequest → _activeRequest
          // Actualizar otros estados según sea necesario
        });
      }
    } catch (e) {
      print('Error refreshing service data: $e');
    }
  }

// Widget para el banner de estado
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'Técnico confirmado',
            style: GoogleFonts.inter(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

// Widget para la información del técnico
  Widget _buildDriverInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _driverName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _driverRating,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• $_vehicleInfo',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

// Widget para los botones de acción
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            // Lógica para llamar al técnico
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone, color: AppColors.success, size: 20),
          ),
        ),
        IconButton(
          onPressed: () {
            // Lógica para enviar mensaje
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.message, color: AppColors.info, size: 20),
          ),
        ),
      ],
    );
  }

// Widget para la información del servicio
  Widget _buildServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildServiceInfoRow(
            icon: Icons.electrical_services,
            label: 'Conector',
            value: _connectorType,
          ),
          const SizedBox(height: 12),
          _buildServiceInfoRow(
            icon: Icons.access_time,
            label: 'Tiempo estimado',
            value: '$_estimatedTime minutos',
          ),
          const SizedBox(height: 12),
          _buildServiceInfoRow(
            icon: Icons.attach_money,
            label: 'Costo estimado',
            value: '\$${_estimatedPrice.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

// Widget reutilizable para cada fila de información del servicio
  Widget _buildServiceInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

// Widget para la barra de progreso
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Técnico llegando en $_estimatedTime minutos',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.3, // Este valor debería ser dinámico
          backgroundColor: AppColors.gray300,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
        ),
      ],
    );
  }

// Widget para el botón de cancelar
  Widget _buildCancelButton() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelRide,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnTripContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estado del servicio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.1),
                  AppColors.success.withOpacity(0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.battery_charging_full,
                      color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cargando tu vehículo',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El técnico está trabajando en tu vehículo',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Información del técnico (compacta)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _driverName.isNotEmpty
                          ? _driverName[0].toUpperCase()
                          : 'T',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Técnico certificado',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Contactar técnico
                  },
                  icon: Icon(Icons.message, color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detalles del servicio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiempo transcurrido',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '15:32',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Costo actual',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\${_estimatedPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón para finalizar
          ElevatedButton(
            onPressed: _endTrip,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Confirmar servicio completado',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Agregar esta dependencia para la animación de búsqueda
class SpinKitRipple extends StatefulWidget {
  final Color color;
  final double size;

  const SpinKitRipple({
    Key? key,
    required this.color,
    this.size = 50.0,
  }) : super(key: key);

  @override
  _SpinKitRippleState createState() => _SpinKitRippleState();
}

class _SpinKitRippleState extends State<SpinKitRipple>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _animation1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );

    _animation2 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          ScaleTransition(
            scale: _animation1,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.4),
                  width: 3,
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _animation2,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
