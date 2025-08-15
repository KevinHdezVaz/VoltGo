import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:Voltgo_app/data/models/User/UserDetail.dart';
import 'dart:io';
import 'package:Voltgo_app/data/models/vehicles/VehicleHistoryPoint.dart';
import 'package:Voltgo_app/data/services/UserCacheService.dart';
import 'package:Voltgo_app/data/services/vehicles_service.dart';
import 'package:Voltgo_app/ui/MenuPage/auditoria/CustomDatePickerDialog.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:pdf/widgets.dart' as pw;

class AuditDetailsScreen extends StatefulWidget {
  final String plate;
  const AuditDetailsScreen({Key? key, required this.plate}) : super(key: key);

  @override
  _AuditDetailsScreenState createState() => _AuditDetailsScreenState();
}

class _AuditDetailsScreenState extends State<AuditDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final GlobalKey _dashboardKey = GlobalKey();

  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  final List<String> _timeRanges = ['24 horas', '12 horas', '8 horas'];
  String _selectedRange = '24 horas';
  bool _isRangeDropdownOpen = false;
  bool _isFullscreen = false;
  EdgeInsets _mapPadding = EdgeInsets.zero;
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  List<HistoryPoint> _historyPoints = [];
  String _distanceTraveled = "0 Km";
  String _averageSpeed = "0 km/h";
  String _maxSpeed = "0 km/h";
  String _totalTime = "00:00:00";

  UserData? _cachedUser;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));

    _loadUserData();
    _fetchHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) => _setMapPadding());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setMapPadding() {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bodyHeight = screenHeight - appBarHeight - statusBarHeight;
    final sheetHeight = bodyHeight * 0.6;
    setState(() {
      _mapPadding = EdgeInsets.only(bottom: sheetHeight - 40);
    });
  }

  Future<void> _loadUserData() async {
    final user = await UserCacheService.getCachedUserData();
    if (mounted) {
      setState(() {
        _cachedUser = user;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _animationController.repeat();
    try {
      final endDate = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, 23, 59, 59);
      int hoursToSubtract = int.parse(_selectedRange.split(' ')[0]);
      final history = await VehicleService.getVehicleHistoryByRange(
        plate: widget.plate,
        endDate: endDate,
        rangeInHours: hoursToSubtract,
      );
      if (mounted) {
        _historyPoints = history;
        if (_historyPoints.isNotEmpty) {
          _updateMapWithHistory();
          _calculateAndSetMetrics();
        } else {
          _polylines.clear();
          _markers.clear();
          _resetMetrics();
        }
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = "Error al cargar el historial.";
        debugPrint("Error en fetchHistory: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  void _updateMapWithHistory() async {
    if (_historyPoints.isEmpty) {
      return;
    }
    final points = _historyPoints
        .where((p) => p.latitude != 0.0 && p.longitude != 0.0)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    _polylines.clear();
    if (points.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 5,
          geodesic: true,
        ),
      );
    }
    _markers.clear();
    if (points.isNotEmpty) {
      BitmapDescriptor customIcon = await _getMarkerIconFromAsset(
        'assets/images/truck_check.png',
        width: 130,
      );

      if (!mounted) return;
      _markers.add(Marker(
        markerId: const MarkerId('start'),
        position: points.first,
        icon: customIcon,
        infoWindow: InfoWindow(
          title: 'Inicio',
          snippet: 'Velocidad: ${_historyPoints.first.speed} km/h',
        ),
      ));
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        await Future.delayed(const Duration(milliseconds: 500));
        if (points.length > 1) {
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(points),
              60.0,
            ),
          );
        } else if (points.isNotEmpty) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(points.first, 16),
          );
        }
      }
    }
    setState(() {});
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _calculateAndSetMetrics() {
    if (_historyPoints.length < 2) {
      _resetMetrics();
      return;
    }
    double totalDistance = 0;
    for (int i = 0; i < _historyPoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _historyPoints[i].latitude,
        _historyPoints[i].longitude,
        _historyPoints[i + 1].latitude,
        _historyPoints[i + 1].longitude,
      );
    }
    _distanceTraveled = "${(totalDistance / 1000).toStringAsFixed(1)} Km";
    double maxSpeed = 0;
    double totalSpeed = 0;
    int speedPointsCount = 0;
    for (var point in _historyPoints) {
      if (point.speed > maxSpeed) maxSpeed = point.speed;
      if (point.speed > 0) {
        totalSpeed += point.speed;
        speedPointsCount++;
      }
    }
    _maxSpeed = "${maxSpeed.toStringAsFixed(0)} km/h";
    _averageSpeed = speedPointsCount > 0
        ? "${(totalSpeed / speedPointsCount).toStringAsFixed(0)} km/h"
        : "0 km/h";
    final duration = _historyPoints.last.timestamp!
        .difference(_historyPoints.first.timestamp!);
    _totalTime = duration.toString().split('.').first.padLeft(8, "0");
    setState(() {});
  }

  void _resetMetrics() {
    setState(() {
      _distanceTraveled = "0 Km";
      _averageSpeed = "0 km/h";
      _maxSpeed = "0 km/h";
      _totalTime = "00:00:00";
    });
  }

  Future<BitmapDescriptor> _getMarkerIconFromAsset(String assetPath,
      {int width = 120}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final Uint8List? resizedBytes =
        (await fi.image.toByteData(format: ui.ImageByteFormat.png))
            ?.buffer
            .asUint8List();
    return BitmapDescriptor.fromBytes(resizedBytes!);
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) =>
          DatePickerBottomSheet(initialDate: _selectedDate),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
      _fetchHistory();
    }
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('No se encontró el RepaintBoundary');
      }
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturando widget: $e');
      return null;
    }
  }

  Future<void> _generatePdfReport() async {
    try {
      final dashboardImage = await _captureWidget(_dashboardKey);
      Uint8List? mapImage;
      if (Platform.isIOS) {
        final GoogleMapController mapController = await _mapController.future;
        mapImage = await mapController.takeSnapshot();
      } else {
        mapImage = await _captureWidget(_repaintBoundaryKey);
      }
      setState(() {
        _isGeneratingPdf = true;
      });
      _animationController.repeat();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando reporte...')),
      );
      if (mapImage == null || dashboardImage == null) {
        throw Exception('Error al capturar los componentes');
      }
      final logo = await rootBundle.load('assets/images/fondoapp.jpg');
      final logoImage = pw.MemoryImage(logo.buffer.asUint8List());
      final pdf = pw.Document();
      final distanceRow = await _buildEnhancedMetricRow(
          'Distancia Recorrida', _distanceTraveled, 'coche.png');
      final speedRow = await _buildEnhancedMetricRow(
          'Velocidad Promedio', _averageSpeed, 'speed.png');
      final maxSpeedRow = await _buildEnhancedMetricRow(
          'Velocidad Máxima', _maxSpeed, 'warning.png');
      final timeRow = await _buildEnhancedMetricRow(
          'Tiempo Total', _totalTime, 'timer.png');
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, height: 50),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Reporte de Auditoría',
                            style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900)),
                        pw.Text(widget.plate,
                            style: pw.TextStyle(
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Rango: $_selectedRange',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(
                      height: 500,
                      width: 400,
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.grey200, width: 1),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: mapImage != null
                          ? pw.Image(pw.MemoryImage(mapImage))
                          : pw.Center(
                              child: pw.Text('No se pudo cargar el mapa')),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],
            );
          },
        ),
      );
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text('Métricas del Viaje',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.SizedBox(
                  width: 300,
                  child: pw.Image(pw.MemoryImage(dashboardImage)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Detalles',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                distanceRow,
                speedRow,
                maxSpeedRow,
                timeRow,
              ],
            );
          },
        ),
      );
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_${widget.plate}.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte generado exitosamente')),
        );
      }
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error generando PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  Future<pw.Widget> _buildEnhancedMetricRow(
      String label, String value, String iconAsset) async {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        children: [
          pw.Container(
            width: 30,
            height: 30,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: await _loadIcon(iconAsset, size: 16),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label,
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Widget> _loadIcon(String assetName, {double size = 24}) async {
    final ByteData data =
        await rootBundle.load('assets/images/icons/$assetName');
    return pw.Image(
      pw.MemoryImage(data.buffer.asUint8List()),
      width: size,
      height: size,
    );
  }

  pw.Widget _buildPdfMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          pw.Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: _buildBackButton(context),
        title: Text(widget.plate,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                  target: LatLng(-33.045, -71.619), zoom: 13.0),
              polylines: _polylines,
              markers: _markers,
              myLocationButtonEnabled: false,
              padding: _mapPadding,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
            ),
            if (!_isLoading && _historyPoints.isEmpty && _errorMessage == null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(
                    child: Text(
                      'No hay datos de ruta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_isLoading && !_isFullscreen)
              DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return RepaintBoundary(
                    key: _dashboardKey,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20.0)),
                        boxShadow: [
                          BoxShadow(blurRadius: 10, color: Colors.black12)
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
                        children: [
                          _buildDriverInfo(),
                          const SizedBox(height: 16),
                          _buildDatePicker(context),
                          const SizedBox(height: 12),
                          _buildRangeDropdown(),
                          const SizedBox(height: 20),
                          _buildMetricsRow(),
                          const SizedBox(height: 16),
                          if (_errorMessage != null)
                            Center(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(color: Colors.red))),
                          if (!_isLoading &&
                              _historyPoints.isEmpty &&
                              _errorMessage == null)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                  'No se encontraron recorridos para la fecha y rango seleccionados.'),
                            )),
                          _buildDownloadButton(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            _buildFullscreenButton(),
            if (_isLoading || _isGeneratingPdf)
              Positioned.fill(
                child: AnimatedTruckProgress(animation: _animationController),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenButton() {
    return Positioned(
      top: 20.0,
      right: 16.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: IconButton(
          icon: Image.asset(
            _isFullscreen
                ? 'assets/images/fullscreen_off.png'
                : 'assets/images/fullscreen.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            setState(() {
              _isFullscreen = !_isFullscreen;
            });
          },
          tooltip: _isFullscreen
              ? 'Salir de pantalla completa'
              : 'Pantalla completa',
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    final bool isButtonEnabled =
        !_isLoading && !_isGeneratingPdf && _historyPoints.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isButtonEnabled ? _generatePdfReport : null,
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text('Descargar Reporte',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isButtonEnabled ? AppColors.primary : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMetricCard(_distanceTraveled, 'Distancia recorrida'),
          _buildMetricCard(_averageSpeed, 'Velocidad promedio'),
          _buildMetricCard(_maxSpeed, 'Velocidad máxima'),
          _buildMetricCard(_totalTime, 'Tiempo total'),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCustomDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.grey),
            const SizedBox(width: 12),
            const Text('Cuándo'),
            const Spacer(),
            Text(
              DateFormat('dd / MM / yy', 'es_ES').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeDropdown() {
    return Column(
      children: [
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () =>
                setState(() => _isRangeDropdownOpen = !_isRangeDropdownOpen),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text('Seleccione rango'),
                  const Spacer(),
                  Text(_selectedRange,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(_isRangeDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: _isRangeDropdownOpen,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: _timeRanges.map((range) {
                bool isSelected = range == _selectedRange;
                return Material(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRange = range;
                        _isRangeDropdownOpen = false;
                      });
                      _fetchHistory();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(range,
                            style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Image.asset('assets/images/backbtn.png', width: 40, height: 40),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildDriverInfo() {
    final String driverName = _cachedUser?.fullName ?? 'Cargando...';
    final String? imageUrl = _cachedUser?.userImage;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
              ? NetworkImage(imageUrl)
              : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        const Text('Conductor',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(driverName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return SizedBox(
      width: 130,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.grey, width: 1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
