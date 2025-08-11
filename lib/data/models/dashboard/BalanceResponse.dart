class BalanceResponse {
  final List<BalanceData> data;

  BalanceResponse({required this.data});

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    return BalanceResponse(
      data: (json['data'] as List)
          .map((item) => BalanceData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class BalanceData {
  final int id;
  final String balanceTitle;
  final List<BalanceDetail> details;

  BalanceData({
    required this.id,
    required this.balanceTitle,
    required this.details,
  });

  factory BalanceData.fromJson(Map<String, dynamic> json) {
    return BalanceData(
      id: json['id'],
      balanceTitle: json['balance_title'],
      details: (json['details'] as List)
          .map((item) => BalanceDetail.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance_title': balanceTitle,
      'details': details.map((item) => item.toJson()).toList(),
    };
  }
}

class BalanceDetail {
  final String fieldName;
  final String value;
  final String? valueType;

  BalanceDetail({
    required this.fieldName,
    required this.value,
    this.valueType,
  });

  factory BalanceDetail.fromJson(Map<String, dynamic> json) {
    return BalanceDetail(
      fieldName: json['field_name'],
      value: json['value'],
      valueType: json['value_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_name': fieldName,
      'value': value,
      'value_type': valueType,
    };
  }
}