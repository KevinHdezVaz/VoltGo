import 'dart:async';
import 'package:Voltgo_app/data/logic/dashboard/DashboardLogic.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Enum para el estado del conductor
enum DriverStatus { offline, online, incomingRequest, enRouteToUser, onService }

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late final DashboardLogic _logic;
  bool isLoading = true;

  // Estado principal que controla la UI del conductor
  DriverStatus _driverStatus = DriverStatus.offline;

  @override
  void initState() {
    super.initState();
    _logic = DashboardLogic();
    _initializeApp();
  }

  // ---- Simulación de una nueva solicitud ----
  void _simulateIncomingRequest() {
    if (_driverStatus == DriverStatus.online) {
      setState(() {
        _driverStatus = DriverStatus.incomingRequest;
      });
    }
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // La lógica de inicialización del mapa se mantiene igual
    setState(() => isLoading = true);
    try {
      final position = await _logic.getCurrentUserPosition();
      if (position != null) {
        setState(() {
          _logic.initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.5,
          );
          _logic.addUserMarker(position);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar el mapa: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Cambia el estado del conductor entre online y offline
  void _toggleOnlineStatus(bool isOnline) {
    setState(() {
      _driverStatus = isOnline ? DriverStatus.online : DriverStatus.offline;
    });
  }

  // --- Lógica de flujo de servicio ---
  void _acceptRequest() {
    setState(() => _driverStatus = DriverStatus.enRouteToUser);
  }

  void _rejectRequest() {
    setState(() => _driverStatus = DriverStatus.online);
  }

  void _updateServiceStatus() {
    setState(() {
      if (_driverStatus == DriverStatus.enRouteToUser) {
        _driverStatus = DriverStatus.onService;
      } else if (_driverStatus == DriverStatus.onService) {
        _driverStatus = DriverStatus.online; // Vuelve a estar disponible
      }
    });
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // La UI del conductor se construye aquí
          _buildDriverUI(),

          if (isLoading) const Center(child: CircularProgressIndicator()),

          // Botón flotante para simular una nueva solicitud (SOLO PARA PRUEBAS)
          if (_driverStatus == DriverStatus.online)
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                onPressed: _simulateIncomingRequest,
                backgroundColor: Colors.amber,
                child: const Icon(Icons.notifications_active),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildDriverUI() {
    return Stack(
      children: [
        // Panel superior siempre visible
        _buildTopHeaderPanel(),

        // Paneles inferiores que cambian según el estado
        if (_driverStatus == DriverStatus.incomingRequest)
          _buildIncomingRequestPanel(),

        if (_driverStatus == DriverStatus.enRouteToUser ||
            _driverStatus == DriverStatus.onService)
          _buildActiveServicePanel(),
      ],
    );
  }

  /// Panel superior con el Switch de estado y las ganancias.
  Widget _buildTopHeaderPanel() {
    bool isOnline = _driverStatus != DriverStatus.offline;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOnline)
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ganancias Hoy',
                            style: TextStyle(color: Colors.grey)),
                        Text('\$125.50',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  Row(
                    children: [
                      Text(
                        isOnline ? 'En Línea' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isOnline,
                        onChanged: _toggleOnlineStatus,
                        activeTrackColor: Colors.green.shade200,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Panel para una nueva solicitud entrante.
  Widget _buildIncomingRequestPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('NUEVA SOLICITUD',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('5 min (2.3 km)',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Conector CCS1 - Carga de emergencia',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 16),
              const LinearProgressIndicator(), // Simula el tiempo para aceptar
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _rejectRequest,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black),
                    child: const Text('Rechazar'),
                  ),
                  ElevatedButton(
                    onPressed: _acceptRequest,
                    child: const Text('Aceptar'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Panel para un servicio activo (en camino o cargando).
  Widget _buildActiveServicePanel() {
    bool enRuta = _driverStatus == DriverStatus.enRouteToUser;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(enRuta ? 'DIRÍGETE AL CLIENTE' : 'SERVICIO EN CURSO',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Ana García'),
                subtitle: Text('123 Main St, Anytown'),
                trailing: Icon(Icons.phone),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(enRuta ? Icons.navigation : Icons.ev_station),
                label: Text(enRuta ? 'Iniciar Navegación' : 'Finalizar Carga'),
                onPressed: _updateServiceStatus,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
