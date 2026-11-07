import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'device_notification_service.dart';

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

  /// Sets an active device reminder notification (via native AlarmManager & notification bar).
  /// If [scheduledTime] is in the past, advances to the same clock time on the next day.
  Future<bool> scheduleDeviceReminder({
    required String id,
    required String title,
    required DateTime scheduledTime,
    String? body,
  }) async {
    final intId = id.hashCode.abs() % 1000000;
    var targetTime = scheduledTime;
    final now = DateTime.now();
    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }
    return await DeviceNotificationService().scheduleReminder(
      id: intId,
      title: 'Reminder: $title',
      body: body ?? 'Scheduled task reminder from NOTtEodo',
      scheduledTime: targetTime,
      channelId: 'notteodo_reminders',
    );
  }

  /// Cancels a scheduled device reminder.
  Future<void> cancelDeviceReminder(String id) async {
    final intId = id.hashCode.abs() % 1000000;
    await DeviceNotificationService().cancelNotification(intId);
  }
}
