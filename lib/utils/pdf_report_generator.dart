import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Necesario para cargar assets
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:Voltgo_app/data/models/BarChartDataModel.dart';
import 'package:Voltgo_app/data/models/dashboard/DashboardDetailModel.dart';
import 'package:Voltgo_app/data/models/vehicles/VehicleHistoryPoint.dart'; // Asegúrate de que esta importación sea correcta
import 'package:image/image.dart' as img; // Importa el paquete image

class PdfReportGenerator {
  static Future<void> generateFullScreenReport({
    required Uint8List screenImage,
    required String plate,
  }) async {
    try {
      final pdf = pw.Document();
      final pdfTheme = await _getPdfTheme();
      final image = img.decodeImage(screenImage);
      if (image == null)
        throw Exception("No se pudo decodificar la imagen de la pantalla.");

      final resizedImage = img.copyResize(image,
          width: 1000, interpolation: img.Interpolation.linear);
      final pdfImage =
          pw.MemoryImage(Uint8List.fromList(img.encodePng(resizedImage)));

      pdf.addPage(
        pw.Page(
          theme: pdfTheme,
          pageFormat: PdfPageFormat
              .a4.landscape, // Usamos formato horizontal para que quepa mejor
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Reporte de Auditoría - Patente: $plate',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(DateTime.now())}',
                    style: const pw.TextStyle(color: PdfColors.grey)),
                pw.SizedBox(height: 20),
                pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_auditoria_$plate.pdf');
      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("Error al generar el reporte de pantalla completa: $e");
      rethrow; // Relanzamos el error para que sea capturado en la UI
    }
  }

  static Future<void> generateVisualReport({
    required Uint8List mapImage,
    required Uint8List panelImage,
    required String plate,
  }) async {
    try {
      final pdf = pw.Document();
      final pdfTheme = await _getPdfTheme();
      Uint8List resizeImage(Uint8List input, {int maxWidth = 800}) {
        final image = img.decodeImage(input);
        if (image == null) {
          debugPrint("Error: No se pudo decodificar la imagen");
          return input; // Devuelve la imagen original si falla
        }
        final resized = img.copyResize(image,
            width: maxWidth, interpolation: img.Interpolation.linear);
        return Uint8List.fromList(img.encodePng(resized));
      }

      final resizedMapImage = resizeImage(mapImage, maxWidth: 800);
      final resizedPanelImage = resizeImage(panelImage, maxWidth: 800);

      final mapPdfImage = pw.MemoryImage(resizedMapImage);
      final panelPdfImage = pw.MemoryImage(resizedPanelImage);

      print('--- INICIO DIAGNÓSTICO PDF ---');
      print(
          'Bytes de imagen del mapa (redimensionada): ${resizedMapImage.lengthInBytes}');
      print(
          'Bytes de imagen del panel (redimensionada): ${resizedPanelImage.lengthInBytes}');
      print('Creando PDF para patente: $plate');

      pdf.addPage(
        pw.Page(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'Reporte de Auditoría - Patente: $plate',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Image(mapPdfImage, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 10),
                pw.Image(panelPdfImage, fit: pw.BoxFit.contain),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_$plate.pdf');
      final pdfBytes = await pdf.save();
      print('PDF generado, tamaño: ${pdfBytes.lengthInBytes} bytes');
      await file.writeAsBytes(pdfBytes);

      final result = await OpenFile.open(file.path);
      print(
          'Resultado de abrir PDF: ${result.type}, mensaje: ${result.message}');
    } catch (e, stackTrace) {
      debugPrint("Error al generar o abrir el PDF: $e");
      debugPrint("StackTrace: $stackTrace");
      throw e;
    }
  }

  static Future<pw.ThemeData> _getPdfTheme() async {
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);
    return pw.ThemeData.withFont(
      base: ttf,
      bold: boldTtf,
    );
  }

  static Future<void> generateBarChartReport({
    required BuildContext context,
    required String reportTitle,
    required DashboardDetailData reportData,
    required Color Function(String) colorResolver,
  }) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando PDF...')),
    );

    try {
      final pdf = pw.Document();
      final pdfTheme = await _getPdfTheme();
      final logoBytes = await rootBundle.load('assets/images/fondoapp.jpg');

      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final chartData = reportData.breakdown.entries.map((entry) {
        return BarChartDataModel(
          label: entry.key.replaceAll('_', ' ').replaceAll(' > 1 hora', ''),
          value: entry.value.toDouble(),
          color: colorResolver(entry.key),
        );
      }).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final maxValue = reportData.breakdown.values.isEmpty
          ? 1.0
          : reportData.breakdown.values.reduce(max).toDouble();

      pdf.addPage(
        pw.Page(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(logoImage, reportTitle),
                pw.SizedBox(height: 15),
                _buildBarChartContent(
                  chartData: chartData,
                  maxValue: maxValue,
                  totalValue: reportData.total.toString(),
                ),
                pw.SizedBox(height: 20),
                _buildPdfFooter(),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Reporte_${reportTitle.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error en generateBarChartReport: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al crear PDF: $e')));
      }
    }
  }

  static pw.Widget _buildPdfHeader(pw.ImageProvider logoImage, String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(logoImage, height: 40),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Reporte de Auditoría',
                style:
                    const pw.TextStyle(fontSize: 16, color: PdfColors.blue800)),
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBarChartContent({
    required List<BarChartDataModel> chartData,
    required double maxValue,
    required String totalValue,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy', 'es_ES').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
                'Generado a las: ${DateFormat('HH:mm', 'es_ES').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Divider(height: 20),
        pw.ListView(
          children: chartData.map((item) {
            final barWidthFraction =
                maxValue > 0 ? (item.value / maxValue) : 0.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                      width: 100,
                      child: pw.Text(item.label,
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.ClipRRect(
                      horizontalRadius: 3,
                      verticalRadius: 3,
                      child: pw.LinearProgressIndicator(
                        value: barWidthFraction,
                        backgroundColor: PdfColors.grey200,
                        valueColor: PdfColor.fromInt(item.color.value),
                        minHeight: 14,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(item.value.toInt().toString(),
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        ),
        pw.Divider(height: 20),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text('Total: $totalValue',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800)),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text('Voltgo',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ],
    );
  }

  static Future<void> generateAuditReport({
    required BuildContext context,
    required String plate,
    required DateTime selectedDate,
    required String selectedRange,
    required String distance,
    required String avgSpeed,
    required String maxSpeed,
    required String totalTime,
  }) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando Reporte de Recorrido...')),
    );

    try {
      final pdf = pw.Document();
      final pdfTheme = await _getPdfTheme();

      pdf.addPage(
        pw.Page(
          theme: pdfTheme, // <-- APLICAMOS EL TEMA A LA PÁGINA
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return _buildAuditPdfPage(
              context: pdfContext,
              plate: plate,
              selectedDate: selectedDate,
              selectedRange: selectedRange,
              distance: distance,
              avgSpeed: avgSpeed,
              maxSpeed: maxSpeed,
              totalTime: totalTime,
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Reporte_Recorrido_${plate}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      final result = await OpenFile.open(file.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.type == ResultType.done
                ? 'Abriendo PDF...'
                : 'No se pudo abrir el PDF: ${result.message}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al generar o abrir el PDF de auditoría: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: ${e.toString()}')),
        );
      }
    }
  }

  static pw.Widget _buildBarChartPdfPage({
    required pw.Context context,
    required String title,
    required List<BarChartDataModel> chartData,
    required double maxValue,
    required String totalValue,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(
            DateFormat('dd/MM/yyyy - HH:mm', 'es_ES').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.Divider()),
        pw.ListView(
          children: chartData.map((item) {
            final barWidthFraction =
                maxValue > 0 ? (item.value / maxValue) : 0.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                      width: 90,
                      child: pw.Text(item.label,
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.ClipRRect(
                      horizontalRadius: 3,
                      verticalRadius: 3,
                      child: pw.LinearProgressIndicator(
                        value: barWidthFraction,
                        backgroundColor: PdfColors.grey200,
                        valueColor: PdfColor.fromInt(item.color.value),
                        minHeight: 14,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.SizedBox(
                      width: 30,
                      child: pw.Text(item.value.toInt().toString(),
                          style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
            );
          }).toList(),
        ),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.Divider()),
        pw.Center(
            child: pw.Text('Total: $totalValue',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold))),
      ],
    );
  }

  static pw.Widget _buildAuditPdfPage({
    required pw.Context context,
    required String plate,
    required DateTime selectedDate,
    required String selectedRange,
    required String distance,
    required String avgSpeed,
    required String maxSpeed,
    required String totalTime,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Reporte de Recorrido',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text(plate,
              style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
        ]),
        pw.SizedBox(height: 10),
        pw.Text(
            'Fecha del reporte: ${DateFormat('dd/MM/yyyy - HH:mm', 'es_ES').format(DateTime.now())}'),
        pw.Text(
            'Período consultado: ${DateFormat('dd/MM/yyyy', 'es_ES').format(selectedDate)} (Últimas $selectedRange)'),
        pw.Divider(height: 30),
        pw.Text('Resumen de Métricas',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 15),
        pw.GridView(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          children: [
            _buildMetricPdfCard('Distancia Recorrida', distance),
            _buildMetricPdfCard('Velocidad Máxima', maxSpeed),
            _buildMetricPdfCard('Tiempo Total en Ruta', totalTime),
            _buildMetricPdfCard('Velocidad Promedio', avgSpeed),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Paragraph(
            text:
                'Este reporte resume la actividad del vehículo en el período seleccionado. Para un análisis detallado de los eventos y paradas, por favor consulte la plataforma web.',
            style: pw.TextStyle(
                color: PdfColors.grey, fontStyle: pw.FontStyle.italic)),
      ],
    );
  }

  static pw.Widget _buildMetricPdfCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
