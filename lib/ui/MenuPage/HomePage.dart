import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWhereToCard(),
              const SizedBox(height: 24),
              _buildShortcuts(),
              const SizedBox(height: 24),
              _buildSectionTitle('Sugerencias para ti'),
              const SizedBox(height: 16),
              _buildSuggestionsCarousel(),
              const SizedBox(height: 24),
              _buildMapView(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS HIJOS PARA MEJOR ORGANIZACIÓN ---

  /// App Bar superior con saludo y avatar de perfil.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[100],
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, Kevin',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.black54, size: 16),
              SizedBox(width: 4),
              Text(
                'Tu ubicación actual',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.black,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Tarjeta principal de acción: "¿A dónde vas?".
  Widget _buildWhereToCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black, size: 28),
            const SizedBox(width: 16),
            Text(
              '¿A dónde vas?',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Atajos para lugares guardados como Casa y Trabajo.
  Widget _buildShortcuts() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ShortcutTile(icon: Icons.home, label: 'Casa'),
        _ShortcutTile(icon: Icons.work, label: 'Trabajo'),
        _ShortcutTile(icon: Icons.star, label: 'Guardados'),
      ],
    );
  }

  /// Título para las diferentes secciones.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Carrusel horizontal para sugerencias o promociones.
  Widget _buildSuggestionsCarousel() {
    final List<Map<String, dynamic>> suggestions = [
      {
        'title': 'Viaja con descuento',
        'subtitle': '15% menos en tu próximo viaje',
        'color': Colors.blue.shade300
      },
      {
        'title': 'Envía un paquete',
        'subtitle': 'Entregas rápidas y seguras',
        'color': Colors.green.shade300
      },
      {
        'title': 'Renta un auto',
        'subtitle': 'Explora la ciudad a tu ritmo',
        'color': Colors.orange.shade300
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: item['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['title'],
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['subtitle'],
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mapa que muestra la ubicación actual en la parte inferior.
  Widget _buildMapView() {
    return SizedBox(
      height: 300, // Fixed height for the map
      child: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
            ),
    );
  }
}

// --- WIDGETS AUXILIARES REUTILIZABLES ---

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ShortcutTile({Key? key, required this.icon, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          child: Icon(icon, size: 28, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
