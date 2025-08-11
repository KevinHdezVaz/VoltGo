class PasswordResetRequest {
  final String email;

  PasswordResetRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class MfaVerification {
  final String email;
  final String code;

  MfaVerification({required this.email, required this.code});

  Map<String, dynamic> toJson() => {'email': email, 'mfa': code};
}

class NewPasswordData {
  final String email;
  final String newPass;
  final String newPassCheck;

  NewPasswordData({
    required this.email,
    required this.newPass,
    required this.newPassCheck,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'new_pass': newPass,
        'new_pass_check': newPassCheck,
      };
}

class PasswordResetResponse {
  final bool success;
  final String? message;

  PasswordResetResponse({required this.success, this.message});
}
