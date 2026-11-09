import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../state/app_settings.dart';
import 'local_store.dart';
import '../state/sanctuary_state.dart';

/// Syncs live streak momentum, pending tasks count, and focus state
/// to Android Home Screen and Lock Screen / AOD Widgets.
class WidgetSyncService {
  WidgetSyncService._();

  static const String appGroupId = 'group.com.notteodo.notteodo';
  static const String androidWidgetName = 'NotteodoWidgetProvider';

  /// Broadcasts the user's latest streak and active task count to the OS widget.
  static Future<void> syncStreakAndTasks({required WidgetRef ref}) async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      final settings = ref.read(appSettingsProvider);
      final tasks = ref.read(tasksProvider);
      final pendingCount = tasks.where((t) => !t.completed).length;
      final streak = settings.activeStreak;

      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<int>('streak_count', streak);
      await HomeWidget.saveWidgetData<String>('streak_text', '🔥 $streak Day Streak');
      await HomeWidget.saveWidgetData<int>('pending_tasks', pendingCount);
      await HomeWidget.saveWidgetData<String>('tasks_text', '$pendingCount Tasks Pending');
      await HomeWidget.saveWidgetData<String>('daily_quote', 'Make today deliberate.');

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
    } catch (_) {}
  }

  /// Switches the live widget between the editorial and card layouts.
  static Future<void> setStyle(String cardStyle) async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>('widget_style', cardStyle);
      await HomeWidget.updateWidget(name: androidWidgetName, androidName: androidWidgetName);
    } catch (_) {}
  }

  /// Direct method to update widget values without requiring a WidgetRef.
  static Future<void> updateValues({
    required int streak,
    required int pendingTasks,
    String? quote,
    List<String> nextTasks = const [],
  }) async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      await HomeWidget.setAppGroupId(appGroupId);
      // The live widget follows the app's view and lists what is next.
      await HomeWidget.saveWidgetData<String>('widget_style', LocalStore().readString('card_style') ?? 'editorial');
      await HomeWidget.saveWidgetData<String>('next_tasks', nextTasks.take(3).join('\n'));
      await HomeWidget.saveWidgetData<int>('streak_count', streak);
      await HomeWidget.saveWidgetData<String>('streak_text', '🔥 $streak Day Streak');
      await HomeWidget.saveWidgetData<int>('pending_tasks', pendingTasks);
      await HomeWidget.saveWidgetData<String>('tasks_text', '$pendingTasks Tasks Pending');
      if (quote != null) {
        await HomeWidget.saveWidgetData<String>('daily_quote', quote);
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
    } catch (_) {}
  }
}
