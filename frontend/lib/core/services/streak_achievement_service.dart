import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../rewards/rewards_ledger.dart';
import '../state/app_settings.dart';
import '../utils/date_labels.dart';
import '../widgets/app_toast_engine.dart';
import 'device_notification_service.dart';
import 'sanctuary_supabase_service.dart';
import 'widget_sync_service.dart';

class StreakAchievementService {
  StreakAchievementService._();

  /// Automatically updates and validates the user's live daily streak.
  /// Guarantees Day 1 streak on first app open, shields streaks using Streak Freezes
  /// and schedules daily alerts. The day's streak screen and milestone badges are
  /// shown by the rewards host in the shell, which watches `lastActiveDate`.
  static Future<void> checkAndUpdateStreak(WidgetRef ref, BuildContext? context) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    final currentSettings = ref.read(appSettingsProvider);

    final today = DateLabels.dayKey(DateTime.now());
    final yesterday = DateLabels.dayKey(DateTime.now().subtract(const Duration(days: 1)));

    final lastDate = currentSettings.lastActiveDate;
    var streak = currentSettings.activeStreak;
    var longest = currentSettings.longestStreak;

    if (lastDate.isEmpty) {
      // Initialize last active date for the first time while honoring existing progress
      if (streak <= 0) streak = 1;
      if (longest < streak) longest = streak;
      notifier.setActiveStreak(streak);
      notifier.setLastActiveDate(today);
      notifier.setLongestStreak(longest);
    } else if (lastDate == today) {
      // Already active today; streak maintained!
      if (longest < streak) {
        longest = streak;
        notifier.setLongestStreak(longest);
      }
      if (context != null && context.mounted) {
        AppToastEngine().showToast(
          context,
          title: '🔥 Streak Secured for Today',
          message: '$streak consecutive days active! Keep the momentum alive.',
        );
      }
    } else if (lastDate == yesterday) {
      // Consecutive active day! Increment streak!
      streak += 1;
      if (streak > longest) longest = streak;
      notifier.setActiveStreak(streak);
      notifier.setLastActiveDate(today);
      notifier.setLongestStreak(longest);
    } else {
      // User missed one or more days! Check if Streak Freeze is available
      if (currentSettings.streakFreezesCount > 0) {
        // USE STREAK FREEZE TO SHIELD THE STREAK!
        notifier.useStreakFreeze(today);
        notifier.setLastActiveDate(today);
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
      }
    }

    // Milestones (Day 3, 7, 14, 30, 100) each reward a streak freeze; the badge
    // ceremony that announces them runs in the rewards host.
    for (final milestone in Badges.streakMilestones) {
      if (streak >= milestone && currentSettings.lastMilestoneCelebrated < milestone) {
        notifier.setLastMilestoneCelebrated(milestone);
        notifier.addStreakFreeze(1);
        break;
      }
    }

    // Sync live state to Android Home/Lock screen widget
    try {
      WidgetSyncService.syncStreakAndTasks(ref: ref);
    } catch (_) {}

    // Persist streak securely to Supabase cloud profile so it survives device reinstalls
    _syncStreakToCloud(
      streak: streak,
      longest: longest,
      lastDate: today,
      freezes: currentSettings.streakFreezesCount,
    );

    // Schedule personalized engagement alerts
    try {
      _schedulePeriodicPersonalizedEngagement(streak);
    } catch (_) {}
  }

  static void _syncStreakToCloud({
    required int streak,
    required int longest,
    required String lastDate,
    required int freezes,
  }) {
    try {
      final user = SanctuarySupabaseService().currentUser;
      if (user != null) {
        SanctuarySupabaseService().client?.auth.updateUser(
          UserAttributes(
            data: {
              'active_streak': streak,
              'longest_streak': longest,
              'last_active_date': lastDate,
              'streak_freezes_count': freezes,
            },
          ),
        );
      }
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
      {
        'delay': const Duration(hours: 12),
        'title': '🌅 Morning Alignment',
        'body': 'Set your daily cornerstone goal in NOTtEodo and command the day ahead.',
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

