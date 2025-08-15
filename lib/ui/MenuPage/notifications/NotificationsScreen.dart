import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Voltgo_app/data/models/NotificationItem.dart' as model;
import 'package:Voltgo_app/data/services/NotificationsService.dart';
import 'package:Voltgo_app/data/models/alert/NotificationPermissions.dart';
import 'package:Voltgo_app/ui/MenuPage/notifications/NotificationDetailScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_app/utils/NotificationCountService.dart';
import 'package:Voltgo_app/utils/ReadStatusManager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  // Estados de UI y datos
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // Paginación
  int _currentPage = 1;
  bool _isFetchingMore = false;

  // Filtros
  int _selectedFilterIndex = 0;
  List<String> _filters = ['Todas'];

  // Listas de notificaciones
  List<model.Notification> _allNotifications = [];
  List<model.Notification> _todayNotifications = [];
  List<model.Notification> _previousNotifications = [];
  Set<int> _readNotificationIds = {};
  Set<int> _todayMasterIds =
      {}; // Almacena los IDs originales de hoy para la separación

  NotificationPermissions? _notificationPermissions;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Carga los datos iniciales (primera página y permisos).
  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      final results = await Future.wait([
        NotificationService.getNotifications(),
        NotificationService.getNotificationPermissions(),
        ReadStatusManager.getReadNotificationIds(),
      ]);

      final notificationData = results[0] as model.NotificationData;
      _notificationPermissions = results[1] as NotificationPermissions;
      final readIds = results[2] as Set<int>;

      if (mounted) {
        setState(() {
          // 1. Guardar los IDs de las notificaciones de hoy para poder separarlas después
          _todayMasterIds =
              notificationData.todayNotifications.map((n) => n.id).toSet();

          // 2. Combinar todas las notificaciones en una sola lista
          _allNotifications = [
            ...notificationData.todayNotifications,
            ...notificationData.previousNotifications,
          ];

          // 3. Ordenar la lista completa. La más reciente (ID más alto) primero.
          _allNotifications.sort((a, b) => b.id.compareTo(a.id));

          _readNotificationIds = readIds;

          // 4. Generar filtros y aplicar la lógica de visualización
          _generateFiltersFromNotifications(_allNotifications);
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "Error al cargar notificaciones.");
        debugPrint("Error en fetchInitialData: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  /// Listener del scroll para detectar el final y cargar más datos.
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                200 && // Margen para cargar antes
        !_isFetchingMore) {
      _fetchMoreNotifications();
    }
  }

  /// Carga las siguientes páginas de notificaciones.
  Future<void> _fetchMoreNotifications() async {
    setState(() => _isFetchingMore = true);
    try {
      _currentPage++;
      final notificationData =
          await NotificationService.getNotifications(page: _currentPage);

      if (mounted && notificationData.previousNotifications.isNotEmpty) {
        setState(() {
          // Añadir las nuevas notificaciones a la lista principal
          _allNotifications.addAll(notificationData.previousNotifications);
          // Re-ordenar la lista completa para mantener el orden
          _allNotifications.sort((a, b) => b.id.compareTo(a.id));
          // Aplicar filtros a la lista actualizada
          _applyFilters();
        });
      } else {
        // Si no vienen más, detenemos las futuras llamadas para esta sesión.
        _currentPage--;
      }
    } catch (e) {
      debugPrint("Error al obtener más notificaciones: $e");
      _currentPage--; // Revertir en caso de error
    } finally {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  /// Maneja la acción de tocar una notificación.
  void _handleNotificationTap(model.Notification notification) {
    NotificationService.setNotificationRead(notificationId: notification.id)
        .catchError((e) {
      debugPrint("Fallo al marcar como leída en la API: $e");
    });

    if (!_readNotificationIds.contains(notification.id)) {
      setState(() {
        _readNotificationIds.add(notification.id);
      });
      ReadStatusManager.markNotificationAsRead(notification.id);
      NotificationCountService.decrementCount();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              NotificationDetailScreen(notificationId: notification.id)),
    ).then((_) {
      // Opcional: refrescar estado si es necesario al volver de la pantalla de detalle
    });
  }

  /// Genera los chips de filtro basados en los tipos de notificación recibidos.
  void _generateFiltersFromNotifications(
      List<model.Notification> notifications) {
    final availableTypes = notifications
        .map((n) => n.type)
        .toSet()
        .where((type) => _isAlertTypeAllowed(type))
        .toList();
    setState(() {
      _filters = ['Todas', ...availableTypes];
    });
  }

  void _applyFilters() {
    setState(() {
      // Filtrar la lista maestra ordenada
      List<model.Notification> filtered =
          _allNotifications.where((n) => _isAlertTypeAllowed(n.type)).toList();

      if (_selectedFilterIndex != 0) {
        final selectedType = _filters[_selectedFilterIndex];
        filtered = filtered.where((n) => n.type == selectedType).toList();
      }

      // Separar la lista filtrada en 'Hoy' y 'Anteriores' para la UI
      // La ordenación se mantiene porque 'filtered' ya está ordenada.
      _todayNotifications =
          filtered.where((n) => _todayMasterIds.contains(n.id)).toList();
      _previousNotifications =
          filtered.where((n) => !_todayMasterIds.contains(n.id)).toList();
    });
  }

  /// Verifica si un tipo de alerta está permitido según la configuración del usuario.
  bool _isAlertTypeAllowed(String alertType) {
    if (_notificationPermissions == null ||
        !_notificationPermissions!.allowNotification) {
      return false;
    }
    final p = _notificationPermissions!.alertPermissions;

    return (p.maxSpeed && alertType == 'Velocidad Maxima') ||
        (p.shortBreak && alertType == 'descanso corto') ||
        (p.noArrivalAtDestination &&
            alertType == 'No presentación en destino') ||
        (p.tenHoursDriving && alertType == 'conduccion 10 Horas') ||
        (p.continuousDriving && alertType == 'conduccion continua') ||
        (p.test && alertType == 'Test');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _buildBackButton(context),
        title: const Text('Notificaciones',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child:
                    _isLoading ? const SizedBox.shrink() : _buildBodyContent(),
              ),
            ],
          ),
          if (_isLoading)
            Center(
                child: AnimatedTruckProgress(animation: _animationController)),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_errorMessage != null) {
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_notificationPermissions != null &&
        !_notificationPermissions!.allowNotification) {
      return const Center(
          child: Text('Las notificaciones están desactivadas.'));
    }

    final bool hasNoVisibleNotifications =
        _todayNotifications.isEmpty && _previousNotifications.isEmpty;
    if (hasNoVisibleNotifications) {
      return const Center(child: Text('No hay notificaciones para mostrar.'));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: [
        if (_todayNotifications.isNotEmpty) ...[
          _buildSectionHeader('Hoy'),
          ..._todayNotifications
              .map((notification) => _buildNotificationTile(notification))
              .toList(),
        ],
        if (_previousNotifications.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Anteriormente'),
          ..._previousNotifications
              .map((notification) => _buildNotificationTile(notification))
              .toList(),
        ],
        if (_isFetchingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: _selectedFilterIndex == index,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedFilterIndex = index;
                    _applyFilters();
                  });
                }
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: AppColors.primary.withOpacity(0.1),
              labelStyle: TextStyle(
                  color: _selectedFilterIndex == index
                      ? AppColors.primary
                      : Colors.black87),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(model.Notification notification) {
    final bool isUnread = !_readNotificationIds.contains(notification.id);
    String extractPlate(String body) {
      RegExp regex = RegExp(r'Vehiculo\s([\w\s-]+),');
      Match? match = regex.firstMatch(body);
      return match?.group(1)?.trim() ?? 'N/A';
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: isUnread
            ? AppColors.primary.withOpacity(0.1)
            : Colors.grey.shade200,
        child: Icon(_getIconForAlert(notification.type),
            color: AppColors.primary, size: 28),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 6),
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle)),
          ],
          const SizedBox(width: 8),
          Text(notification.hour,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'Móvil: ${extractPlate(notification.body)}',
          style: const TextStyle(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      isThreeLine: true,
      onTap: () => _handleNotificationTap(notification),
    );
  }

  IconData _getIconForAlert(String alertName) {
    String name = alertName.toLowerCase();
    if (name.contains('velocidad')) return Icons.speed;
    if (name.contains('conduccion') ||
        name.contains('horas') ||
        name.contains('continua')) return Icons.time_to_leave;
    if (name.contains('descanso')) return Icons.hotel;
    if (name.contains('destino')) return Icons.location_on;
    if (name.contains('test')) return Icons.science;
    return Icons.notifications;
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Image.asset('assets/images/backbtn.png', width: 40, height: 40),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Text('¿No encuentras más notificaciones?',
              style: TextStyle(color: Colors.grey.shade700)),
          TextButton(
            onPressed:
                () {}, // TODO: Implementar navegación a pantalla de historial si existe
            child: const Text('Ir al historial',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
