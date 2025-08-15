import 'package:flutter/material.dart';
import 'dart:math';
import 'package:Voltgo_app/data/models/BarChartDataModel.dart';
import 'package:Voltgo_app/data/models/dashboard/DashboardData.dart';
import 'package:Voltgo_app/data/services/DashboardService.dart';
import 'package:Voltgo_app/ui/MenuPage/dashboard/DataVisualizationDetail.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class DataVisualizationScreen extends StatefulWidget {
  const DataVisualizationScreen({Key? key}) : super(key: key);

  @override
  _DataVisualizationScreenState createState() =>
      _DataVisualizationScreenState();
}

class _DataVisualizationScreenState extends State<DataVisualizationScreen> {
  late Future<DashboardData> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = DashboardService.getDashboardData(rangeInHours: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Error al cargar los datos: ${snapshot.error}"));
          }
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return _buildCharts(data);
          }
          return const Center(child: Text("No hay datos disponibles."));
        },
      ),
    );
  }

  Widget _buildCharts(DashboardData data) {
    final List<BarChartDataModel> mobilesData =
        _mapToChartData(data.vehicleTypes, AppColors.primary);
    final double maxMobileValue = _calculateMaxValue(data.vehicleTypes);

    final List<BarChartDataModel> plannedData =
        _mapToChartData(data.alertPlan, Colors.orange.shade600);
    final double maxAlertValue = _calculateMaxValue(data.alertPlan);

    final List<BarChartDataModel> fleetStatusData =
        _mapToChartData(data.vehicleStatus, Colors.cyan.shade400);
    final double maxStatusValue = _calculateMaxValue(data.vehicleStatus);

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ChartCard(
          title: 'Móviles por Tipo',
          data: mobilesData,
          totalLabel: 'Móviles totales',
          totalValue: data.totalVehicles.toString(),
          maxValue: maxMobileValue,
          dataType: 'd_vehicles_type', // Se pasa el dataType correcto
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'Alertas del Plan (24h)',
          data: plannedData,
          totalLabel: 'Alertas totales',
          totalValue: data.totalAlerts.toString(),
          maxValue: maxAlertValue,
          dataType: 'd_alert_plan', // Se pasa el dataType correcto
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: 'Estado de la Flota',
          data: fleetStatusData,
          totalLabel: 'Total en línea',
          totalValue: data.totalOnline.toString(),
          maxValue: maxStatusValue,
          dataType: 'd_vehicles_status', // Se pasa el dataType correcto
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  List<BarChartDataModel> _mapToChartData(
      Map<String, int> sourceMap, Color defaultColor) {
    final sortedEntries = sourceMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      return BarChartDataModel(
        label: entry.key.replaceAll('_', ' '),
        value: entry.value.toDouble(),
        color: _getColorForLabel(entry.key, defaultColor),
      );
    }).toList();
  }

  double _calculateMaxValue(Map<String, int> sourceMap) {
    if (sourceMap.isEmpty || sourceMap.values.every((v) => v == 0)) return 1.0;
    final maxValue = sourceMap.values.reduce(max).toDouble();
    return maxValue * 1.1;
  }

  Color _getColorForLabel(String label, Color defaultColor) {
    if (label == 'En ruta') return AppColors.primary;
    if (label == 'Sin Transmision') return Colors.orange;
    return defaultColor;
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final List<BarChartDataModel> data;
  final String totalLabel;
  final String totalValue;
  final double maxValue;
  final String dataType; // CORRECCIÓN: Se añade la propiedad que faltaba

  const ChartCard({
    Key? key,
    required this.title,
    required this.data,
    required this.totalLabel,
    required this.totalValue,
    required this.maxValue,
    required this.dataType, // CORRECCIÓN: Se añade al constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DataVisualizationDetail(
              title: title,
              dataType: dataType,
            ),
          ),
        );
      },
      child: Card(
        elevation: 10,
        color: Colors.white, // Fondo blanco explícito

        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildHorizontalBarChart(),
              const SizedBox(height: 16),
              const Divider(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.grey),
            onPressed: () {}),
      ],
    );
  }

  Widget _buildHorizontalBarChart() {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No hay datos para mostrar en el gráfico.")),
      );
    }
    return Column(
      children: [
        ...data.map((item) => _buildBarRow(item)).toList(),
        const SizedBox(height: 8),
        _buildXAxis(),
      ],
    );
  }

  Widget _buildBarRow(BarChartDataModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              item.label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = maxValue > 0
                        ? (item.value / maxValue) * constraints.maxWidth
                        : 0;
                    return Container(
                      height: 20,
                      width:
                          barWidth.clamp(0.0, constraints.maxWidth).toDouble(),
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXAxis() {
    return Padding(
      padding: const EdgeInsets.only(left: 100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int numberOfLabels = 5;
          if (constraints.maxWidth < 150) numberOfLabels = 3;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(numberOfLabels, (index) {
              int labelValue =
                  (maxValue / (numberOfLabels - 1) * index).round();
              return Text(
                labelValue.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$totalLabel: $totalValue',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DataVisualizationDetail(
                    title: title,
                    dataType: dataType,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Text('Ver más', style: TextStyle(color: AppColors.primary)),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
