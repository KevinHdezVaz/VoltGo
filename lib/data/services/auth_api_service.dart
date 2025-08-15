import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/data/models/LOGIN/ResetPasswordModel.dart';
import 'package:Voltgo_app/data/models/LOGIN/login_request_model.dart';
import 'package:Voltgo_app/data/models/LOGIN/logout_response.dart'; // Asegúrate que esta es la ruta correcta a tu nuevo modelo
import 'package:Voltgo_app/data/services/UserCacheService.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';

class AuthService {
  static Future<LoginResponse> login({
    required String username,
    required String password,
    required String company,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user-login');
    final body = LoginRequest(
      username: username,
      password: password,
      company: company,
    ).toJson();

    print('Intentando login - URL: $url');
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
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        print('Login exitoso - Token: ${loginResponse.token}');

        if (loginResponse.token.isNotEmpty) {
          await TokenStorage.saveToken(loginResponse.token);
          print('Token guardado exitosamente en TokenStorage');
        }

        return loginResponse;
      } else {
        final errorMsg = 'Error: ${response.statusCode} - ${response.body}';
        print('Error en login: $errorMsg');
        return LoginResponse(
          token: '',
          error: errorMsg,
        );
      }
    } catch (e) {
      print('Excepción en login: $e');
      return LoginResponse(
        token: '',
        error: 'Exception: $e',
      );
    }
  }

  static Future<LogoutResponse> logout() async {
    final token = await TokenStorage.getToken();
    print('Intentando logout - Token obtenido: $token');

    // Si no hay token, no hay nada que hacer en el servidor, pero sí podemos limpiar la caché local
    if (token == null) {
      print('No hay token almacenado. Limpiando caché local por si acaso.');
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData(); // <--- AÑADIDO AQUÍ
      return LogoutResponse(
        detail: 'No hay token almacenado',
      );
    }

    final url = Uri.parse('${Constants.baseUrl}/user-logout');
    print('URL de logout: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print('Respuesta recibida - Status Code: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      // Limpia los datos locales SIN IMPORTAR la respuesta del servidor
      await TokenStorage.deleteToken();
      print('Token eliminado de TokenStorage');
      await UserCacheService.clearUserData(); // <--- AÑADIDO AQUÍ
      print('Datos de usuario eliminados de UserCacheService');

      if (response.statusCode == 200) {
        return LogoutResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorMsg = 'Error: ${response.statusCode} - ${response.body}';
        print('Error en logout: $errorMsg');
        return LogoutResponse(
          detail: errorMsg,
        );
      }
    } catch (e) {
      // Si hay una excepción (ej. sin internet), también limpiamos los datos locales
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData(); // <--- AÑADIDO AQUÍ TAMBIÉN
      print('Excepción en logout: $e. Limpiando datos locales.');
      return LogoutResponse(
        detail: 'Exception: $e',
      );
    }
  }

  static Future<String?> getStoredToken() async {
    final token = await TokenStorage.getToken();
    print('Obteniendo token almacenado: $token');
    return token;
  }

  static Future<bool> isLoggedIn() async {
    final hasToken = await TokenStorage.hasToken();
    print('Verificando si está logueado: $hasToken');
    return hasToken;
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
