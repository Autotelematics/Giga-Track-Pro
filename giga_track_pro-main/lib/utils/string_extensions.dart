import 'translation_service.dart';

extension StringTranslation on String {
  Future<String> toUrdu() async {
    return await TranslationService().toUrdu(this);
  }

  /// Formats a duration string like "2117h 47min 42s" into years, months, days, etc.
  /// Example output: "2 months 28 days 5 hours 47 min 42 sec"
  String formatDuration() {
    if (this == '-' || isEmpty) return this;

    // Check if it already contains complex units to avoid double formatting
    if (contains('year') || contains('month') || contains('day')) return this;

    try {
      // Regex to extract hours, minutes, and seconds
      final hoursMatch = RegExp(r'(\d+)h').firstMatch(this);
      final minsMatch = RegExp(r'(\d+)(min|m)').firstMatch(this); 
      final secsMatch = RegExp(r'(\d+)s').firstMatch(this);

      int totalHours = hoursMatch != null ? int.parse(hoursMatch.group(1)!) : 0;
      int mins = minsMatch != null ? int.parse(minsMatch.group(1)!) : 0;
      int secs = secsMatch != null ? int.parse(secsMatch.group(1)!) : 0;

      if (totalHours < 1 && mins < 1 && secs < 1) return this;

      int totalDays = totalHours ~/ 24;
      int remainingHours = totalHours % 24;

      int years = totalDays ~/ 365;
      int daysAfterYears = totalDays % 365;
      
      int months = daysAfterYears ~/ 30;
      int remainingDays = daysAfterYears % 30;

      List<String> parts = [];

      if (years > 0) parts.add('$years year${years > 1 ? "s" : ""}');
      if (months > 0) parts.add('$months month${months > 1 ? "s" : ""}');
      if (remainingDays > 0) parts.add('$remainingDays day${remainingDays > 1 ? "s" : ""}');
      if (remainingHours > 0) parts.add('$remainingHours hour${remainingHours > 1 ? "s" : ""}');
      if (mins > 0) parts.add('$mins min');
      if (secs > 0) parts.add('$secs sec');

      if (parts.isEmpty) return this;
      
      return parts.join(' ');
    } catch (e) {
      return this;
    }
  }
}