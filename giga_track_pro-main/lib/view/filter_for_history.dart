import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

class CustomHistoryDateTimePicker extends StatefulWidget {
  final dynamic deviceID;
  final String screenRoute;

  const CustomHistoryDateTimePicker(
      this.deviceID,
      this.screenRoute, {
        super.key,
      });

  @override
  State<CustomHistoryDateTimePicker> createState() =>
      _CustomHistoryDateTimePickerState();
}

class _CustomHistoryDateTimePickerState
    extends State<CustomHistoryDateTimePicker> {
  static const Color _primaryColor = Color(0xFFFFA000);
  static const Color _primaryLight = Color(0xFFFFF7E6);
  static const Color _borderColor = Color(0xFFE8E8E8);
  static const Color _textPrimary = Color(0xFF252525);
  static const Color _textSecondary = Color(0xFF8A8A8A);

  late DateTime _fromDateTime;
  late DateTime _toDateTime;
  late String _buttonText;

  final DateFormat _dateFormat = DateFormat("yyyy-MM-dd");
  final DateFormat _timeFormat = DateFormat("HH:mm:ss");

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _fromDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      0,
      0,
      0,
    );

    _toDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    _buttonText = widget.screenRoute == 'playroutonmap'
        ? 'View History'
        : 'View Report';
  }

  Future<void> _pickFromDate() async {
    final selectedDate = await _showDatePicker(_fromDateTime);

    if (selectedDate != null) {
      setState(() {
        _fromDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          _fromDateTime.hour,
          _fromDateTime.minute,
          _fromDateTime.second,
        );
        if (_toDateTime.isBefore(_fromDateTime)) {
          _toDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            23,
            59,
            59,
          );
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    final selectedDate = await _showDatePicker(_toDateTime);

    if (selectedDate != null) {
      setState(() {
        _toDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          _toDateTime.hour,
          _toDateTime.minute,
          _toDateTime.second,
        );
      });
    }
  }

  Future<DateTime?> _showDatePicker(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(DateTime.now()) ? DateTime.now() : initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickFromTime() async {
    final selectedTime = await _showTimePicker(_fromDateTime);

    if (selectedTime != null) {
      setState(() {
        _fromDateTime = DateTime(
          _fromDateTime.year,
          _fromDateTime.month,
          _fromDateTime.day,
          selectedTime.hour,
          selectedTime.minute,
          0,
        );
      });
    }
  }

  Future<void> _pickToTime() async {
    final selectedTime = await _showTimePicker(_toDateTime);

    if (selectedTime != null) {
      setState(() {
        _toDateTime = DateTime(
          _toDateTime.year,
          _toDateTime.month,
          _toDateTime.day,
          selectedTime.hour,
          selectedTime.minute,
          59,
        );
      });
    }
  }

  Future<TimeOfDay?> _showTimePicker(DateTime dateTime) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: dateTime.hour,
        minute: dateTime.minute,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _primaryColor,
                onPrimary: Colors.white,
                onSurface: _textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  void _handleNavigate() {
    if (_toDateTime.isBefore(_fromDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date and time cannot be earlier than start date and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final arguments = DeviceHistoryOnMapInitialData(
      deviceId: widget.deviceID,
      fromDate: _dateFormat.format(_fromDateTime),
      toDate: _dateFormat.format(_toDateTime),
      fromTime: _timeFormat.format(_fromDateTime),
      toTime: _timeFormat.format(_toDateTime),
    );

    Navigator.pop(context);

    final routeName = widget.screenRoute == 'playroutonmap'
        ? RoutesName.playroutonmap
        : RoutesName.reporttype;

    Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required DateTime dateTime,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildPickerTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Date',
                  value: DateFormat('dd MMM yyyy').format(dateTime),
                  onTap: onDateTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPickerTile(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: DateFormat('hh:mm a').format(dateTime),
                  onTap: onTimeTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFF0F0F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: _primaryColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7D7D7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select Date & Time',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),

            const Text(
              'Choose a time range to view vehicle history or reports',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 22),

            _buildSection(
              title: 'From',
              subtitle: 'Start date and time',
              dateTime: _fromDateTime,
              onDateTap: _pickFromDate,
              onTimeTap: _pickFromTime,
            ),
            const SizedBox(height: 12),

            _buildSection(
              title: 'To',
              subtitle: 'End date and time',
              dateTime: _toDateTime,
              onDateTap: _pickToDate,
              onTimeTap: _pickToTime,
            ),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleNavigate,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _buttonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
