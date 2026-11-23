import 'package:intl/intl.dart';

extension SafeDateTimeExtension on String {
  String toFormattedDateTime() {
    try {
      final dateTime = DateTime.parse(this);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return this; // 🔥 IMPORTANT: duration ya text same return karo
    }
  }
}