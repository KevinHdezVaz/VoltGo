import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Voltgo_app/data/models/BarChartDataModel.dart';
import 'package:Voltgo_app/data/models/dashboard/DashboardDetailModel.dart';
import 'package:Voltgo_app/data/services/DashboardService.dart';
import 'package:Voltgo_app/ui/MenuPage/auditoria/CustomDatePickerDialog.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/pdf_report_generator.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';

class DataVisualizationDetail extends StatefulWidget {
  final String title;
  final String dataType;

  const DataVisualizationDetail({
    Key? key,
    required this.title,
    required this.dataType,
  }) : super(key: key);

  @override
  _DataVisualizationDetailState createState() =>
      _DataVisualizationDetailState();
}

class _DataVisualizationDetailState extends State<DataVisualizationDetail>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  Future<DashboardDetailData>? _detailDataFuture;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
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

  void _fetchDetails() {
    setState(() {
      _detailDataFuture = DashboardService.getDashboardDetailData(
        rangeInHours: 24,
        dataType: widget.dataType,
      );
    });
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DatePickerBottomSheet(initialDate: _selectedDate);
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _fetchDetails();
      });
    }
  }

  Future<void> _generatePdfReport(DashboardDetailData data) async {
    setState(() {
      _isLoading = true;
    });
    _animationController.repeat();

    try {
      await PdfReportGenerator.generateBarChartReport(
        context: context,
        reportTitle: widget.title,
        reportData: data,
        colorResolver: _getColorForDataType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _buildBackButton(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            Text(DateFormat('EEE, d MMM', 'es_ES').format(_selectedDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<DashboardDetailData>(
            future: _detailDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.hasData) {
                return _buildContent(snapshot.data!);
              }
              return const Center(child: Text("No hay datos disponibles."));
            },
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

  Widget _buildContent(DashboardDetailData detailData) {
    final chartData = detailData.breakdown.entries.map((entry) {
      return BarChartDataModel(
          label: entry.key.replaceAll('_', ' ').replaceAll(' > 1 hora', ''),
          value: entry.value.toDouble(),
          color: _getColorForDataType(entry.key));
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = detailData.breakdown.values.isEmpty
        ? 1.0
        : detailData.breakdown.values.reduce(max).toDouble() * 1.1;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDatePicker(context),
                const SizedBox(height: 16),
                _buildChartCard(
                    chartData, maxValue, detailData.total.toString()),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildDownloadButton(detailData),
      ],
    );
  }

  Color _getColorForDataType(String key) {
    switch (widget.dataType) {
      case 'd_vehicles_status':
        switch (key) {
          case 'En ruta':
            return Colors.blue.shade400;
          case 'Sin Transmision':
            return Colors.orange.shade400;
          case 'Ralentí':
            return Colors.lightBlue;
          case 'Apagado_>_1_hora':
            return Colors.deepOrange;
          default:
            return Colors.grey;
        }
      case 'd_alert_plan':
        return Colors.primaries[key.hashCode % Colors.primaries.length];
      case 'd_vehicles_type':
        return Colors.primaries[key.hashCode % Colors.primaries.length];
      default:
        return Colors.primaries[key.hashCode % Colors.primaries.length];
    }
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCustomDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey),
            boxShadow: [
              BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.05))
            ]),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Cuándo', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(DateFormat('dd / MM / yy', 'es_ES').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
      List<BarChartDataModel> data, double maxValue, String totalValue) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHorizontalBarChart(data, maxValue),
            const SizedBox(height: 16),
            const Divider(),
            _buildFooter(totalValue),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBarChart(
      List<BarChartDataModel> data, double maxValue) {
    if (data.isEmpty) {
      return const SizedBox(
          height: 100,
          child: Center(child: Text("No hay datos para este período.")));
    }
    return Column(
      children: [
        ...data.map((item) => _buildBarRow(item, maxValue)).toList(),
        const SizedBox(height: 8),
        _buildXAxis(maxValue),
      ],
    );
  }

  Widget _buildBarRow(BarChartDataModel item, double maxValue) {
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

  Widget _buildXAxis(double maxValue) {
    return Padding(
      padding: const EdgeInsets.only(left: 100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const int numberOfLabels = 5;
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

  Widget _buildFooter(String totalValue) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(totalValue,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildDownloadButton(DashboardDetailData data) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _generatePdfReport(data),
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text('Descargar',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLoading ? Colors.grey : AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
      ),
    );
  }
}
