import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'device_notification_service.dart';
import 'local_store.dart';

class CalendarReminderService {
  static final CalendarReminderService _instance = CalendarReminderService._internal();
  factory CalendarReminderService() => _instance;
  CalendarReminderService._internal();

  static const MethodChannel _calendarChannel = MethodChannel('notteodo/calendar');

  /// Generates the modern Google Calendar event editor URL (/calendar/u/0/r/eventedit)
  /// with pre-populated event details.
  static Uri buildGoogleCalendarUrl({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? location,
  }) {
    final effectiveEnd = endTime ?? startTime.add(const Duration(hours: 1));
    final startIso = _formatCalendarUtc(startTime);
    final endIso = _formatCalendarUtc(effectiveEnd);
    final queryParams = <String, String>{
      'text': title,
      'dates': '$startIso/$endIso',
    };
    if (description != null && description.trim().isNotEmpty) {
      queryParams['details'] = description.trim();
    }
    if (location != null && location.trim().isNotEmpty) {
      queryParams['location'] = location.trim();
    }
    return Uri.https('calendar.google.com', '/calendar/u/0/r/eventedit', queryParams);
  }

  static String _formatCalendarUtc(DateTime dt) {
    final u = dt.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final h = u.hour.toString().padLeft(2, '0');
    final min = u.minute.toString().padLeft(2, '0');
    final s = u.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  /// Adds a task or event to Google Calendar / device calendar app.
  /// Launches native Google Calendar edit activity with title, dates, and notes pre-filled.
  Future<bool> addToGoogleCalendar({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? location,
  }) async {
    final effectiveEnd = endTime ?? startTime.add(const Duration(hours: 1));
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        final uri = buildGoogleCalendarUrl(
          title: title,
          startTime: startTime,
          endTime: effectiveEnd,
          description: description,
          location: location,
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      return true;
    }

    try {
      if (Platform.isAndroid) {
        final res = await _calendarChannel.invokeMethod<bool>('addToCalendar', {
          'title': title,
          'description': description,
          'location': location,
          'beginTimeMillis': startTime.millisecondsSinceEpoch,
          'endTimeMillis': effectiveEnd.millisecondsSinceEpoch,
        });
        if (res == true) return true;
      }
    } catch (_) {}

    // Fallback: Launch modern Google Calendar URL in external browser/calendar app
    try {
      final uri = buildGoogleCalendarUrl(
        title: title,
        startTime: startTime,
        endTime: effectiveEnd,
        description: description,
        location: location,
      );
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    return false;
  }

  static const String _storeKey = 'device_reminders';

  /// Stable notification id for an item id. Dart's `String.hashCode` is not guaranteed to
  /// be the same across runs, and the native side keeps alarms across restarts, so this
  /// uses FNV-1a. Ids land in 100000..999999, clear of the engagement range (8801-8850).
  static int notificationIdFor(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 100000 + hash % 900000;
  }

  /// Item ids with a device reminder still pending, mapped to when it fires.
  Map<String, DateTime> get pendingReminders {
    final raw = LocalStore().readMap(_storeKey) ?? const {};
    return {
      for (final e in raw.entries)
        if (DateTime.tryParse('${e.value}') case final at?) e.key: at,
    };
  }

  void _savePending(Map<String, DateTime> pending) {
    LocalStore().writeMap(_storeKey, {for (final e in pending.entries) e.key: e.value.toIso8601String()});
  }

  /// Sets a device reminder that fires at [scheduledTime] even when the app is closed,
  /// replacing any earlier reminder for the same item. Returns false, without scheduling,
  /// when the time has already passed, so callers can tell the user instead of the
  /// reminder silently moving to another day.
  Future<bool> scheduleDeviceReminder({
    required String id,
    required String title,
    required DateTime scheduledTime,
    String? body,
  }) async {
    if (!scheduledTime.isAfter(DateTime.now())) return false;
    final ok = await DeviceNotificationService().scheduleReminder(
      id: notificationIdFor(id),
      title: title,
      body: body ?? 'Reminder from NOTtEodo',
      scheduledTime: scheduledTime,
      channelId: 'notteodo_reminders',
    );
    _savePending({...pendingReminders, id: scheduledTime});
    return ok;
  }

  /// Cancels the device reminder for item [id], if any.
  Future<void> cancelDeviceReminder(String id) async {
    final pending = pendingReminders;
    if (pending.remove(id) != null) _savePending(pending);
    await DeviceNotificationService().cancelNotification(notificationIdFor(id));
  }

  /// Cancels reminders whose item was deleted or completed, and forgets ones that fired
  /// over a day ago. Run whenever tasks or events change, so a finished task never rings.
  Future<void> reconcile({required Set<String> liveIds}) async {
    // Fired reminders are remembered for a day so in-app alerts can still de-duplicate.
    final expired = DateTime.now().subtract(const Duration(days: 1));
    final pending = pendingReminders;
    final stale = [
      for (final e in pending.entries)
        if (!liveIds.contains(e.key) || e.value.isBefore(expired)) e.key,
    ];
    for (final id in stale) {
      pending.remove(id);
      if (!liveIds.contains(id)) {
        await DeviceNotificationService().cancelNotification(notificationIdFor(id));
      }
    }
    if (stale.isNotEmpty) _savePending(pending);
  }
}
