/// Turns phrases like "tomorrow at 3pm", "fri 9:30", "in 2 hours", "nov 4 noon" or
/// "2026-11-04 18:00" into a date-time. Returns null when nothing date-like is found.
class NlpDateParser {
  static const _weekdays = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Default hour when a day is given without a time.
  static const int defaultHour = 9;

  static DateTime? parse(String text, {DateTime? now}) => tryParse(text, now: now);

  static DateTime? tryParse(String text, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final s = ' ${text.toLowerCase().trim()} ';
    if (s.trim().isEmpty) return null;

    // Relative offsets: "in 30 minutes", "in 2 hours", "in 3 days", "in 1 week".
    final rel = RegExp(r'\bin (\d+) ?(min|minute|minutes|h|hr|hrs|hour|hours|d|day|days|w|week|weeks)\b').firstMatch(s);
    if (rel != null) {
      final v = int.parse(rel.group(1)!);
      final unit = rel.group(2)!;
      final d = unit.startsWith('m')
          ? Duration(minutes: v)
          : unit.startsWith('h')
              ? Duration(hours: v)
              : unit.startsWith('w')
                  ? Duration(days: 7 * v)
                  : Duration(days: v);
      return n.add(d);
    }

    DateTime? day;
    // ISO date: 2026-11-04
    final iso = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b').firstMatch(s);
    if (iso != null) {
      day = DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    }

    // Month name + day: "nov 4", "4 nov", "november 4th"
    if (day == null) {
      int? month, date;
      for (final m in RegExp(r'\b([a-z]{3})[a-z]* (\d{1,2})(?:st|nd|rd|th)?\b(?!:)').allMatches(s)) {
        if (_months.containsKey(m.group(1))) {
          month = _months[m.group(1)];
          date = int.parse(m.group(2)!);
          break;
        }
      }
      if (month == null) {
        for (final m in RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)? ([a-z]{3})[a-z]*\b').allMatches(s)) {
          if (_months.containsKey(m.group(2))) {
            month = _months[m.group(2)];
            date = int.parse(m.group(1)!);
            break;
          }
        }
      }
      if (month != null && date != null && date >= 1 && date <= 31) {
        var candidate = DateTime(n.year, month, date);
        // A date already behind us this year means next year.
        if (candidate.isBefore(DateTime(n.year, n.month, n.day))) candidate = DateTime(n.year + 1, month, date);
        day = candidate;
      }
    }

    final today = DateTime(n.year, n.month, n.day);
    if (day == null) {
      if (RegExp(r'\b(today|tonight|this evening)\b').hasMatch(s)) {
        day = today;
      } else if (RegExp(r'\b(tomorrow|tmrw|tmr)\b').hasMatch(s)) {
        day = today.add(const Duration(days: 1));
      } else {
        final wd = RegExp(r'\b(next )?(mon|tue|wed|thu|fri|sat|sun)[a-z]*\b').firstMatch(s);
        if (wd != null) {
          final target = _weekdays[wd.group(2)]!;
          var ahead = (target - n.weekday + 7) % 7;
          if (ahead == 0) ahead = 7;
          day = today.add(Duration(days: ahead));
        }
      }
    }

    // Time of day.
    int? hour, minute;
    final t12 = RegExp(r'\b(\d{1,2})(?::(\d{2}))? ?(am|pm)\b').firstMatch(s);
    final t24 = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(s);
    if (t12 != null) {
      final h = int.parse(t12.group(1)!);
      if (h >= 1 && h <= 12) {
        hour = (h % 12) + (t12.group(3) == 'pm' ? 12 : 0);
        minute = int.tryParse(t12.group(2) ?? '0') ?? 0;
      }
    } else if (t24 != null) {
      final h = int.parse(t24.group(1)!), m = int.parse(t24.group(2)!);
      if (h < 24 && m < 60) {
        hour = h;
        minute = m;
      }
    } else if (s.contains(' noon ')) {
      hour = 12;
      minute = 0;
    } else if (s.contains(' midnight ')) {
      hour = 0;
      minute = 0;
    } else if (RegExp(r'\b(tonight|this evening)\b').hasMatch(s)) {
      hour = 20;
      minute = 0;
    } else if (s.contains(' morning ')) {
      hour = 9;
      minute = 0;
    } else if (s.contains(' afternoon ')) {
      hour = 14;
      minute = 0;
    } else if (s.contains(' evening ')) {
      hour = 18;
      minute = 0;
    }

    if (day == null && hour == null) return null;
    if (day == null) {
      // A bare time means the next time the clock shows it.
      final candidate = DateTime(n.year, n.month, n.day, hour!, minute ?? 0);
      return candidate.isAfter(n) ? candidate : candidate.add(const Duration(days: 1));
    }
    return DateTime(day.year, day.month, day.day, hour ?? defaultHour, minute ?? 0);
  }

  /// Kept for older call sites: falls back to two hours from now.
  static DateTime parseNaturalLanguage(String text) =>
      tryParse(text) ?? DateTime.now().add(const Duration(hours: 2));

  static String formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $period';
  }
}
