import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../state/notification_log_state.dart';

class DeviceNotificationService {
  static final DeviceNotificationService _instance = DeviceNotificationService._internal();
  factory DeviceNotificationService() => _instance;
  DeviceNotificationService._internal();

  static const MethodChannel _channel = MethodChannel('notteodo/notifications');

  /// Requests notification permissions (required on Android 13+).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final granted = await _channel.invokeMethod<bool>('requestPermission');
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  /// Displays an immediate system notification in the device's notification bar.
  Future<bool> showSystemNotification({
    required String title,
    required String message,
    int? id,
    String channelId = 'notteodo_reminders',
  }) async {
    NotificationLogger.record(
      title: title,
      message: message,
      category: channelId.contains('engagement') || channelId.contains('streak')
          ? NotificationCategory.dailyEngagement
          : NotificationCategory.reminder,
      channel: 'Device Notification Bar',
    );

    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final notifId = id ?? (DateTime.now().millisecondsSinceEpoch % 100000);
        final res = await _channel.invokeMethod<bool>('showNotification', {
          'id': notifId,
          'title': title,
          'message': message,
          'channelId': channelId,
        });
        return res ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Schedules a system notification to ring/alert at [scheduledTime] (even if app is closed).
  Future<bool> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String channelId = 'notteodo_reminders',
  }) async {
    NotificationLogger.record(
      title: title,
      message: body,
      category: channelId.contains('engagement') || channelId.contains('streak')
          ? NotificationCategory.dailyEngagement
          : NotificationCategory.reminder,
      channel: 'Device Notification Bar (Scheduled)',
    );

    if (kIsWeb) return false;
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return false;

    try {
      if (Platform.isAndroid) {
        final triggerTimeMillis = scheduledTime.millisecondsSinceEpoch;
        final res = await _channel.invokeMethod<bool>('scheduleNotification', {
          'id': id,
          'title': title,
          'message': body,
          'triggerTimeMillis': triggerTimeMillis,
          'channelId': channelId,
        });
        return res ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Cancels an existing scheduled notification by id.
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('cancelNotification', {'id': id});
      }
    } catch (_) {}
  }
}

