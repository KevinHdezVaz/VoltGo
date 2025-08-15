import 'package:flutter/material.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Todo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Historial de Actividad',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.textOnPrimary,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        shadowColor: AppColors.gray300.withOpacity(0.3),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Divider(height: 1, color: AppColors.gray300),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('Todo'),
            _buildChip('Rescues'),
            _buildChip('Ganancias'),
            _buildChip('Cancelados'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = label;
              // TODO: Aquí iría la lógica para volver a cargar los datos con el nuevo filtro
            });
          }
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.lightGrey,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.black : AppColors.gray300,
          ),
        ),
        elevation: isSelected ? 2 : 0,
        pressElevation: 4,
      ),
    );
  }

  Widget _buildHistoryList() {
    final items = [
      {'type': 'header', 'date': 'Hoy, 11 de Agosto'},
      {
        'type': 'item',
        'title': 'Rescate en Av. Insurgentes',
        'time': '10:45 PM',
        'amount': 22.50,
        'status': 'Completado'
      },
      {
        'type': 'item',
        'title': 'Entrega de paquete',
        'time': '08:30 PM',
        'amount': 12.00,
        'status': 'Completado'
      },
      {'type': 'header', 'date': 'Ayer, 10 de Agosto'},
      {
        'type': 'item',
        'title': 'Viaje al aeropuerto',
        'time': '06:15 PM',
        'amount': 35.00,
        'status': 'Completado'
      },
      {
        'type': 'item',
        'title': 'Rescate cancelado',
        'time': '04:00 PM',
        'amount': 0.00,
        'status': 'Cancelado'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item['type'] == 'header') {
          return _buildDateHeader(item['date'] as String);
        } else {
          return _buildHistoryItem(
            icon: item['status'] == 'Cancelado'
                ? Icons.cancel
                : Icons.directions_car,
            title: item['title'] as String,
            time: item['time'] as String,
            amount: item['amount'] as double,
            status: item['status'] as String,
          );
        }
      },
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        date,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String time,
    required double amount,
    required String status,
  }) {
    final statusColor =
        status == 'Completado' ? AppColors.success : AppColors.error;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navegar a la pantalla de detalles del viaje/rescate
        },
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '$time • $status',
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
