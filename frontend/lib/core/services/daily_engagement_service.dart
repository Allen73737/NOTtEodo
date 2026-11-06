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
      'title': '🕯️ Evening Reflection & Peace',
      'message': 'Take 60 seconds to review what you conquered today. You made real progress.',
    },
    {
      'title': '✨ Tomorrow Starts Tonight',
      'message': 'Set your single most critical objective for tomorrow and rest peacefully.',
    },
  ];

  /// Schedules next 24-48 hours of dynamic, engaging notifications
  Future<void> scheduleDailyCadence({bool enabled = true}) async {
    if (!enabled) {
      await cancelAll();
      return;
    }

    final rand = Random();
    final now = DateTime.now();

    // 1. Morning Alignment (8:30 AM)
    final morningTime = _nextTime(now, 8, 30);
    final morning = _morningCopies[rand.nextInt(_morningCopies.length)];
    await DeviceNotificationService().scheduleReminder(
      id: 8801,
      title: morning['title']!,
      body: morning['message']!,
      scheduledTime: morningTime,
      channelId: 'notteodo_daily_engagement',
    );

    // 2. Midday Momentum (1:45 PM)
    final middayTime = _nextTime(now, 13, 45);
    final midday = _middayCopies[rand.nextInt(_middayCopies.length)];
    await DeviceNotificationService().scheduleReminder(
      id: 8802,
      title: midday['title']!,
      body: midday['message']!,
      scheduledTime: middayTime,
      channelId: 'notteodo_daily_engagement',
    );

    // 3. Streak Guardian (6:30 PM)
    final streakTime = _nextTime(now, 18, 30);
    final streak = _streakCopies[rand.nextInt(_streakCopies.length)];
    await DeviceNotificationService().scheduleReminder(
      id: 8803,
      title: streak['title']!,
      body: streak['message']!,
      scheduledTime: streakTime,
      channelId: 'notteodo_daily_engagement',
    );

    // 4. Night Reflection (9:45 PM)
    final eveningTime = _nextTime(now, 21, 45);
    final evening = _eveningCopies[rand.nextInt(_eveningCopies.length)];
    await DeviceNotificationService().scheduleReminder(
      id: 8804,
      title: evening['title']!,
      body: evening['message']!,
      scheduledTime: eveningTime,
      channelId: 'notteodo_daily_engagement',
    );
  }

  DateTime _nextTime(DateTime from, int hour, int minute) {
    var target = DateTime(from.year, from.month, from.day, hour, minute);
    if (target.isBefore(from)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  Future<void> cancelAll() async {
    for (final id in [8801, 8802, 8803, 8804]) {
      await DeviceNotificationService().cancelNotification(id);
    }
  }
}

