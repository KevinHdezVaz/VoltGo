import 'package:Voltgo_User/data/models/User/user_model.dart';

class LoginRequest {
  final String email; // Debe llamarse 'email'
  final String password;

  LoginRequest({
    required this.email, // Debe ser 'email'
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email, // La clave debe ser 'email' como un string
        'password': password,
      };
}

// En tu AuthService o donde tengas los modelos de respuesta

class RegisterResponse {
  final bool success;
  final String? token;
  final UserModel? user;
  final String? error;

  RegisterResponse({required this.success, this.token, this.user, this.error});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: true,
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

// Haz lo mismo para tu clase LoginResponse
class LoginResponse {
  final String token;
  final UserModel? user;
  final String? error;

  LoginResponse({required this.token, this.user, this.error});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      error: json['message'],
    );
  }
}
