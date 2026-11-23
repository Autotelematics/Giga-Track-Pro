import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/view/filter_for_history.dart' show CustomHistoryDateTimePicker;

class ActionButtonsPanel extends StatelessWidget {
  final int deviceId;
  final String deviceTitle;

  const ActionButtonsPanel({
    super.key,
    required this.deviceId,
    required this.deviceTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 30,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(child: _historyButton(context)),
          const SizedBox(width: 12),
          Expanded(child: _reportButton(context)),
        ],
      ),
    );
  }

  // 🔵 HISTORY BUTTON WITH POPUP
  Widget _historyButton(BuildContext context) {
    return PopupMenuButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        _handleNavigation(context, value, isReport: false);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text('Today')),
        PopupMenuItem(value: 1, child: Text('Yesterday')),
        PopupMenuItem(value: 7, child: Text('7 Days')),
        PopupMenuItem(value: 30, child: Text('30 Days')),
        PopupMenuItem(value: 2, child: Text('Custom Date')),
      ],
      child: _buildButton(Icons.history, "View\nHistory"),
    );
  }

  Widget _reportButton(BuildContext context) {
    return PopupMenuButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        _handleNavigation(context, value, isReport: true);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text('Today')),
        PopupMenuItem(value: 1, child: Text('Yesterday')),
        PopupMenuItem(value: 7, child: Text('7 Days')),
        PopupMenuItem(value: 30, child: Text('30 Days')),
        PopupMenuItem(value: 2, child: Text('Custom Date')),
      ],
      child: _buildButton(Icons.report_outlined, "View\nReports"),
    );
  }

  // ✅ CUSTOM DATE PICKER DIALOG
  Future<void> _showDatePickerDialog(
      BuildContext context,
      String screenRoute,
      ) {
    return showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomHistoryDateTimePicker(
                deviceId,
                screenRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int value,
      {required bool isReport}) {
    String toDate;
    String fromDate;
    String fromTime = '00:00:00';
    String toTime = '23:59:59';

    DateTime dt = DateTime.now();
    DateFormat format = DateFormat("yyyy-MM-dd");

    switch (value) {
      case 0: // Today
        fromDate = format.format(dt);
        toDate = format.format(dt);
        _navigateToPage(
          context,
          isReport,
          fromDate,
          toDate,
          fromTime,
          toTime,
        );
        break;

      case 1: // Yesterday (ONLY yesterday)
        final yesterday = dt.subtract(const Duration(days: 1));
        fromDate = format.format(yesterday);
        toDate = format.format(yesterday);
        _navigateToPage(
          context,
          isReport,
          fromDate,
          toDate,
          fromTime,
          toTime,
        );
        break;

      case 7: // 7 Days (today + previous 6 days)
        fromDate = format.format(dt.subtract(const Duration(days: 6)));
        toDate = format.format(dt);
        _navigateToPage(
          context,
          isReport,
          fromDate,
          toDate,
          fromTime,
          toTime,
        );
        break;

      case 30: // 30 Days (today + previous 29 days)
        fromDate = format.format(dt.subtract(const Duration(days: 29)));
        toDate = format.format(dt);
        _navigateToPage(
          context,
          isReport,
          fromDate,
          toDate,
          fromTime,
          toTime,
        );
        break;

      case 2: // ✅ CUSTOM DATE
        _showDatePickerDialog(
          context,
          isReport ? 'reporttype' : 'playroutonmap',
        );
        break;

      default:
        break;
    }
  }

  // ✅ HELPER METHOD - NAVIGATE TO PAGE
  void _navigateToPage(
      BuildContext context,
      bool isReport,
      String fromDate,
      String toDate,
      String fromTime,
      String toTime,
      ) {
    Navigator.pushNamed(
      context,
      isReport ? RoutesName.reporttype : RoutesName.playroutonmap,
      arguments: DeviceHistoryOnMapInitialData(
        deviceTitle: deviceTitle,
        deviceId: deviceId,
        fromDate: fromDate,
        toDate: toDate,
        fromTime: fromTime,
        toTime: toTime,
      ),
    );
  }

  // 🎨 SAME UI BUTTON DESIGN
  Widget _buildButton(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.fromARGB(255, 93, 161, 245),
            Color.fromARGB(255, 2, 107, 244),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}