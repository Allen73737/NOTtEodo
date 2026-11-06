import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'device_notification_service.dart';

class CalendarReminderService {
  static final CalendarReminderService _instance = CalendarReminderService._internal();
  factory CalendarReminderService() => _instance;
  CalendarReminderService._internal();

  static const MethodChannel _calendarChannel = MethodChannel('notteodo/calendar');

  /// Adds a task or event to Google Calendar / device calendar app.
  Future<bool> addToGoogleCalendar({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? location,
  }) async {
    final effectiveEnd = endTime ?? startTime.add(const Duration(hours: 1));
    if (kIsWeb) {
      // In web or tests, return success simulation
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
        return res ?? true;
      }
    } catch (_) {}

    return true;
  }

  /// Sets an active device reminder notification (via native AlarmManager & notification bar).
  Future<bool> scheduleDeviceReminder({
    required String id,
    required String title,
    required DateTime scheduledTime,
    String? body,
  }) async {
    final intId = id.hashCode.abs() % 1000000;
    return await DeviceNotificationService().scheduleReminder(
      id: intId,
      title: 'Reminder: $title',
      body: body ?? 'Scheduled task reminder from NOTtEodo',
      scheduledTime: scheduledTime,
      channelId: 'notteodo_reminders',
    );
  }

  /// Cancels a scheduled device reminder.
  Future<void> cancelDeviceReminder(String id) async {
    final intId = id.hashCode.abs() % 1000000;
    await DeviceNotificationService().cancelNotification(intId);
  }
}

