import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:Voltgo_app/data/models/dashboard/BalanceResponse.dart';
import 'package:Voltgo_app/data/models/dashboard/DashboardData.dart';
import 'package:Voltgo_app/data/services/DashboardService.dart';
import 'package:Voltgo_app/ui/MenuPage/dashboard/BalanceScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/dashboard/DataVisualizationScreen.dart';

class CombinedDashboardScreen extends StatefulWidget {
  const CombinedDashboardScreen({Key? key}) : super(key: key);

  @override
  _CombinedDashboardScreenState createState() =>
      _CombinedDashboardScreenState();
}

class _CombinedDashboardScreenState extends State<CombinedDashboardScreen> {
  int _selectedTabIndex = 0;
  bool _isLoading = false; // <-- AÑADE ESTA LÍNEA
  BalanceResponse? _balanceData;
  DashboardData? _dashboardData;
  final List<String> _titles = ['Balance de Hoy', 'Dashboard'];
  final List<Widget> _tabContents = [
    const BalanceScreen(),
    const DataVisualizationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('es_MX', null);

    // Obtiene la fecha y hora actual.
    final DateTime now = DateTime.now();

    // Crea el formato deseado: Día abreviado, número de día, Mes abreviado.
    // 'es_MX' asegura que sea en español (ej: "mar." en lugar de "Tue").
    final String formattedDate = DateFormat('EEE d MMM.', 'es_MX').format(now);

    // Capitaliza la primera letra del resultado (ej: "lun" -> "Lun")
    final String displayDate = formattedDate.substring(0, 1).toUpperCase() +
        formattedDate.substring(1);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _buildBackButton(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_selectedTabIndex],
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            Text(displayDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
        // Dentro de tu método build, localiza la sección 'actions' del AppBar
        actions: [
          if (_selectedTabIndex == 0) // Muestra el botón solo en "Balance"
            // Usa una condición para mostrar el loader o el botón
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    // Llama a tu función al presionar
                    onPressed: _refreshData,
                  ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: _tabContents,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Image.asset('assets/images/backbtn.png', width: 40, height: 40),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("Iniciando actualización de datos en paralelo...");

      // Usamos Future.wait para ejecutar ambas llamadas al mismo tiempo.
      final results = await Future.wait([
        DashboardService.getUserBalance(),
        DashboardService.getDashboardData(rangeInHours: 24),
      ]);

      // Una vez que ambas llamadas terminan, actualizamos el estado con los nuevos datos.
      // Esto hará que la interfaz de usuario se redibuje con la información fresca.
      if (mounted) {
        setState(() {
          _balanceData = results[0] as BalanceResponse;
          _dashboardData = results[1] as DashboardData;
          print("Datos de UI actualizados correctamente.");
        });
      }
    } catch (e) {
      // Si cualquiera de las dos llamadas falla, el 'catch' lo manejará.
      print("Error durante la actualización: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al refrescar los datos: ${e.toString()}')),
        );
      }
    } finally {
      // Este bloque se ejecuta siempre, asegurando que el loader se oculte.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabButton(0, 'Balance de Hoy'),
            _buildTabButton(1, 'Dashboard'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String text) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.black54,
          elevation: isSelected ? 2 : 0,
          shadowColor: isSelected
              ? AppColors.primary.withOpacity(0.5)
              : Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFF00636A);
}

class MetricCard extends StatelessWidget {
  /*...*/ const MetricCard({super.key});
  @override
  Widget build(BuildContext context) => const Card();
}

class ChartCard extends StatelessWidget {
  /*...*/ const ChartCard({super.key});
  @override
  Widget build(BuildContext context) => const Card();
}

class LegendItem {
  const LegendItem(
      {required String text, required String value, required Color color});
}

class BarChartDataModel {
  const BarChartDataModel(
      {required String label, required double value, required Color color});
}
