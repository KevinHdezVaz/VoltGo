import 'dart:convert';
import 'package:Voltgo_User/data/models/User/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_User/data/models/LOGIN/ResetPasswordModel.dart';
import 'package:Voltgo_User/data/models/LOGIN/login_request_model.dart';
import 'package:Voltgo_User/data/models/LOGIN/logout_response.dart'; // Asegúrate que esta es la ruta correcta a tu nuevo modelo
import 'package:Voltgo_User/data/services/UserCacheService.dart';
import 'package:Voltgo_User/utils/TokenStorage.dart';
import 'package:Voltgo_User/utils/constants.dart';

class AuthService {
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/login');
    final body = LoginRequest(
      email: email,
      password: password,
    ).toJson();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        if (loginResponse.token.isNotEmpty) {
          await TokenStorage.saveToken(loginResponse.token);
        }
        return loginResponse;
      } else {
        String errorMessage = 'Credenciales inválidas.';
        try {
          errorMessage = jsonDecode(response.body)['message'] ?? errorMessage;
        } catch (e) {/* Ignora errores de parseo */}
        return LoginResponse(token: '', error: errorMessage);
      }
    } catch (e) {
      return LoginResponse(token: '', error: 'Error de conexión: $e');
    }
  }

  static Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String userType,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/register');
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'user_type': userType,
      if (phone != null) 'phone': phone,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        // Esta línea ahora procesará el 'user' gracias al factory actualizado
        return RegisterResponse.fromJson(jsonDecode(response.body));
      } else {
        String errorMessage = 'Error en el registro.';
        try {
          final jsonResponse = jsonDecode(response.body);
          errorMessage = jsonResponse['errors']?.values?.first[0] ??
              jsonResponse['message'] ??
              errorMessage;
        } catch (e) {/* Ignora errores de parseo */}
        return RegisterResponse(success: false, error: errorMessage);
      }
    } catch (e) {
      return RegisterResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  static Future<UserModel?> fetchUserProfile() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      print('No token found, cannot fetch profile.');
      return null;
    }

    final url = Uri.parse('${Constants.baseUrl}/user/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // La API devuelve el objeto de usuario directamente
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        // Si el token es inválido o hay otro error, devolvemos null
        print('Failed to fetch profile: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching profile: $e');
      return null;
    }
  }

// En tu archivo data/services/auth_api_service.dart

  static Future<void> logout() async {
    // Changed to Future<void> for simplicity
    final token = await TokenStorage.getToken();
    if (token == null) {
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
      return;
    }

    final url = Uri.parse('${Constants.baseUrl}/logout');
    print('URL de logout: $url');

    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // <-- La cabecera clave
          'Authorization': 'Bearer $token', // <-- Asegúrate de que sea 'Bearer'
        },
      );
    } catch (e) {
      print('Exception during logout request: $e');
    } finally {
      // Limpia los datos locales SIN IMPORTAR la respuesta del servidor
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
      print('Local user data and token cleared.');
    }
  }

  static Future<String?> getStoredToken() async {
    final token = await TokenStorage.getToken();
    print('Obteniendo token almacenado: $token');
    return token;
  }

  static Future<bool> isLoggedIn() async {
    return await TokenStorage.hasToken();
  }

  static Future<PasswordResetResponse> requestPasswordReset(
      String email) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    print('Solicitando reset de contraseña - URL: $url');

    try {
      final response = await http.get(url);
      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return PasswordResetResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Código enviado correctamente',
          );
        } catch (e) {
          print('Error al parsear JSON: $e');
          return PasswordResetResponse(
            success: false,
            message: 'Error al procesar la respuesta del servidor',
          );
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Error desconocido';
        print('Error en reset: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en requestPasswordReset: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  static Future<PasswordResetResponse> verifyMfaCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    final body = MfaVerification(email: email, code: code).toJson();
    print('Validando MFA - URL: $url');
    print('Cuerpo de la solicitud: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Validación MFA exitosa');
          return PasswordResetResponse(
            success: true,
            message:
                jsonResponse['message'] ?? 'Código verificado correctamente',
          );
        } catch (e) {
          print('Error al parsear JSON: $e');
          return PasswordResetResponse(
            success: false,
            message: 'Error al procesar la respuesta del servidor',
          );
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Código inválido';
        print('Error en MFA: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en verifyMfaCode: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  static Future<PasswordResetResponse> setNewPassword({
    required String email,
    required String newPass,
    required String newPassCheck,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    final body = NewPasswordData(
      email: email,
      newPass: newPass,
      newPassCheck: newPassCheck,
    ).toJson();
    print('Cambiando contraseña - URL: $url');
    print('Cuerpo de la solicitud: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Cambio de contraseña exitoso');
        return PasswordResetResponse(
          success: true,
          message:
              jsonResponse['message'] ?? 'Contraseña cambiada correctamente',
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        final errorMsg =
            jsonResponse['message'] ?? 'Error al cambiar contraseña';
        print('Error en setNewPassword: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en setNewPassword: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
}

class RegisterResponse {
  final bool success;
  final String? token;
  final UserModel? user; // Ahora contiene el objeto UserModel
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
