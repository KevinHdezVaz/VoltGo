class LogoutResponse {
  final String detail;

  LogoutResponse({
    required this.detail,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      detail: json['detail'],
    );
  }
}
