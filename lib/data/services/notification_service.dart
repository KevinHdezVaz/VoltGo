import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NotificationServiceFirebase {
  void _log(String message) {
    print('[FirebaseNotification] $message');
  }

  static ValueNotifier<String?> fcmTokenNotifier = ValueNotifier(null);
  static ValueNotifier<String?> apnsTokenNotifier =
      ValueNotifier(null); // <-- NUEVO
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> _configureIOSNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _log('📱 Estado de permisos iOS: ${settings.authorizationStatus}');
  }

  Future<void> initAndSendDeviceData() async {
    _log('🚀 Iniciando proceso de registro de dispositivo...');
    try {
      _log('ℹ️ Solicitando permisos para notificaciones...');
      await _firebaseMessaging.requestPermission();
      _log('✅ Permisos concedidos.');

      if (Platform.isIOS) {
        _log('ℹ️ Obteniendo APNs Token...');
        final String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          _log('✅ APNs Token obtenido!');
          apnsTokenNotifier.value = apnsToken;
        } else {
          _log('❌ No se pudo obtener el APNs Token.');
          apnsTokenNotifier.value = "Error al obtener APNs token";
        }
      }

      _log('ℹ️ Obteniendo FCM Token...');
      final String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken == null) {
        _log(
            '❌ ERROR: No se pudo obtener el FCM Token. El proceso se detiene.');
        return;
      }
      _log('✅ FCM Token obtenido: $fcmToken');

      fcmTokenNotifier.value = fcmToken; // Notifica el token a la UI

      _log('ℹ️ Obteniendo información del dispositivo y la app...');
      final String deviceId =
          await _getDeviceId(); // Esta función ahora es más inteligente
      final String appVersion = await _getAppVersion();
      final String deviceType = Platform.isAndroid ? 'android' : 'ios';

      _log('✅ ID del Dispositivo: $deviceId');
      _log('✅ Tipo de Dispositivo: $deviceType');
      _log('✅ Versión de la App: $appVersion');

      final Map<String, dynamic> deviceData = {
        'fcm_token': fcmToken,
        'device_id': deviceId,
        'device_type': deviceType,
        'version_app': appVersion,
      };

      await _sendDataToBackend(deviceData);
      _listenForTokenRefresh();
      _log('🏁 Proceso de registro de dispositivo finalizado.');
    } catch (e) {
      fcmTokenNotifier.value =
          'Error: ${e.toString()}'; // Notifica el error a la UI

      _log('❌ ERROR CRÍTICO en initAndSendDeviceData: $e');
    }
  }

  void _listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newFcmToken) async {
      _log('🔄 ATENCIÓN: El token de FCM ha sido actualizado.');
      _log('   Nuevo token: $newFcmToken');
      _log('   Reenviando datos actualizados al backend...');

      _log('🔄 ATENCIÓN: El token de FCM ha sido actualizado a: $newFcmToken');
      fcmTokenNotifier.value =
          newFcmToken; // Actualiza el token en la UI también

      try {
        final String deviceId = await _getDeviceId();
        final String appVersion = await _getAppVersion();
        final String deviceType = Platform.isAndroid ? 'android' : 'ios';

        final Map<String, dynamic> updatedData = {
          'fcm_token': newFcmToken,
          'device_id': deviceId,
          'device_type': deviceType,
          'version_app': appVersion,
        };
        await _sendDataToBackend(updatedData);
      } catch (e) {
        _log('❌ ERROR al reenviar el token actualizado: $e');
      }
    });
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isIOS) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_id_not_found';
      } else if (Platform.isAndroid) {
        return await _getAndroidUniqueId();
      }
    } catch (e) {
      _log('❌ Error obteniendo ID del dispositivo: $e');
    }
    return 'unknown_device_id';
  }

  Future<String> _getAndroidUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_id'; // La clave donde guardamos nuestro ID
    String? storedId = prefs.getString(key);

    if (storedId == null) {
      final uuid = Uuid();
      String newId = uuid
          .v4(); // Generamos un ID único (ej: "123e4567-e89b-12d3-a456-426614174000")
      await prefs.setString(key, newId); // Lo guardamos para el futuro
      _log(
          'ℹ️ No se encontró ID de dispositivo para Android. Generando uno nuevo: $newId');
      return newId;
    } else {
      _log('ℹ️ Usando ID de dispositivo de Android almacenado: $storedId');
      return storedId;
    }
  }

  Future<String> _getAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      _log('❌ Error obteniendo la versión de la app: $e');
    }
    return 'unknown_app_version';
  }

  Future<void> _sendDataToBackend(Map<String, dynamic> data) async {
    _log('ℹ️ Preparando envío de datos al backend...');

    final authToken = await TokenStorage.getToken();
    if (authToken == null) {
      _log(
          '❌ ERROR: No se encontró token de autorización. No se puede enviar al backend.');
      return;
    }
    _log(
        '🔑 Usando token de autorización: ...${authToken.substring(authToken.length - 6)}');

    final url = Uri.parse('https://fleetmobile.Voltgo.cl/user/assign-device');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Token $authToken',
    };
    final body = jsonEncode(data);

    _log('--- 📋 Petición HTTP (cURL) ---');
    _log("curl --location --request POST '${url.toString()}' \\");
    headers.forEach((key, value) {
      _log("--header '$key: $value' \\");
    });
    _log("--data-raw '$body'");
    _log('---------------------------------');

    try {
      _log('🚀 Enviando datos a ${url.toString()}...');
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log(
            '✅ ÉXITO: Datos enviados correctamente (Código: ${response.statusCode})');
        _log('   Respuesta del Servidor: ${response.body}');
      } else {
        _log('❌ ERROR al enviar datos (Código: ${response.statusCode})');
        _log('   Respuesta del Servidor: ${response.body}');
      }
    } catch (e) {
      _log('❌ EXCEPCIÓN al intentar conectar con el backend: $e');
    }
  }
}
