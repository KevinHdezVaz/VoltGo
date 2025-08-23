import 'dart:async';
import 'dart:math' as math; // Import para cálculos matemáticos
import 'package:flutter/foundation.dart'; // Import para ChangeNotifier
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardLogic with ChangeNotifier {
  final Completer<GoogleMapController> mapController = Completer();
  final Set<Marker> markers = {};

  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(-32.775, -71.229), // Posición inicial por defecto
    zoom: 8.0,
  );

  Position? lastKnownPosition;

  void addDriverMarker(LatLng position, String markerId) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Técnico',
        snippet: 'En camino hacia ti',
      ),
    );

    markers.add(marker);
    notifyListeners(); // Si estás usando ChangeNotifier
  }

  /// Obtiene la posición actual del usuario solicitando permisos si es necesario.
  Future<Position?> getCurrentUserPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Servicio de ubicación deshabilitado.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          debugPrint("Permisos de ubicación denegados.");
          return null;
        }
      }

      // Obtiene la posición con un tiempo de espera para evitar bloqueos.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Error obteniendo la posición del usuario: $e");
      return null;
    }
  }

  /// Agrega o actualiza el marcador de la ubicación del usuario en el mapa.
  void addUserMarker(Position position) {
    // Elimina el marcador anterior para evitar duplicados.
    markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Tu ubicación'),
    );

    markers.add(userMarker);
    notifyListeners(); // Notifica a los widgets que escuchan para que se redibujen.
  }

  /// Agrega o actualiza el marcador de un técnico en el mapa.
  void updateDriverMarker(String markerId, LatLng newPosition) {
    // Elimina el marcador anterior del mismo técnico.
    markers.removeWhere((marker) => marker.markerId.value == markerId);

    final driverMarker = Marker(
      markerId: MarkerId(markerId),
      position: newPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Técnico',
        snippet: 'En camino hacia ti',
      ),
    );

    markers.add(driverMarker);
    notifyListeners(); // Notifica para actualizar el mapa.
  }

  /// Elimina el marcador de un técnico del mapa.
  void removeDriverMarker(String markerId) {
    markers.removeWhere((marker) => marker.markerId.value == markerId);
    notifyListeners(); // Notifica para quitar el marcador del mapa.
  }

  /// Centra el mapa para mostrar al usuario y al técnico al mismo tiempo.
  Future<void> showBothUserAndTechnician(
      LatLng userLocation, LatLng technicianLocation) async {
    final controller = await mapController.future;

    // Calcula los límites geográficos que contienen ambos puntos.
    double minLat =
        math.min(userLocation.latitude, technicianLocation.latitude);
    double maxLat =
        math.max(userLocation.latitude, technicianLocation.latitude);
    double minLng =
        math.min(userLocation.longitude, technicianLocation.longitude);
    double maxLng =
        math.max(userLocation.longitude, technicianLocation.longitude);

    // Crea un cuadro delimitador (LatLngBounds) para la cámara.
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Anima la cámara para que se ajuste a los límites con un padding.
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  /// Limpia los recursos cuando la clase ya no es necesaria.
  @override
  void dispose() {
    // Es importante llamar a super.dispose() para que ChangeNotifier limpie sus recursos.
    super.dispose();
  }
}
