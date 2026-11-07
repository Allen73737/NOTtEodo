import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_settings.dart';
import '../utils/date_labels.dart';
import '../widgets/app_toast_engine.dart';
import '../widgets/streak_milestone_celebration_dialog.dart';
import 'device_notification_service.dart';
import 'widget_sync_service.dart';

class StreakAchievementService {
  StreakAchievementService._();

  /// Automatically updates and validates the user's live daily streak.
  /// Guarantees Day 1 streak on first app open, shields streaks using Streak Freezes,
  /// triggers Duolingo-style milestone celebrations, and schedules daily alerts.
  static Future<void> checkAndUpdateStreak(WidgetRef ref, BuildContext? context) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final currentSettings = ref.read(appSettingsProvider);

    final today = DateLabels.dayKey(DateTime.now());
    final yesterday = DateLabels.dayKey(DateTime.now().subtract(const Duration(days: 1)));

    final lastDate = currentSettings.lastActiveDate;
    var streak = currentSettings.activeStreak;
    var longest = currentSettings.longestStreak;

    // Purge legacy hardcoded 18d mock streak if unearned or legacy
    if (streak == 18 && (longest <= 1 || lastDate.isEmpty)) {
      streak = 1;
      longest = 1;
      notifier.setActiveStreak(1);
      notifier.setLongestStreak(1);
    }

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
      // User missed one or more days! Check if Streak Freeze is available
      if (currentSettings.streakFreezesCount > 0) {
        // USE STREAK FREEZE TO SHIELD THE STREAK!
        notifier.useStreakFreeze(today);
        notifier.setLastActiveDate(today);
        final remainingFreezes = currentSettings.streakFreezesCount - 1;

        if (context != null && context.mounted) {
          AppToastEngine().showToast(
            context,
            title: '❄️ Streak Freeze Activated!',
            message: 'Your $streak-day streak was protected while you were away! ($remainingFreezes left)',
          );
        }
        try {
          DeviceNotificationService().showSystemNotification(
            title: '❄️ Streak Freeze Activated!',
            message: 'Your $streak-day streak was shielded from breaking! Keep the momentum alive today.',
            channelId: 'notteodo_daily_engagement',
          );
        } catch (_) {}
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
    }

    // Check for Duolingo-style celebratory milestone unlocks (Day 3, 7, 14, 30, 100)
    const milestones = [3, 7, 14, 30, 100];
    for (final milestone in milestones) {
      if (streak >= milestone && currentSettings.lastMilestoneCelebrated < milestone) {
        notifier.setLastMilestoneCelebrated(milestone);
        notifier.addStreakFreeze(1); // Reward a bonus streak freeze!
        final updatedFreezes = ref.read(appSettingsProvider).streakFreezesCount;

        if (context != null && context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              StreakMilestoneCelebrationDialog.show(
                context,
                milestone: milestone,
                freezesAvailable: updatedFreezes,
              );
            }
          });
        }
        break;
      }
    }

    // Sync live state to Android Home/Lock screen widget
    try {
      WidgetSyncService.syncStreakAndTasks(ref: ref);
    } catch (_) {}

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

