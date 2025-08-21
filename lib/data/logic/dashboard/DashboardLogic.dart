import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardLogic {
  final Completer<GoogleMapController> mapController = Completer();
  final Set<Marker> markers = {};
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(-32.775, -71.229),
    zoom: 8.0,
  );
  Position? lastKnownPosition;

  Future<Position?> getCurrentUserPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print("Error getting position: $e");
      return null;
    }
  }

  void addUserMarker(Position position) {
    markers.add(Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Tu ubicación'),
    ));
  }

  void addDriverMarker(LatLng position, String driverId) {
    markers.add(Marker(
      markerId: MarkerId(driverId),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Cargador'),
    ));
  }

  void removeDriverMarker(String driverId) {
    markers.removeWhere((marker) => marker.markerId.value == driverId);
  }

  void dispose() {
    mapController.future.then((controller) => controller.dispose());
  }
}
