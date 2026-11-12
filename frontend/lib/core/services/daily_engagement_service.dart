import 'dart:math';
import 'device_notification_service.dart';

class DailyEngagementService {
  static final DailyEngagementService _instance = DailyEngagementService._internal();
  factory DailyEngagementService() => _instance;
  DailyEngagementService._internal();

  static const List<Map<String, String>> _morningCopies = [
    {
      'title': '🌅 Good Morning, Champion!',
      'message': 'Your blank canvas is waiting. What\'s the ONE thing that would make today amazing?',
    },
    {
      'title': '☀️ Rise & Shine — Your Day Begins!',
      'message': 'Top performers plan first, react never. Take 2 min to set your intentions!',
    },
    {
      'title': '☕ Fresh Start, Fresh Energy!',
      'message': 'Yesterday is done. Today\'s story is yours to write. What\'s your opening chapter?',
    },
    {
      'title': '🚀 Ready to Launch Your Day?',
      'message': 'Quick: pick your #1 priority, mark it, and watch your confidence soar!',
    },
    {
      'title': '✨ A New Day, A New Opportunity!',
      'message': 'The most productive people start small and finish strong. What\'s your first move?',
    },
  ];

  static const List<Map<String, String>> _middayCopies = [
    {
      'title': '🎯 Halftime Check-In!',
      'message': 'You\'re crushing it! Quick peek at your tasks — what can you knock out before lunch ends?',
    },
    {
      'title': '🚀 Afternoon Power-Up!',
      'message': 'The post-lunch dip is real. Beat it! Review one task and ride the momentum wave 🌊',
    },
    {
      'title': '💡 Brain Dump Time!',
      'message': 'Mind buzzing with ideas? Drop them into a quick note before they vanish. Future you will be grateful!',
    },
    {
      'title': '⏰ Midday Momentum Check!',
      'message': 'How\'s your #1 priority progressing? A quick glance keeps you ahead of the curve.',
    },
  ];

  static const List<Map<String, String>> _focusCopies = [
    {
      'title': '⚡ 15-Minute Focus Sprint!',
      'message': 'Set a timer, silence distractions, conquer ONE thing. You\'ve got this! 💪',
    },
    {
      'title': '🧭 Are You On Track?',
      'message': 'Quick gut check: is what you\'re doing right now moving the needle on your top goal?',
    },
    {
      'title': '💎 Quality Over Quantity!',
      'message': 'One completed deep task beats ten half-finished ones. Pick your highest-leverage item!',
    },
    {
      'title': '☕ Energy Recharge Moment!',
      'message': 'Stretch, hydrate, breathe. A 60-second reset supercharges your next hour of focus.',
    },
    {
      'title': '🎧 Deep Work Mode Activated!',
      'message': 'Block 25 minutes for pure, uninterrupted work. Your future self is cheering you on!',
    },
  ];

  static const List<Map<String, String>> _streakCopies = [
    {
      'title': '🔥 Keep That Flame Blazing!',
      'message': 'Your streak is on fire today! One tap to check off your habit and keep your momentum alive 🏆',
    },
    {
      'title': '🛡️ Protect Your Hard-Earned Streak!',
      'message': 'You\'ve built incredible consistency! Don\'t let today slip by — log your ritual now ✨',
    },
    {
      'title': '⚡ Champions Show Up Every Day',
      'message': 'Even 2 minutes counts toward greatness. Keep your winning habit streak alive!',
    },
    {
      'title': '🔥 Your Streak Is Counting On You!',
      'message': 'You\'re only one checkmark away from extending your streak. Lock it in right now! 🎯',
    },
  ];

  static const List<Map<String, String>> _eveningCopies = [
    {
      'title': '🌙 Mind Clear, Sleep Sound',
      'message': 'Empty today\'s loose thoughts into NOTtEodo so you can rest with total peace of mind 🛌',
    },
    {
      'title': '🕯️ Celebrate Today\'s Wins!',
      'message': 'Take 60 seconds to review what you conquered today. You made real progress, be proud! 🌟',
    },
    {
      'title': '✨ Tomorrow\'s Success Starts Tonight',
      'message': 'Jot down your #1 focus for tomorrow morning and wake up with unstoppable clarity! 🚀',
    },
    {
      'title': '🌌 Evening Wind-Down & Reflection',
      'message': 'Unclutter your mind, check off completed tasks, and savor a peaceful evening ☕',
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
