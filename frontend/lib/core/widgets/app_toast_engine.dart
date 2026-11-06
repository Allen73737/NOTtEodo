import 'dart:async';
import 'package:flutter/material.dart';

import '../services/local_store.dart';
import '../state/notification_log_state.dart';
import '../systems/aesthetic_audio_service.dart';
import 'sanctuary_animated_notification.dart';

enum ToastType { success, info, alert }

class AppToastItem {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;

  /// Optional inline action, e.g. "Undo" after a deletion.
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isAlarm;
  final String? customSoundId;

  AppToastItem({
    required this.title,
    required this.message,
    this.type = ToastType.success,
    this.duration = const Duration(seconds: 4),
    this.actionLabel,
    this.onAction,
    this.isAlarm = false,
    this.customSoundId,
  });
}

class AppToastEngine {
  static final AppToastEngine _instance = AppToastEngine._internal();
  factory AppToastEngine() => _instance;
  AppToastEngine._internal();

  final _toastStreamController = StreamController<AppToastItem>.broadcast();
  Stream<AppToastItem> get toastStream => _toastStreamController.stream;

  void showToast(
    BuildContext? context, {
    required String title,
    required String message,
    ToastType type = ToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
    bool isAlarm = false,
    String? customSoundId,
  }) {
    notify(
      title: title,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      isAlarm: isAlarm,
      customSoundId: customSoundId,
    );
  }

  /// Shows a luxury, animated heads-up notification from anywhere.
  void notify({
    required String title,
    required String message,
    ToastType type = ToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool isAlarm = false,
    String? customSoundId,
  }) {
    _toastStreamController.add(AppToastItem(
      title: title,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      isAlarm: isAlarm,
      customSoundId: customSoundId,
      duration: duration ?? Duration(seconds: actionLabel == null ? (isAlarm ? 6 : 4) : 7),
    ));

    NotificationLogger.record(
      title: title,
      message: message,
      category: isAlarm
          ? NotificationCategory.alarm
          : (type == ToastType.alert ? NotificationCategory.security : NotificationCategory.system),
      channel: isAlarm ? 'Alarm Escapement' : 'In-App Animated Banner',
    );
  }

  /// Convenience method for triggering explicit app-themed animated notifications
  void notifyAnimated({
    required String title,
    required String message,
    ToastType type = ToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool isAlarm = false,
    String? customSoundId,
  }) {
    notify(
      title: title,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      isAlarm: isAlarm,
      customSoundId: customSoundId,
    );
  }
}

class AppToastOverlay extends StatefulWidget {
  final Widget child;

  const AppToastOverlay({super.key, required this.child});

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _life;
  late StreamSubscription<AppToastItem> _subscription;
  AppToastItem? _currentToast;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _life = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      });
    _subscription = AppToastEngine().toastStream.listen(_handleNewToast);
  }

  void _handleNewToast(AppToastItem toast) {
    setState(() {
      _currentToast = toast;
    });

    _animController.forward(from: 0.0);
    _life
      ..duration = toast.duration
      ..forward(from: 0);

    // Play aesthetic audio cue & tactile haptics if sounds are enabled
    try {
      final isSoundOn = LocalStore().readBool('sound_fx_enabled') ?? true;
      if (isSoundOn) {
        final isAlarm = toast.isAlarm || toast.type == ToastType.alert;
        final soundId = isAlarm
            ? (toast.customSoundId ?? LocalStore().readString('alarm_sound') ?? 'horology_cascade')
            : (toast.customSoundId ?? LocalStore().readString('notification_sound') ?? 'velvet_obsidian');
        final customPath = isAlarm
            ? LocalStore().readString('custom_alarm_sound_path')
            : LocalStore().readString('custom_notification_sound_path');

        AestheticAudioService().previewSound(
          soundId: soundId,
          customPath: customPath,
          isAlarm: isAlarm,
        );
      }
    } catch (_) {}
  }

  void _dismiss() {
    if (!mounted || _currentToast == null) return;
    _life.stop();
    _animController.reverse().then((_) {
      if (mounted && _animController.isDismissed) {
        setState(() => _currentToast = null);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _life.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,
        if (_currentToast != null)
          Positioned(
            top: topPadding + 14,
            left: 0,
            right: 0,
            child: SanctuaryAnimatedNotificationCard(
              item: _currentToast!,
              entranceController: _animController,
              lifeController: _life,
              onDismiss: _dismiss,
              onAction: _currentToast!.onAction,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}
