// permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Cache para almacenar el estado de los permisos
  final Map<Permission, PermissionStatus> _permissionCache = {};

  Future<PermissionStatus> checkOrRequest(Permission permission) async {
    // Primero verificar si tenemos un valor en caché
    if (_permissionCache.containsKey(permission)) {
      return _permissionCache[permission]!;
    }

    // Verificar el estado actual del permiso
    var status = await permission.status;

    // Si está denegado permanentemente, no pedir de nuevo, solo abrir configuración
    if (status.isPermanentlyDenied) {
      _permissionCache[permission] = status;
      return status;
    }

    // Si está denegado o no determinado, solicitar permiso
    if (status.isDenied || status.isRestricted) {
      status = await permission.request();
      _permissionCache[permission] = status;
      return status;
    }

    // Si ya está concedido, guardar en caché y retornar
    _permissionCache[permission] = status;
    return status;
  }

  Future<void> resetCache() async {
    _permissionCache.clear();
  }

  Future<bool> shouldShowRequestRationale(Permission permission) async {
    final status = await permission.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }
}
