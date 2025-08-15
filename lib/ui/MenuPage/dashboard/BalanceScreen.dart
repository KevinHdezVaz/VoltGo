import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/models/dashboard/BalanceResponse.dart';
import 'package:Voltgo_app/data/services/DashboardService.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({Key? key}) : super(key: key);

  @override
  _BalanceScreenState createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with SingleTickerProviderStateMixin {
  late Future<BalanceResponse> _balanceFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _balanceFuture = DashboardService.getUserBalance();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<BalanceResponse>(
        future: _balanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _animationController.repeat();
            return Center(
              child: AnimatedTruckProgress(
                animation: _animationController,
              ),
            );
          }

          _animationController.stop();

          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final balanceData = snapshot.data!;
            return _buildContent(balanceData);
          }
          return const Center(child: Text('No hay datos para mostrar.'));
        },
      ),
    );
  }

  Widget _buildContent(BalanceResponse balanceData) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: balanceData.data.map((balanceItem) {
        final values = balanceItem.details
            .where((detail) => double.tryParse(detail.value) != null)
            .map((detail) => double.parse(detail.value))
            .toList();

        final maxValue =
            values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1.0;
        final progressValue = maxValue > 0
            ? (values.isNotEmpty ? values[0] / maxValue : 0.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: MetricCard(
            title: balanceItem.balanceTitle,
            progressValue: progressValue,
            progressText:
                values.isNotEmpty ? values[0].toStringAsFixed(2) : '0.00',
            progressColor: _getColorForBalanceItem(balanceItem.id),
            legendItems: balanceItem.details.map((detail) {
              return LegendItem(
                text: detail.fieldName,
                value: '${detail.value} ${detail.valueType ?? ''}',
                color: _getColorForDetail(detail.fieldName),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForBalanceItem(int id) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[id % colors.length];
  }

  Color _getColorForDetail(String fieldName) {
    switch (fieldName) {
      case 'Total consumidos':
      case 'Planificados':
      case 'Promedio':
      case 'Optimo cliente':
      case 'Reportando':
        return Colors.blue;
      case 'En ralentí':
      case 'Realizados':
      case 'Actual':
      case 'Sin reportar':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final double progressValue;
  final String progressText;
  final Color progressColor;
  final List<LegendItem> legendItems;

  const MetricCard({
    Key? key,
    required this.title,
    required this.progressValue,
    required this.progressText,
    required this.progressColor,
    required this.legendItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      color: Colors.white,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                CircularMetricIndicator(
                  value: progressValue,
                  text: progressText,
                  color: progressColor,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legendItems.isEmpty
                        ? [const Text('No hay datos para esta categoría.')]
                        : legendItems
                            .map((item) => _buildLegendRow(item))
                            .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(LegendItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(item.text, style: TextStyle(color: Colors.grey[700]))),
          Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CircularMetricIndicator extends StatelessWidget {
  final double value;
  final String text;
  final Color color;

  const CircularMetricIndicator({
    Key? key,
    required this.value,
    required this.text,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Text(text,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ),
        ],
      ),
    );
  }
}

class LegendItem {
  final String text;
  final String value;
  final Color color;

  const LegendItem({
    required this.text,
    required this.value,
    required this.color,
  });
}
