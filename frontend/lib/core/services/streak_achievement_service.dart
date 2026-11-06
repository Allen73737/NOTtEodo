import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_settings.dart';
import '../utils/date_labels.dart';
import '../widgets/app_toast_engine.dart';
import 'device_notification_service.dart';

class StreakAchievementService {
  StreakAchievementService._();

  /// Automatically updates and validates the user's live daily streak.
  /// Guarantees Day 1 streak on first app open, increments on consecutive days,
  /// and schedules motivating personalized engagement alerts.
  static Future<void> checkAndUpdateStreak(WidgetRef ref, BuildContext? context) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final currentSettings = ref.read(appSettingsProvider);

    final today = DateLabels.dayKey(DateTime.now());
    final yesterday = DateLabels.dayKey(DateTime.now().subtract(const Duration(days: 1)));

    final lastDate = currentSettings.lastActiveDate;
    var streak = currentSettings.activeStreak;
    var longest = currentSettings.longestStreak;

    if (lastDate.isEmpty || streak <= 0) {
      // First time entering the sanctuary!
      streak = 1;
      longest = 1;
      notifier.setActiveStreak(1);
      notifier.setLastActiveDate(today);
      notifier.setLongestStreak(1);

      if (context != null && context.mounted) {
        AppToastEngine().showToast(
          context,
          title: '🔥 Day 1 Streak Started',
          message: 'Welcome to NOTtEodo! Complete a daily check-in to keep momentum.',
        );
      }
    } else if (lastDate == today) {
      // Already active today; streak maintained!
    } else if (lastDate == yesterday) {
      // Consecutive active day! Increment streak!
      streak += 1;
      if (streak > longest) longest = streak;
      notifier.setActiveStreak(streak);
      notifier.setLastActiveDate(today);
      notifier.setLongestStreak(longest);

      if (context != null && context.mounted) {
        AppToastEngine().showToast(
          context,
          title: '🔥 $streak-Day Streak Unlocked!',
          message: 'Your sanctuary momentum is protected.',
        );
      }
    } else {
      // Streak broken; reset back to day 1 fresh start
      streak = 1;
      notifier.setActiveStreak(1);
      notifier.setLastActiveDate(today);

      if (context != null && context.mounted) {
        AppToastEngine().showToast(
          context,
          title: '🔥 Day 1 Streak Started',
          message: 'A fresh chapter begins today.',
        );
      }
    }

    // Schedule 3-hour personalized Duolingo-style alerts
    try {
      await DeviceNotificationService().requestPermission();
      _schedulePeriodicPersonalizedEngagement(streak);
    } catch (_) {}
  }

  static Future<void> _schedulePeriodicPersonalizedEngagement(int streak) async {
    final now = DateTime.now();

    final reminders = [
      {
        'delay': const Duration(hours: 3),
        'title': '🔥 Streak Guard: $streak Days Strong!',
        'body': 'Keep your NOTtEodo momentum alive! Take 60 seconds to review your priorities.',
      },
      {
        'delay': const Duration(hours: 6),
        'title': '⚡ Mindful Check-in',
        'body': 'Have you logged your habits or thoughts today? Your sanctuary is waiting.',
      },
      {
        'delay': const Duration(hours: 9),
        'title': '🌙 Evening Reflection',
        'body': 'Wind down and clear your mind with a 2-minute journal reflection before bed.',
      },
    ];

    for (int i = 0; i < reminders.length; i++) {
      final item = reminders[i];
      final targetTime = now.add(item['delay'] as Duration);
      final id = 9000 + i;
      await DeviceNotificationService().scheduleReminder(
        id: id,
        title: item['title'] as String,
        body: item['body'] as String,
        scheduledTime: targetTime,
        channelId: 'notteodo_daily_engagement',
      );
    }
  }
}

