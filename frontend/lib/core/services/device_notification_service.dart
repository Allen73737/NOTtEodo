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

  final _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get onDeepLink => _deepLinkController.stream;
  String? _pendingDeepLink;
  String? get pendingDeepLink => _pendingDeepLink;
  void consumePendingDeepLink() {
    _pendingDeepLink = null;
  }

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
      } else if (call.method == 'onDeepLink') {
        final target = call.arguments is Map ? call.arguments['target'] as String? : null;
        if (target != null) {
          _pendingDeepLink = target;
          _deepLinkController.add(target);
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

  /// Schedules a system notification at [scheduledTime], even if the app is closed.
  /// The device keeps it across reboots; with [repeatDaily] it recurs at the same time.
  Future<bool> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String channelId = 'notteodo_reminders',
    bool repeatDaily = false,
    String? soundId,
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
          'repeatDaily': repeatDaily,
          if (soundId != null) 'soundId': soundId,
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

  /// Cancels all scheduled and active reminders/notifications.
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('cancelAllNotifications');
      }
    } catch (_) {}
  }

  /// Starts the live on-device notification panel countdown timer.
  Future<bool> startCadenceTimerNotification({
    required int durationSeconds,
    String? title,
    String? soundId,
  }) async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('startCadenceTimer', {
          'durationSeconds': durationSeconds,
          if (title != null) 'title': title,
          if (soundId != null) 'soundId': soundId,
        });
        return res ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Extends the live on-device timer by [additionalSeconds] (default 15 mins).
  Future<bool> extendCadenceTimerNotification({int additionalSeconds = 900}) async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('extendCadenceTimer', {
          'additionalSeconds': additionalSeconds,
        });
        return res ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Resets the live on-device timer back to its initial configured duration.
  Future<bool> resetCadenceTimerNotification() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('resetCadenceTimer');
        return res ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Cancels and clears the live on-device timer from the notification panel.
  Future<void> cancelCadenceTimerNotification() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('cancelCadenceTimer');
      }
    } catch (_) {}
  }

  /// Queries the live on-device timer status.
  Future<Map<String, dynamic>?> getCadenceTimerStatus() async {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMapMethod<String, dynamic>('getCadenceTimerStatus');
        return res;
      }
    } catch (_) {}
    return null;
  }

  /// Synchronizes user aesthetic sound preferences and curator details with native Android receiver.
  Future<void> syncNotificationPreferences({
    String? alarmSound,
    String? notificationSound,
    String? customAlarmSoundPath,
    String? customNotificationSoundPath,
    String? displayName,
    int? activeStreak,
  }) async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('syncNotificationPreferences', {
          if (alarmSound != null) 'alarmSound': alarmSound,
          if (notificationSound != null) 'notificationSound': notificationSound,
          if (customAlarmSoundPath != null) 'customAlarmSoundPath': customAlarmSoundPath,
          if (customNotificationSoundPath != null) 'customNotificationSoundPath': customNotificationSoundPath,
          if (displayName != null) 'displayName': displayName,
          if (activeStreak != null) 'activeStreak': activeStreak,
        });
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

