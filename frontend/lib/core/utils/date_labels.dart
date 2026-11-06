import 'package:intl/intl.dart';

/// Human-readable labels for the real timestamps stored on every item.
class DateLabels {
  DateLabels._();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar-day key used for habit logs, e.g. `2026-11-01`.
  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime? parseDayKey(String key) => DateTime.tryParse(key);

  static bool isSameDay(DateTime a, DateTime b) => _day(a) == _day(b);

  /// "Just now", "Today", "Yesterday", "Aug 24", or "Aug 24, 2025" for other years.
  static String relative(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(d);
    if (diff.inSeconds >= 0 && diff.inMinutes < 1) return 'Just now';
    final days = _day(n).difference(_day(d)).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days == -1) return 'Tomorrow';
    return d.year == n.year ? DateFormat('MMM d').format(d) : DateFormat('MMM d, y').format(d);
  }

  /// "Aug 24" this year, "Aug 24, 2025" otherwise.
  static String short(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return d.year == n.year ? DateFormat('MMM d').format(d) : DateFormat('MMM d, y').format(d);
  }

  /// Always includes the year: "Aug 24, 2026".
  static String long(DateTime d) => DateFormat('MMM d, y').format(d);

  /// E.g. "November 2026"
  static String monthYear(DateTime d) => DateFormat('MMMM y').format(d);

  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  /// "Today · 10:00 AM", "Nov 4 · 9:30 PM".
  static String dateTime(DateTime d, {DateTime? now}) => '${relative(d, now: now)} · ${time(d)}';

  /// "Oct 12 – Oct 18, 2026" or "Dec 28, 2026 – Jan 3, 2027".
  static String range(DateTime start, DateTime? end) {
    if (end == null || isSameDay(start, end)) return long(start);
    if (start.year == end.year) {
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(end)}';
    }
    return '${long(start)} – ${long(end)}';
  }
}
