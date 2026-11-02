import '../state/sanctuary_state.dart';

/// Builds an iCalendar (.ics) file that Google Calendar, Apple Calendar and Outlook can import.
class IcsExport {
  IcsExport._();

  static String _stamp(DateTime d) {
    final u = d.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  static String _day(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}';
  }

  /// RFC 5545 text escaping.
  static String _text(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll(RegExp(r'\r?\n'), '\\n');

  /// Lines over 75 octets are folded with a leading space, as the spec requires.
  static String _fold(String line) {
    if (line.length <= 74) return line;
    final out = StringBuffer(line.substring(0, 74));
    for (var i = 74; i < line.length; i += 73) {
      out.write('\r\n ${line.substring(i, (i + 73).clamp(0, line.length))}');
    }
    return out.toString();
  }

  static String build({
    required List<PlannerEvent> events,
    List<TaskItem> tasks = const [],
    List<TravelTrip> trips = const [],
    DateTime? now,
  }) {
    final stamp = _stamp(now ?? DateTime.now());
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//NOTtEodo//Planner//EN',
      'CALSCALE:GREGORIAN',
    ];
    for (final e in events) {
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${e.id}@notteodo',
        'DTSTAMP:$stamp',
        'DTSTART:${_stamp(e.startsAt)}',
        'DTEND:${_stamp(e.endsAt)}',
        'SUMMARY:${_text(e.title)}',
        if (e.notes.isNotEmpty) 'DESCRIPTION:${_text(e.notes)}',
        'END:VEVENT',
      ]);
    }
    for (final t in tasks.where((t) => t.dueAt != null && !t.completed)) {
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:task-${t.id}@notteodo',
        'DTSTAMP:$stamp',
        'DTSTART:${_stamp(t.dueAt!)}',
        'DTEND:${_stamp(t.dueAt!.add(const Duration(minutes: 30)))}',
        'SUMMARY:${_text('Task: ${t.title}')}',
        if (t.notes.isNotEmpty) 'DESCRIPTION:${_text(t.notes)}',
        if (t.repeat == TaskRepeat.daily) 'RRULE:FREQ=DAILY',
        if (t.repeat == TaskRepeat.weekly) 'RRULE:FREQ=WEEKLY',
        if (t.repeat == TaskRepeat.monthly) 'RRULE:FREQ=MONTHLY',
        'END:VEVENT',
      ]);
    }
    for (final trip in trips.where((t) => t.startDate != null)) {
      final end = (trip.endDate ?? trip.startDate!).add(const Duration(days: 1)); // DTEND is exclusive
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:trip-${trip.id}@notteodo',
        'DTSTAMP:$stamp',
        'DTSTART;VALUE=DATE:${_day(trip.startDate!)}',
        'DTEND;VALUE=DATE:${_day(end)}',
        'SUMMARY:${_text('Trip: ${trip.title}')}',
        if (trip.destination.isNotEmpty) 'LOCATION:${_text(trip.destination)}',
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }
}
