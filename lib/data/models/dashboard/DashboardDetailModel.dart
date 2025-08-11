import 'dart:convert';

class DashboardDetailData {
  final Map<String, int> breakdown;
  final int total;

  DashboardDetailData({
    required this.breakdown,
    required this.total,
  });

  factory DashboardDetailData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final breakdownKey = data.keys.firstWhere(
      (key) => data[key] is Map,
      orElse: () => 'unknown',
    );

    final breakdownMap = data[breakdownKey] as Map<String, dynamic>? ?? {};
    final totalKey = data.keys.firstWhere(
      (key) => key.startsWith('total_'),
      orElse: () => 'unknown',
    );

    return DashboardDetailData(
      breakdown: breakdownMap
          .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      total: data[totalKey] as int? ?? 0,
    );
  }
}
