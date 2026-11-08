import 'dart:math';
import 'device_notification_service.dart';

class DailyEngagementService {
  static final DailyEngagementService _instance = DailyEngagementService._internal();
  factory DailyEngagementService() => _instance;
  DailyEngagementService._internal();

  static const List<Map<String, String>> _morningCopies = [
    {
      'title': '🌅 Rise & Command the Day',
      'message': 'A clean slate awaits. Knock out your #1 priority early and feel unstoppable!',
    },
    {
      'title': '⚡ 2 Minutes to Total Clarity',
      'message': 'Two minutes aligning your tasks right now saves two hours of reactive chaos.',
    },
    {
      'title': '☕ Morning Momentum Awaits',
      'message': 'Your day\'s trajectory is set before noon. What is today\'s cornerstone goal?',
    },
  ];

  static const List<Map<String, String>> _middayCopies = [
    {
      'title': '🎯 Halfway Through the Sun',
      'message': 'How is your top focus moving? Check off one lingering item and crush the afternoon.',
    },
    {
      'title': '🚀 Midday Power Pulse',
      'message': 'Break through the afternoon dip. Revisit your daily plan and claim the win.',
    },
    {
      'title': '💡 Quick Headspace Flush',
      'message': 'Mind racing? Drop raw thoughts into a fast note and return to deep focus.',
    },
  ];

  static const List<Map<String, String>> _focusCopies = [
    {
      'title': '⚡ Micro-Focus Sprint',
      'message': 'Dedicate 15 minutes of uninterrupted focus to your most pivotal item.',
    },
    {
      'title': '🧭 True North Alignment',
      'message': 'Pause for 10 seconds. Is your current effort aligned with your highest daily priority?',
    },
    {
      'title': '💎 High-Leverage Mastery',
      'message': 'Cut away minor distractions. One completed cornerstone task beats ten half-done chores.',
    },
    {
      'title': '☕ Mindful Energy Check',
      'message': 'Hydrate, adjust your posture, and channel intentional energy into your afternoon.',
    },
  ];

  static const List<Map<String, String>> _streakCopies = [
    {
      'title': '🔥 Don\'t Break Your Habit Chain!',
      'message': 'Your streak is on the line today! One tap to log your daily progress and keep the fire burning.',
    },
    {
      'title': '🛡️ Streak Protector Alert',
      'message': 'You\'ve built incredible momentum this week. Finish your evening habit now!',
    },
    {
      'title': '⚡ Consistency Conquers Everything',
      'message': 'Mastery is doing it even on ordinary days. Lock in today\'s habit check-in.',
    },
  ];

  static const List<Map<String, String>> _eveningCopies = [
    {
      'title': '🌙 Clear Your Headspace for Sleep',
      'message': 'Unload tomorrow\'s to-dos from your brain into NOTtEodo. Sleep deeply with a tranquil mind.',
    },
    {
      'title': '🕯️ Evening Reflection & Daily Recap',
      'message': 'Take 60 seconds to review what you conquered today. You made real progress.',
    },
    {
      'title': '✨ Tomorrow Starts Tonight',
      'message': 'Set your single most critical objective for tomorrow and rest peacefully.',
    },
  ];

  /// Computes deterministic notification times given cadence and quiet hours constraints.
  static List<DateTime> calculateScheduleTimes({
    required DateTime referenceTime,
    required int cadenceHours,
    required String morningTimeStr,
    required String eveningTimeStr,
    bool quietHoursEnabled = false,
    String quietHoursStart = '22:00',
    String quietHoursEnd = '07:00',
  }) {
    final morningParts = _parseHourMinute(morningTimeStr, defaultHour: 9, defaultMinute: 30);
    final eveningParts = _parseHourMinute(eveningTimeStr, defaultHour: 21, defaultMinute: 30);

    // If cadence is 24 or 0 (Once Daily), schedule only morning briefing
    if (cadenceHours <= 0 || cadenceHours >= 24) {
      if (quietHoursEnabled && _isInQuietHours(morningParts.$1, morningParts.$2, quietHoursStart, quietHoursEnd)) {
        return const [];
      }
      return [_nextTime(referenceTime, morningParts.$1, morningParts.$2)];
    }

    final morningMin = morningParts.$1 * 60 + morningParts.$2;
    int eveningMin = eveningParts.$1 * 60 + eveningParts.$2;
    if (eveningMin <= morningMin) {
      eveningMin += 24 * 60;
    }

    final stepMin = cadenceHours * 60;
    final plannedMinutes = <int>[];

    for (int m = morningMin; m < eveningMin; m += stepMin) {
      plannedMinutes.add(m);
    }

    // Ensure evening reflection is included at the end
    if (plannedMinutes.isEmpty || (eveningMin - plannedMinutes.last) >= 45) {
      plannedMinutes.add(eveningMin);
    } else {
      // If within 45 mins of evening, snap final slot to exact evening reflection time
      plannedMinutes[plannedMinutes.length - 1] = eveningMin;
    }

    final results = <DateTime>[];
    for (final m in plannedMinutes) {
      final hour = (m ~/ 60) % 24;
      final minute = m % 60;

      if (quietHoursEnabled && _isInQuietHours(hour, minute, quietHoursStart, quietHoursEnd)) {
        continue;
      }

      results.add(_nextTime(referenceTime, hour, minute));
    }

    return results;
  }

  static bool _isInQuietHours(int hour, int minute, String startStr, String endStr) {
    final startParts = _parseHourMinute(startStr, defaultHour: 22, defaultMinute: 0);
    final endParts = _parseHourMinute(endStr, defaultHour: 7, defaultMinute: 0);

    final currentMin = hour * 60 + minute;
    final startMin = startParts.$1 * 60 + startParts.$2;
    final endMin = endParts.$1 * 60 + endParts.$2;

    if (startMin < endMin) {
      // Quiet hours do NOT span midnight (e.g. 13:00 to 15:00)
      return currentMin >= startMin && currentMin < endMin;
    } else if (startMin > endMin) {
      // Quiet hours span midnight (e.g. 22:00 to 07:00)
      return currentMin >= startMin || currentMin < endMin;
    } else {
      // start == end, disabled or 0 length
      return false;
    }
  }

  /// Schedules next 24-48 hours of dynamic, engaging notifications based on user-chosen cadence.
  /// Times are automatically evaluated against the user device's local timezone (e.g., IST).
  Future<void> scheduleDailyCadence({
    bool enabled = true,
    int cadenceHours = 3,
    String morningTimeStr = '09:30',
    String eveningTimeStr = '21:30',
    bool quietHoursEnabled = false,
    String quietHoursStart = '22:00',
    String quietHoursEnd = '07:00',
  }) async {
    // 1. Clear any prior active engagement notifications
    await cancelAll();

    if (!enabled) return;

    final now = DateTime.now();
    final times = calculateScheduleTimes(
      referenceTime: now,
      cadenceHours: cadenceHours,
      morningTimeStr: morningTimeStr,
      eveningTimeStr: eveningTimeStr,
      quietHoursEnabled: quietHoursEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
    );

    final rand = Random();
    for (int i = 0; i < times.length; i++) {
      final scheduledTime = times[i];
      final Map<String, String> copy;

      if (i == 0) {
        copy = _morningCopies[rand.nextInt(_morningCopies.length)];
      } else if (i == times.length - 1 && times.length > 1) {
        copy = _eveningCopies[rand.nextInt(_eveningCopies.length)];
      } else {
        final h = scheduledTime.hour;
        if (h < 14) {
          copy = _middayCopies[rand.nextInt(_middayCopies.length)];
        } else if (h >= 17) {
          copy = _streakCopies[rand.nextInt(_streakCopies.length)];
        } else {
          copy = _focusCopies[rand.nextInt(_focusCopies.length)];
        }
      }

      await DeviceNotificationService().scheduleReminder(
        id: 8801 + i,
        title: copy['title']!,
        body: copy['message']!,
        scheduledTime: scheduledTime,
        channelId: 'notteodo_daily_engagement',
        repeatDaily: true,
      );
    }
  }

  static (int, int) _parseHourMinute(String timeStr, {required int defaultHour, required int defaultMinute}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0].trim());
        final m = int.tryParse(parts[1].trim());
        if (h != null && m != null) {
          return (h, m);
        }
      }
    } catch (_) {}
    return (defaultHour, defaultMinute);
  }

  static DateTime _nextTime(DateTime from, int hour, int minute) {
    var target = DateTime(from.year, from.month, from.day, hour, minute);
    if (target.isBefore(from)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  Future<void> cancelAll() async {
    for (int id = 8801; id <= 8850; id++) {
      await DeviceNotificationService().cancelNotification(id);
    }
  }
}
