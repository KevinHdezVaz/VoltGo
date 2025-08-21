import 'dart:async';
import 'package:Voltgo_User/data/logic/dashboard/DashboardLogic.dart';
import 'package:Voltgo_User/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_User/data/services/ServiceRequestService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:Voltgo_User/ui/color/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';

enum PassengerStatus { idle, searching, driverAssigned, onTrip }

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  late final DashboardLogic _logic;
  bool _isLoading = true;
  PassengerStatus _passengerStatus = PassengerStatus.idle;
  Timer? _statusCheckTimer;
  ServiceRequestModel? _activeRequest;

  @override
  void initState() {
    super.initState();
    _logic = DashboardLogic();
    _initializeMap();
  }

  @override
  void dispose() {
    _logic.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackbar('Por favor, activa los servicios de ubicación.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showErrorSnackbar('Permiso de ubicación denegado.');
          return;
        }
      }

      final position = await _logic.getCurrentUserPosition();
      if (position != null) {
        final userLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _logic.initialCameraPosition = CameraPosition(
            target: userLocation,
            zoom: 15.0,
          );
          _logic.addUserMarker(position);
        });

        final controller = await _logic.mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 15.0),
        ));
      } else {
        _showErrorSnackbar('No se pudo obtener la ubicación.');
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar el mapa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestService() async {
    if (_passengerStatus != PassengerStatus.idle) return;

    final position = await _logic.getCurrentUserPosition();
    if (position == null) {
      _showErrorSnackbar('No se pudo obtener tu ubicación actual.');
      return;
    }

    setState(() {
      _passengerStatus = PassengerStatus.searching;
      _isLoading = true;
    });

    try {
      final location = LatLng(position.latitude!, position.longitude!);
      final newRequest = await ServiceRequestService.createRequest(location);

      setState(() {
        _activeRequest = newRequest;
        _isLoading = false;
      });

      _startStatusChecker();
    } catch (e) {
      _showErrorSnackbar(e.toString());
      setState(() {
        _passengerStatus = PassengerStatus.idle;
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _cancelRide() async {
    _statusCheckTimer?.cancel();

    if (_activeRequest == null) {
      setState(() {
        _passengerStatus = PassengerStatus.idle;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ServiceRequestService.cancelRequest(_activeRequest!.id);
      _showErrorSnackbar('Tu solicitud ha sido cancelada.');
    } catch (e) {
      _showErrorSnackbar(
          'No se pudo cancelar la solicitud. Inténtalo de nuevo.');
      print("Error al cancelar: $e");
    } finally {
      if (mounted) {
        setState(() {
          _passengerStatus = PassengerStatus.idle;
          _activeRequest = null;
          _isLoading = false;
          _logic.removeDriverMarker('driver_1');
        });
      }
    }
  }

  void _startStatusChecker() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_activeRequest == null) {
        timer.cancel();
        return;
      }

      try {
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_activeRequest!.id);
        if (updatedRequest.technicianId != null) {
          timer.cancel();
          setState(() {
            _activeRequest = updatedRequest;
            _passengerStatus = PassengerStatus.driverAssigned;
            _logic.addDriverMarker(
              LatLng(
                _logic.initialCameraPosition.target.latitude + 0.01,
                _logic.initialCameraPosition.target.longitude + 0.01,
              ),
              'driver_1',
            );
          });
        }
      } catch (e) {
        print("Error checking status: $e");
      }
    });
  }

  void _startTrip() {
    setState(() => _passengerStatus = PassengerStatus.onTrip);
  }

  void _endTrip() {
    setState(() => _passengerStatus = PassengerStatus.idle);
    _logic.removeDriverMarker('driver_1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _logic.initialCameraPosition,
            onMapCreated: (controller) =>
                _logic.mapController.complete(controller),
            markers: _logic.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(bottom: 150),
          ),
          _buildPassengerUI(),
          if (_isLoading)
            FadeIn(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_passengerStatus == PassengerStatus.idle)
            Positioned(
              bottom: 100,
              right: 16,
              child: ZoomIn(
                child: FloatingActionButton.large(
                  onPressed: _requestService,
                  backgroundColor: AppColors.primary,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 32),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassengerUI() {
    return Stack(
      children: [
        _buildTopStatusPanel(),
        if (_passengerStatus == PassengerStatus.searching)
          FadeInUp(child: _buildSearchingPanel()),
        if (_passengerStatus == PassengerStatus.driverAssigned)
          FadeInUp(child: _buildDriverAssignedPanel()),
        if (_passengerStatus == PassengerStatus.onTrip)
          FadeInUp(child: _buildOnTripPanel()),
      ],
    );
  }

  Widget _buildTopStatusPanel() {
    String statusText;
    Color statusColor;
    switch (_passengerStatus) {
      case PassengerStatus.idle:
        statusText = 'Listo para solicitar';
        statusColor = Colors.grey.shade700;
        break;
      case PassengerStatus.searching:
        statusText = 'Buscando técnico';
        statusColor = Colors.blueAccent;
        break;
      case PassengerStatus.driverAssigned:
        statusText = 'Técnico asignado';
        statusColor = Colors.green;
        break;
      case PassengerStatus.onTrip:
        statusText = 'En servicio';
        statusColor = Colors.green;
        break;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FadeInDown(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (_passengerStatus != PassengerStatus.idle)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: _cancelRide,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingPanel() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: FadeInUp(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buscando un técnico...',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cancelRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    elevation: 2,
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverAssignedPanel() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: FadeInUp(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Técnico asignado',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    'Juan Pérez',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '5 min (2.3 km) - Conector CCS1',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  child: Text(
                    'Confirmar llegada del técnico',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnTripPanel() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: FadeInUp(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Servicio en curso',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(
                    'Juan Pérez',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Cargando - Conector CCS1',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _endTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  child: Text(
                    'Finalizar servicio',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
