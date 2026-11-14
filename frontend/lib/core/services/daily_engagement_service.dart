import 'dart:math';
import 'device_notification_service.dart';

class DailyEngagementService {
  static final DailyEngagementService _instance = DailyEngagementService._internal();
  factory DailyEngagementService() => _instance;
  DailyEngagementService._internal();

  static const List<Map<String, String>> _morningCopies = [
    {
      'title': '🌅 Buongiorno, {curator} · Day {streak} Horizon',
      'message': 'Your canvas is pristine. 1 primary horizon defined now shields your morning from noise.',
    },
    {
      'title': '☀️ Morning Stillness · {curator}',
      'message': 'Before the world demands your attention, capture your singular intention for today.',
    },
    {
      'title': '☕ First Light Ritual · {curator}',
      'message': 'Great days are not accidents; they are architected. 2 minutes to define your standard.',
    },
    {
      'title': '🏛️ The Tuscan Dawn · Day {streak}',
      'message': 'Consistency is quiet mastery. Step into today with total calm and pristine clarity.',
    },
    {
      'title': '✨ Pristine Horizon · {curator}',
      'message': 'Yesterday is complete. Today\'s masterpiece is yours to shape in your sanctuary.',
    },
  ];

  static const List<Map<String, String>> _middayCopies = [
    {
      'title': '🎯 Midday Meridian · {curator}',
      'message': 'The sun is at its zenith. Half your waking hours remain — which high-leverage intention will you seal before dusk?',
    },
    {
      'title': '⏳ 3-Hour Cadence Check · {curator}',
      'message': 'Intentional pause: Step back from the screen, take 3 restorative breaths, and check in with your top priority.',
    },
    {
      'title': '⚡ Deep Focus Horizon · {curator}',
      'message': 'One deliberate block of deep work beats a day of fragmented busyness. Ready for a 25-minute sprint?',
    },
    {
      'title': '💎 Deliberate Action · {curator}',
      'message': 'Silence the non-essential. Protect what truly moves your needle today.',
    },
    {
      'title': '🌊 Midday Calibration · Day {streak}',
      'message': 'Review your morning gains. What single win will define the afternoon?',
    },
  ];

  static const List<Map<String, String>> _focusCopies = [
    {
      'title': '⚡ 25-Minute Focus Horizon · {curator}',
      'message': 'Set a timer, silence distractions, and immerse in deep flow. Your future self is cheering you on.',
    },
    {
      'title': '🧭 Sanctuary Gut Check · {curator}',
      'message': 'Is what you are doing right now moving the needle on your top goal? Realign in 30 seconds.',
    },
    {
      'title': '💎 Quality Over Quantity · {curator}',
      'message': 'One completed deep task beats ten half-finished ones. Pick your highest-leverage item and conquer it.',
    },
    {
      'title': '🌿 Mindful Reset · {curator}',
      'message': 'Stretch, hydrate, and breathe. A 60-second restorative pause supercharges your next hour of flow.',
    },
    {
      'title': '🎧 Deep Work Sanctuary · {curator}',
      'message': 'Enter the quiet zone. Block distraction and execute with calm Tuscan precision.',
    },
  ];

  static const List<Map<String, String>> _streakCopies = [
    {
      'title': '🛡️ Protect Your {streak}-Day Streak, {curator}',
      'message': 'Consistency is your moat. 60 seconds to log today\'s ritual keeps your flame blazing bright.',
    },
    {
      'title': '🔥 Day {streak} Momentum · {curator}',
      'message': 'You have built rare discipline. Don\'t let today slip into tomorrow — lock in your checkmark now.',
    },
    {
      'title': '👑 Mastery Through Continuity · {streak} Days',
      'message': 'Small daily rituals compound into extraordinary results. Extend your streak today in one tap.',
    },
    {
      'title': '⚡ The Standard You Set · {curator}',
      'message': 'Showing up when it\'s easy is common. Showing up today is what makes you formidable.',
    },
    {
      'title': '🏆 A Legacy of Daily Progress · Day {streak}',
      'message': 'Your {streak}-day momentum is proof of your focus. One tap to honor today\'s progress.',
    },
  ];

  static const List<Map<String, String>> _eveningCopies = [
    {
      'title': '🌙 Evening Horizon · Day {streak} Intact',
      'message': 'Well navigated today, {curator}. Unburden lingering thoughts into your vault and enter rest with total serenity.',
    },
    {
      'title': '🕯️ Twilight Recap & Gratitude · {curator}',
      'message': 'Celebrate what you conquered today. Honor your progress and let go of what wasn\'t finished.',
    },
    {
      'title': '🌌 The Quiet Hour · {curator}',
      'message': 'Tomorrow\'s clarity begins tonight. Note your #1 focus for tomorrow morning and rest deeply.',
    },
    {
      'title': '🛌 Total Cognitive Stillness · {curator}',
      'message': 'Your encrypted sanctuary holds your work safe. Close the day and rest without cognitive open loops.',
    },
    {
      'title': '✨ Dusk Reflection · Day {streak} Sealed',
      'message': 'Another day of intentional living written into your story. Sleep soundly, {curator}.',
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
    String displayName = '',
    int activeStreak = 0,
    String? alarmSound,
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

    final curator = displayName.trim().isNotEmpty ? displayName.trim() : 'Curator';
    final streak = activeStreak > 0 ? '$activeStreak' : '1';

    final rand = Random();
    for (int i = 0; i < times.length; i++) {
      final scheduledTime = times[i];
      final Map<String, String> template;

      if (i == 0) {
        template = _morningCopies[rand.nextInt(_morningCopies.length)];
      } else if (i == times.length - 1 && times.length > 1) {
        template = _eveningCopies[rand.nextInt(_eveningCopies.length)];
      } else {
        final h = scheduledTime.hour;
        if (h < 14) {
          template = _middayCopies[rand.nextInt(_middayCopies.length)];
        } else if (h >= 17) {
          template = _streakCopies[rand.nextInt(_streakCopies.length)];
        } else {
          template = _focusCopies[rand.nextInt(_focusCopies.length)];
        }
      }

      final title = template['title']!
          .replaceAll('{curator}', curator)
          .replaceAll('{streak}', streak);
      final body = template['message']!
          .replaceAll('{curator}', curator)
          .replaceAll('{streak}', streak);

      await DeviceNotificationService().scheduleReminder(
        id: 8801 + i,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        channelId: 'notteodo_daily_engagement',
        repeatDaily: true,
        soundId: alarmSound,
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
