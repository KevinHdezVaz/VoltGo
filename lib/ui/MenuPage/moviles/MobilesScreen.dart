import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/services/vehicles_service.dart';
import 'package:Voltgo_app/ui/MenuPage/moviles/FilterBottomSheet.dart';
import 'package:Voltgo_app/ui/MenuPage/moviles/SecurityActionsScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/moviles/VehicleDetailScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/data/models/vehicles/Vehicle.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';

class MobilesScreen extends StatefulWidget {
  const MobilesScreen({Key? key}) : super(key: key);

  @override
  _MobilesScreenState createState() => _MobilesScreenState();
}

class _MobilesScreenState extends State<MobilesScreen>
    with SingleTickerProviderStateMixin {
  List<Vehicle> _allVehicles = [];
  List<Vehicle> _displayedVehicles = [];

  Map<int, String> _vehicleTypeMap = {};

  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Set<String> _currentFilters = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _animationController.repeat();

    try {
      final results = await Future.wait([
        VehicleService.getAllVehicles(),
        VehicleService.getVehicleTypes(),
      ]);

      final List<Vehicle> vehicles = results[0] as List<Vehicle>;
      final List<VehicleType> types = results[1] as List<VehicleType>;

      final Map<int, String> typesMap = {
        for (var type in types) type.id: type.name
      };

      await _animationController.forward(from: _animationController.value);
      _animationController.stop();

      if (mounted) {
        setState(() {
          _allVehicles = vehicles;
          _vehicleTypeMap = typesMap;
          _applyFilters();
        });
        _searchController.addListener(_applyFilters);
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        setState(() {
          _errorMessage = "Error al cargar los móviles. Revisa tu conexión.";
          debugPrint('Error al cargar datos iniciales: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.reset();
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    _displayedVehicles = _allVehicles.where((vehicle) {
      final vehicleTypeName = _vehicleTypeMap[vehicle.vehicleType] ?? '';

      final matchesSearchQuery = vehicle.plate.toLowerCase().contains(query) ||
          vehicleTypeName.toLowerCase().contains(query);

      if (_currentFilters.isEmpty) {
        return matchesSearchQuery;
      }

      final typeFilters = _currentFilters
          .where((f) => _vehicleTypeMap.values.contains(f))
          .toSet();
      final bool typeMatches =
          typeFilters.isEmpty || typeFilters.contains(vehicleTypeName);

      final connectionFilters = _currentFilters
          .where((f) => ['Online', 'Offline'].contains(f))
          .toSet();
      final bool connectionMatches = connectionFilters.isEmpty ||
          (connectionFilters.contains('Online') && vehicle.statusDevice == 1) ||
          (connectionFilters.contains('Offline') && vehicle.statusDevice == 0);

      final positionFilters = _currentFilters
          .where((f) => ['Válida', 'Inválida'].contains(f))
          .toSet();
      final bool positionMatches = positionFilters.isEmpty ||
          (positionFilters.contains('Válida') && vehicle.statusVehicle == 1) ||
          (positionFilters.contains('Inválida') && vehicle.statusVehicle == 0);

      final engineStatusFilters = _currentFilters
          .where((f) => ['Encendido', 'Apagado'].contains(f))
          .toSet();
      final bool engineStatusMatches = engineStatusFilters.isEmpty ||
          (engineStatusFilters.contains('Encendido') &&
              vehicle.statusVehicle == 1) ||
          (engineStatusFilters.contains('Apagado') &&
              vehicle.statusVehicle == 0);

      return matchesSearchQuery &&
          typeMatches &&
          connectionMatches &&
          positionMatches &&
          engineStatusMatches;
    }).toList();

    setState(() {});
  }

  String _getIconForVehicleType(String typeName) {
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

  Future<void> _refreshVehicles() async {
    _searchController.removeListener(_applyFilters);
    _searchController.clear();
    await _fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(context),
              Expanded(
                child: _buildBodyContent(),
              ),
            ],
          ),
          if (_isLoading)
            Center(
              child: AnimatedTruckProgress(
                animation: _animationController,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshVehicles,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    if (!_isLoading && _displayedVehicles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshVehicles,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
            child: Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No hay vehículos para mostrar.'
                    : 'No se encontraron resultados.',
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshVehicles,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _displayedVehicles.length,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemBuilder: (context, index) {
          final vehicle = _displayedVehicles[index];
          return _buildVehicleTile(vehicle, context);
        },
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
          indent: 12.0,
          endIndent: 16.0,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.asset(
                  'assets/images/backbtn.png',
                  width: 40,
                  height: 40,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Móviles',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar un móvil por patente',
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.black),
          suffixIcon: GestureDetector(
            onTap: () async {
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
            },
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: ImageIcon(
                const AssetImage('assets/images/icon_filter.png'),
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTile(Vehicle vehicle, BuildContext context) {
    final String vehicleTypeName =
        _vehicleTypeMap[vehicle.vehicleType] ?? 'Desconocido';
    final String vehicleIconPath = _getIconForVehicleType(vehicleTypeName);
    Color iconBgColor = vehicle.statusDevice == 1
        ? AppColors.primary.withOpacity(0.8)
        : Colors.red.shade400;

    bool isLocationActive = vehicle.statusVehicle == 1;
    bool isGpsActive = vehicle.statusDevice == 1;
    bool isKeyActive = false; // Reemplazar con lógica real si está disponible
    bool isShieldActive =
        false; // Reemplazar con lógica real si está disponible

    return InkWell(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailScreen(
              plate: vehicle.plate,
              originScreen: 'mobiles', // Bandera de origen
              onDataChanged: _refreshVehicles,
            ),
          ),
        );

        if (shouldRefresh == true && mounted) {
          _refreshVehicles(); // Recargar la lista
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: iconBgColor,
              child: ClipOval(
                child: Image.asset(
                  vehicleIconPath,
                  width: 30,
                  height: 30,
                  color: Colors.white,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vehicle.plate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusIcon('ubi', isLocationActive),
                _statusIcon('gps', isGpsActive),
                _statusIcon('llave', isKeyActive),
                GestureDetector(
                  onTap: () {
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
          ],
        ),
      ),
    );
  }

  Widget _statusIconShield(String baseName, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Image.asset(
        'assets/images/shield2.png',
        width: 30.0,
        height: 30.0,
      ),
    );
  }

  Widget _statusIcon(String baseName, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Image.asset(
        'assets/images/${baseName}_${isActive ? 'on' : 'off'}.png',
        width: 23.0,
        height: 23.0,
      ),
    );
  }
}
