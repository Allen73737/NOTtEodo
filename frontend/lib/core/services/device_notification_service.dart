import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../state/notification_log_state.dart';

class DeviceNotificationService {
  static final DeviceNotificationService _instance = DeviceNotificationService._internal();
  factory DeviceNotificationService() => _instance;

  static const MethodChannel _channel = MethodChannel('notteodo/notifications');
  static const MethodChannel _focusActionsChannel = MethodChannel('notteodo/focus_actions');

  final _focusActionController = StreamController<String>.broadcast();
  Stream<String> get onFocusAction => _focusActionController.stream;

  final _quickTileActionController = StreamController<String>.broadcast();
  Stream<String> get onQuickTileAction => _quickTileActionController.stream;

  DeviceNotificationService._internal() {
    _focusActionsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onFocusAction') {
        final action = call.arguments is Map ? call.arguments['action'] as String? : null;
        if (action != null) {
          _focusActionController.add(action);
        }
      } else if (call.method == 'onQuickTileAction') {
        final action = call.arguments is Map ? call.arguments['action'] as String? : null;
        if (action != null) {
          _quickTileActionController.add(action);
        }
      }
    });
  }

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

  /// Displays or updates an ongoing focus timer media notification in the system shade.
  Future<void> updateFocusNotification({
    required String soundTitle,
    required String remainingFormatted,
    required bool isRunning,
    required int totalSeconds,
    required int remainingSeconds,
  }) async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('updateFocusNotification', {
          'soundTitle': soundTitle,
          'remainingFormatted': remainingFormatted,
          'isRunning': isRunning,
          'totalSeconds': totalSeconds,
          'remainingSeconds': remainingSeconds,
        });
      }
    } catch (_) {}
  }

  /// Clears the ongoing focus notification when session ends or is reset.
  Future<void> cancelFocusNotification() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('cancelFocusNotification');
      }
    } catch (_) {}
  }
}

