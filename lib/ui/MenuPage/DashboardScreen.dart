import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wisetrack_app/data/models/User/UserDetail.dart';
import 'dart:async';

import 'package:wisetrack_app/data/models/vehicles/Vehicle.dart';
import 'package:wisetrack_app/data/models/vehicles/VehiclePositionModel.dart';
import 'package:wisetrack_app/data/services/NotificationsService.dart';
import 'package:wisetrack_app/data/services/VehicleServicePosition.dart';
import 'package:wisetrack_app/data/services/auth_api_service.dart';
import 'package:wisetrack_app/data/services/notification_service.dart';
import 'package:wisetrack_app/data/services/vehicles_service.dart';
import 'package:wisetrack_app/ui/MenuPage/AppDrawer.dart';
import 'package:wisetrack_app/ui/MenuPage/moviles/FilterBottomSheet.dart';
import 'package:wisetrack_app/ui/MenuPage/moviles/SecurityActionsScreen.dart';
import 'package:wisetrack_app/ui/MenuPage/moviles/VehicleDetailScreen.dart';
import 'package:wisetrack_app/ui/color/app_colors.dart';
import 'package:wisetrack_app/ui/profile/EditProfileScreen.dart';
import 'package:wisetrack_app/utils/AnimatedTruckProgress.dart';
import 'package:wisetrack_app/utils/NotificationCountService.dart';
import 'package:wisetrack_app/utils/TokenStorage.dart';
import 'dart:ui' as ui;
import 'dart:math' show pi;
import '../../data/services/UserService.dart';
import 'package:location/location.dart' as loc;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};

  bool _isLoading = true;
  late AnimationController _animationController;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  Map<String, LatLng> _vehiclePositions = {};
  Map<int, String> _vehicleTypeMap = {};
  UserData? _currentUser;

  Position? _lastKnownPosition;
  static const double _locationChangeThreshold = 50.0;
  Set<String> _currentFilters = {};
  Set<Marker> _allMarkers = {};
  Set<Marker> _visibleMarkers = {};
  final _markerCache = <String, BitmapDescriptor>{};

  bool _isLoggingOut = false;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-32.775, -71.229),
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _searchFocusNode.addListener(_onSearchFocusChange);
    _searchController.addListener(_filterVehicles);
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      // 1. Ejecutamos todas las llamadas de red y de permisos en PARALELO.
      final results = await Future.wait([
        VehicleService.getAllVehicles(), // Índice 0
        VehiclePositionService.getVehiclesPositions(), // Índice 1
        VehicleService.getVehicleTypes(), // Índice 2
        UserService.getUserDetail(), // Índice 3
        NotificationCountService
            .updateCount(), // Índice 4 (No devuelve nada importante)
        _getInitialUserPosition(), // Índice 5 (Nueva función auxiliar)
      ]);

      // 2. Una vez que TODO ha llegado, procesamos los resultados.
      final List<Vehicle> vehicles = results[0] as List<Vehicle>;
      final VehiclePositionResponse positionResponse =
          results[1] as VehiclePositionResponse;
      final List<VehicleType> types = results[2] as List<VehicleType>;
      final UserDetailResponse userResponse = results[3] as UserDetailResponse;
      final Position? userPosition = results[5] as Position?;

      // 3. Preparamos los datos para el estado.
      final Map<int, String> typesMap = {
        for (var type in types) type.id: type.name
      };

      if (userPosition != null && mounted) {
        _initialCameraPosition = CameraPosition(
          target: LatLng(userPosition.latitude, userPosition.longitude),
          zoom: 8.0,
        );
      }

      // 4. Actualizamos el estado de la UI una sola vez con los datos principales.
      // Esto hace que el mapa y la UI aparezcan más rápido.
      if (mounted) {
        setState(() {
          _allVehicles = vehicles;
          _vehicleTypeMap = typesMap;
          _filteredVehicles = List.from(_allVehicles);
          _currentUser = userResponse.data;
          _isLoading = false; // <-- Mostramos la UI principal aquí
        });
        _animationController.stop();
      }

      // 5. Configuramos los marcadores de forma asíncrona.
      // El usuario ya ve el mapa mientras los marcadores se preparan.
      await _setupMarkers(positionResponse.data);

      // 6. Enviamos datos del dispositivo (esto puede ser al final y sin esperar).
      final notificationService = NotificationServiceFirebase();
      notificationService.initAndSendDeviceData();
    } catch (e) {
      print('Error al inicializar datos del dashboard: $e');
      if (e.toString().contains('401')) {
        if (mounted) await _handleInvalidToken();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudieron cargar los datos: $e')),
          );
          setState(() => _isLoading = false); // Detener carga en otros errores
        }
      }
    }
  }

  // Separa la lógica de permisos y obtención de la ubicación para usarla en Future.wait
  Future<Position?> _getInitialUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("No se pudo obtener la ubicación inicial: $e");
      return null;
    }
  }

  Widget _statusIconShield(String baseName, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Image.asset(
        'assets/images/shield2.png',
        width: 22.0,
        height: 22.0,
      ),
    );
  }

  Widget _statusIcon(String baseName, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Image.asset(
        'assets/images/${baseName}_${isActive ? 'on' : 'off'}.png',
        width: 12.0,
        height: 12.0,
      ),
    );
  }

  Future<void> _handleInvalidToken() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Tu sesión ha expirado. Por favor, inicia sesión de nuevo.'),
        backgroundColor: Colors.orange,
      ),
    );

    await TokenStorage.deleteToken();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _initializeDashboardData() async {
    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      final results = await Future.wait([
        VehicleService.getAllVehicles(),
        VehiclePositionService.getVehiclesPositions(),
        VehicleService.getVehicleTypes(),
        UserService.getUserDetail(),
      ]);

      final List<Vehicle> vehicles = results[0] as List<Vehicle>;
      final VehiclePositionResponse positionResponse =
          results[1] as VehiclePositionResponse;
      final List<VehicleType> types = results[2] as List<VehicleType>;
      final UserDetailResponse userResponse = results[3] as UserDetailResponse;

      final Map<int, String> typesMap = {
        for (var type in types) type.id: type.name
      };

      await _setupMarkers(positionResponse.data);

      if (mounted) {
        setState(() {
          _allVehicles = vehicles;
          _vehicleTypeMap = typesMap;
          _filteredVehicles = List.from(_allVehicles);
          _currentUser = userResponse.data;
          _isLoading = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    } catch (e) {
      print('Error al inicializar datos del dashboard: $e');

      if (e.toString().contains('401')) {
        if (mounted) {
          await _handleInvalidToken();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudieron cargar los datos: $e')),
          );
        }
      }
    } finally {
      if (mounted && !_isLoggingOut && _isLoading) {
        setState(() => _isLoading = false);
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  Future<void> _setupMarkers(List<VehicleCurrentPosition> positions) async {
    final Map<String, LatLng> positionsMap = {};
    final Set<Marker> vehicleMarkers = {};

    for (final position in positions) {
      final latLng = LatLng(position.latitude, position.longitude);
      positionsMap[position.vehiclePlate] = latLng;

      final markerIcon = await _getMarkerIcon(
        position.ignitionStatus,
        position.direction,
        verticalAdjustment: -10.0,
      );

      vehicleMarkers.add(
        Marker(
          markerId: MarkerId(position.vehiclePlate),
          position: latLng,
          infoWindow: InfoWindow(
            title: position.vehiclePlate,
            snippet: 'Velocidad: ${position.speed.toStringAsFixed(1)} km/h',
            onTap: () {
              _navigateToDetail(position.vehiclePlate);
            },
          ),
          icon: markerIcon,
          onTap: () {
            _navigateToDetail(position.vehiclePlate);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value != 'user_location');
        _markers.addAll(vehicleMarkers);
        _vehiclePositions = positionsMap;
        _allMarkers = vehicleMarkers;
        _visibleMarkers = vehicleMarkers;
      });
    }
  }

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = List.from(_allVehicles);
      } else {
        _filteredVehicles = _allVehicles.where((vehicle) {
          final typeName =
              _vehicleTypeMap[vehicle.vehicleType]?.toLowerCase() ?? '';
          return vehicle.plate.toLowerCase().contains(query) ||
              typeName.contains(query);
        }).toList();
      }
    });
  }

  void _onVehicleSelected(Vehicle vehicle) {
    _navigateToDetail(vehicle.plate);
  }

  void _navigateToDetail(String plate) {
    _searchFocusNode.unfocus();
    _searchController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailScreen(plate: plate),
      ),
    );
  }

  Future<BitmapDescriptor> _getMarkerIcon(bool isIgnitionOn, int direction,
      {double verticalAdjustment = 0.0}) async {
    final cacheKey = '${isIgnitionOn ? 'on' : 'off'}_$direction';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final Uint8List baseIcon = await _loadAsset(
      isIgnitionOn
          ? 'assets/images/icons/market_green.png'
          : 'assets/images/icons/market_red2.png',
    );

    final baseCodec = await ui.instantiateImageCodec(baseIcon);
    final baseFrame = await baseCodec.getNextFrame();
    final baseImage = baseFrame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder,
        Rect.fromLTRB(
            0, 0, baseImage.width.toDouble(), baseImage.height.toDouble()));

    canvas.drawImage(baseImage, Offset.zero, Paint());

    if (isIgnitionOn) {
      final Uint8List arrowIcon =
          await _loadAsset('assets/images/icons/arrow2.png');

      final arrowCodec = await ui.instantiateImageCodec(arrowIcon);
      final arrowFrame = await arrowCodec.getNextFrame();
      final arrowImage = arrowFrame.image;

      final desiredArrowWidth = baseImage.width * 0.5;
      final scaleFactor = desiredArrowWidth / arrowImage.width;
      final scaledArrowHeight = arrowImage.height * scaleFactor;

      canvas.save();

      canvas.translate(
          baseImage.width / 2, (baseImage.height / 2) + verticalAdjustment);

      canvas.rotate((direction - 90) * pi / 180);

      canvas.scale(scaleFactor, scaleFactor);

      canvas.drawImage(arrowImage,
          Offset(-arrowImage.width / 2, -arrowImage.height / 2), Paint());

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(baseImage.width, baseImage.height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.fromBytes(bytes);
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  Future<BitmapDescriptor> _createDirectionalMarker(
      Uint8List baseImage, int direction) async {
    final Uint8List arrowIcon =
        await _loadAsset('assets/images/icons/arrow.png');

    final codec = await instantiateImageCodec(baseImage);
    final frame = await codec.getNextFrame();
    final baseImageBitmap = frame.image;

    final arrowCodec = await instantiateImageCodec(arrowIcon);
    final arrowFrame = await arrowCodec.getNextFrame();
    final arrowBitmap = arrowFrame.image;

    final recorder = PictureRecorder();
    final canvas = Canvas(
        recorder,
        Rect.fromPoints(
          Offset(0, 0),
          Offset(baseImageBitmap.width.toDouble(),
              baseImageBitmap.height.toDouble()),
        ));

    canvas.drawImage(baseImageBitmap, Offset.zero, Paint());

    final arrowPaint = Paint();
    final arrowSize =
        Size(arrowBitmap.width.toDouble(), arrowBitmap.height.toDouble());

    final centerX = baseImageBitmap.width / 2;
    final centerY = baseImageBitmap.height / 2;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate((direction * pi) / 180);
    canvas.translate(-centerX, -centerY);

    canvas.drawImage(
      arrowBitmap,
      Offset(centerX - arrowSize.width / 2, centerY - arrowSize.height / 2),
      arrowPaint,
    );

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      baseImageBitmap.width,
      baseImageBitmap.height,
    );

    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  Future<Uint8List> _loadAsset(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  String _getIconPathForVehicleType(String typeName) {
    final normalizedTypeName =
        typeName.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
    switch (normalizedTypeName) {
      case 'tracto':
        return 'assets/images/icons/tracto.png';
      case 'camion_3_4':
        return 'assets/images/icons/camion_3_4.png';
      case 'rampla_seca':
        return 'assets/images/icons/rampla_seca.png';
      case 'rampla_fria':
        return 'assets/images/icons/rampla_fria.png';
      case 'liviano':
        return 'assets/images/icons/liviano.png';
      case 'cama_baja':
        return 'assets/images/icons/cama_baja.png';
      case 'tolva':
        return 'assets/images/icons/tolva.png';
      case 'caex':
        return 'assets/images/icons/caex.png';
      case 'grúa_horquilla':
        return 'assets/images/icons/grua_horquilla.png';
      case 'pluma':
        return 'assets/images/icons/pluma.png';
      case 'grúa_vehicular':
        return 'assets/images/icons/grua_vehicular.png';
      case 'carro_bomba':
        return 'assets/images/icons/carro_bomba.png';
      case 'furgón':
        return 'assets/images/icons/furgon.png';
      case 'retro_excavadora':
        return 'assets/images/icons/retro_excavadora.png';
      case 'cargador_frontal':
        return 'assets/images/icons/cargador_frontal.png';
      case 'otro':
        return 'assets/images/icons/otro.png';
      case 'cisterna':
        return 'assets/images/icons/cisterna.png';
      case 'bus':
        return 'assets/images/icons/bus.png';
      default:
        return 'assets/images/icons/otro.png';
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    final filteredVehicles = _allVehicles.where((vehicle) {
      final vehicleTypeName = _vehicleTypeMap[vehicle.vehicleType] ?? '';

      final matchesSearchQuery = vehicle.plate.toLowerCase().contains(query) ||
          vehicleTypeName.toLowerCase().contains(query);

      if (_currentFilters.isEmpty) return matchesSearchQuery;

      final typeMatches =
          !_currentFilters.any((f) => _vehicleTypeMap.values.contains(f)) ||
              _currentFilters.contains(vehicleTypeName);
      final connectionMatches = !_currentFilters.contains('Online') &&
              !_currentFilters.contains('Offline') ||
          (_currentFilters.contains('Online') && vehicle.statusDevice == 1) ||
          (_currentFilters.contains('Offline') && vehicle.statusDevice == 0);
      final engineStatusMatches = !_currentFilters.contains('Encendido') &&
              !_currentFilters.contains('Apagado') ||
          (_currentFilters.contains('Encendido') &&
              vehicle.statusVehicle == 1) ||
          (_currentFilters.contains('Apagado') && vehicle.statusVehicle == 0);

      return matchesSearchQuery &&
          typeMatches &&
          connectionMatches &&
          engineStatusMatches;
    }).toList();

    final Set<String> filteredPlates =
        filteredVehicles.map((v) => v.plate).toSet();
    final Set<Marker> visibleMarkers = _allMarkers.where((marker) {
      return marker.markerId.value == 'user_location' ||
          filteredPlates.contains(marker.markerId.value);
    }).toSet();

    setState(() {
      _filteredVehicles = filteredVehicles;
      _visibleMarkers = visibleMarkers;
    });
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          drawer: AppDrawer(onLogout: _logout),
          body: Stack(
            children: [
              if (!_isLoading)
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onTap: (_) => _searchFocusNode.unfocus(),
                ),
              if (!_isLoading) _buildTopSearchBar(),
              if (!_isLoading) _buildFloatingActionButtons(),
              if (_isLoading || _isLoggingOut)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child:
                        AnimatedTruckProgress(animation: _animationController),
                  ),
                ),
            ],
          ),
        ),
        if (_isLoading || _isLoggingOut)
          Positioned.fill(
            child: AnimatedTruckProgress(animation: _animationController),
          ),
      ],
    );
  }

  // En DashboardScreen.dart

  Widget _buildTopSearchBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Builder(builder: (context) {
                  return ValueListenableBuilder<int>(
                    valueListenable:
                        NotificationCountService.unreadCountNotifier,
                    builder: (context, unreadCount, child) {
                      final bool hasNotifications = unreadCount > 0;

                      // Define el color del fondo y del ícono dinámicamente
                      final Color backgroundColor =
                          hasNotifications ? AppColors.primary : Colors.white;
                      final Color iconColor =
                          hasNotifications ? Colors.white : Colors.black54;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Botón del menú con color dinámico
                          Container(
                            decoration: BoxDecoration(
                                color:
                                    backgroundColor, // <-- Se usa el color dinámico
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 5,
                                      color: Colors.black.withOpacity(0.2))
                                ]),
                            child: IconButton(
                                icon: Icon(Icons.menu, color: iconColor),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer()),
                          ),
                          // Badge (se mantiene igual)
                          if (hasNotifications)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                }),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 5,
                              color: Colors.black.withOpacity(0.2))
                        ]),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Buscar un móvil',
                        border: InputBorder.none,
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _openFilterBottomSheet();
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Transform.scale(
                                scale: 0.7,
                                child: ImageIcon(
                                    const AssetImage(
                                        'assets/images/icon_filter.png'),
                                    color: AppColors.primary)),
                          ),
                        ),
                        contentPadding: const EdgeInsets.only(left: 20),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildDriverInfo(),
              ],
            ),
            _buildSearchResultsList(),
          ],
        ),
      ),
    );
  }

  Future<void> _centerOnUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Para continuar, por favor activa el GPS.'),
        ));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Los permisos de ubicación son necesarios.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Permisos bloqueados. Habilítalos en la configuración.'),
        ));
      }
      await openAppSettings();
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 8.0,
          );
        });
      }
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    }
  }

  Widget _buildSearchResultsList() {
    if (!_isSearchFocused || _filteredVehicles.isEmpty) {
      return const SizedBox.shrink();
    }
    const double itemHeight = 54.0;
    final int displayItemCount =
        _filteredVehicles.length > 5 ? 5 : _filteredVehicles.length;
    final double containerHeight = displayItemCount * itemHeight;

    return Container(
      margin: const EdgeInsets.only(top: 10.0, left: 56.0, right: 56.0),
      height: containerHeight,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.15))
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _filteredVehicles.length,
          itemBuilder: (context, index) {
            final vehicle = _filteredVehicles[index];
            final String vehicleTypeName =
                _vehicleTypeMap[vehicle.vehicleType] ?? 'Desconocido';
            final String vehicleIconPath =
                _getIconPathForVehicleType(vehicleTypeName);

            final Color iconBgColor = vehicle.statusDevice == 1
                ? AppColors.primary.withOpacity(0.8)
                : Colors.red.shade400;

            bool isLocationActive = vehicle.statusVehicle == 1;
            bool isGpsActive = vehicle.statusDevice == 1;
            bool isKeyActive = false;
            bool isShieldActive = false;

            return ListTile(
              leading: GestureDetector(
                onTap: () => _focusOnVehicle(vehicle),
                child: CircleAvatar(
                  backgroundColor: iconBgColor,
                  radius: 20,
                  child: Image.asset(
                    vehicleIconPath,
                    width: 24,
                    height: 24,
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              title: Text(
                vehicle.plate,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
              onTap: () => _onVehicleSelected(vehicle),
              dense: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusIcon('ubi', isLocationActive),
                  _statusIcon('gps', isGpsActive),
                  _statusIcon('llave', isKeyActive),
                  GestureDetector(
                    onTap: () {
                      _searchFocusNode.unfocus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecurityActionsScreen(
                            plate: vehicle.plate,
                          ),
                        ),
                      );
                    },
                    child: _statusIconShield('shield', isShieldActive),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 16),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    _animationController.repeat();

    try {
      final logoutResponse = await AuthService.logout();

      if (logoutResponse.detail == null ||
          logoutResponse.detail!.contains('Error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                logoutResponse.detail ?? 'Error desconocido al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error durante el logout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      await TokenStorage.deleteToken();

      _animationController.stop();
      _animationController.reset();

      if (mounted) {
        setState(() => _isLoggingOut = false);
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  void _updateUserLocationMarker(Position position) {
    setState(() {
      _markers
          .removeWhere((m) => m.markerId == const MarkerId('user_location'));
    });
  }

  Widget _buildDriverInfo() {
    return FutureBuilder<UserDetailResponse>(
      future: UserService.getUserDetail(),
      builder: (context, snapshot) {
        final ImageProvider? profileImage =
            (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data!.data.userImage != null)
                ? NetworkImage(snapshot.data!.data.userImage!)
                : null;

        return Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                 Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditProfileScreen()),
          ).then((_) {
            
            setState(() {
          
            });
          });
        },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    image: profileImage != null
                        ? DecorationImage(
                            image: profileImage,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImage == null
                      ? Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _focusOnVehicle(Vehicle vehicle) async {
    final LatLng? position = _vehiclePositions[vehicle.plate];

    if (position == null) {
      print('No se encontró la posición para el vehículo ${vehicle.plate}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No se encontró la posición para el vehículo ${vehicle.plate}'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    _searchFocusNode.unfocus();

    final GoogleMapController controller = await _mapController.future;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 8.0,
        ),
      ),
    );

    await controller.showMarkerInfoWindow(MarkerId(vehicle.plate));
  }

  void _openFilterBottomSheet() async {
    _searchFocusNode.unfocus();
    final Set<String>? newFilters = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FilterBottomSheet(initialFilters: _currentFilters);
      },
    );

    if (newFilters != null && mounted) {
      setState(() {
        _currentFilters = newFilters;
        _applyFilters();
      });
    }
  }

  Widget _buildFloatingActionButtons() {
    return Positioned(
      bottom: 40,
      right: 16,
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final controller = await _mapController.future;
              controller.animateCamera(CameraUpdate.zoomIn());
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fondoFloating.png'),
                  fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Image.asset(
                  'assets/images/mas.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final controller = await _mapController.future;
              controller.animateCamera(CameraUpdate.zoomOut());
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fondoFloating.png'),
                  fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Image.asset(
                  'assets/images/menos.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _centerOnUserLocation,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fondoFloating.png'),
                  fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.center,
              child: Padding(
                                padding: const EdgeInsets.only(bottom: 5),

                child: Image.asset(
                  'assets/images/gps.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
