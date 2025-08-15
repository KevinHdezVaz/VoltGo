import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

class DatePickerBottomSheet extends StatefulWidget {
  final DateTime? initialDate;

  const DatePickerBottomSheet({Key? key, this.initialDate}) : super(key: key);

  @override
  _DatePickerBottomSheetState createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 0 &&
        _scrollController.position.extentBefore <= 0) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 8),
                        _buildSelectedDateDisplay(),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: _buildCustomCalendarHeader(),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: _buildCalendar(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildActionButtons(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text('Cuándo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSelectedDateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          const Text('Cuándo'),
          const Spacer(),
          Text(
            _selectedDay != null
                ? DateFormat('dd / MM / yyyy', 'es_ES').format(_selectedDay!)
                : '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => setState(() => _focusedDay = DateTime(
              _focusedDay.year, _focusedDay.month - 1, _focusedDay.day)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            toBeginningOfSentenceCase(
                DateFormat.MMMM('es_ES').format(_focusedDay))!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            DateFormat.y('es_ES').format(_focusedDay),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => setState(() => _focusedDay = DateTime(
              _focusedDay.year, _focusedDay.month + 1, _focusedDay.day)),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      locale: 'es_ES',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) => setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      }),
      headerVisible: false,
      calendarStyle: CalendarStyle(
        selectedDecoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.5), shape: BoxShape.circle),
      ),
      daysOfWeekStyle:
          const DaysOfWeekStyle(weekendStyle: TextStyle(color: Colors.black87)),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    bool isEnabled = _selectedDay != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salir',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () => Navigator.of(context).pop(_selectedDay)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
