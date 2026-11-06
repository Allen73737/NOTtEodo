import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_store.dart';
import '../services/sanctuary_supabase_service.dart';

enum NotificationCategory {
  all,
  reminder,
  dailyEngagement,
  alarm,
  system,
  aiAssistant,
  security,
}

extension NotificationCategoryLabel on NotificationCategory {
  String get label => switch (this) {
        NotificationCategory.all => 'All',
        NotificationCategory.reminder => 'Due Reminders',
        NotificationCategory.dailyEngagement => 'Daily Engagement',
        NotificationCategory.alarm => 'Alarms & Chimes',
        NotificationCategory.system => 'System & Sync',
        NotificationCategory.aiAssistant => 'Nodo AI',
        NotificationCategory.security => 'Security & Vault',
      };
}

class NotificationLogEntry {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final String channel; // 'Device Notification Bar', 'In-App Animated Banner', 'Alarm Escapement'
  final String userIdentifier; // e.g. user email or 'Local Sanctuary User'
  final bool isRead;
  final String? targetModule; // e.g. 'tasks', 'events', 'notes', 'habits', 'expenses'

  const NotificationLogEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    required this.channel,
    required this.userIdentifier,
    this.isRead = false,
    this.targetModule,
  });

  NotificationLogEntry copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationCategory? category,
    String? channel,
    String? userIdentifier,
    bool? isRead,
    String? targetModule,
  }) {
    return NotificationLogEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      channel: channel ?? this.channel,
      userIdentifier: userIdentifier ?? this.userIdentifier,
      isRead: isRead ?? this.isRead,
      targetModule: targetModule ?? this.targetModule,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'category': category.name,
        'channel': channel,
        'userIdentifier': userIdentifier,
        'isRead': isRead,
        'targetModule': targetModule,
      };

  factory NotificationLogEntry.fromJson(Map<String, dynamic> j) {
    NotificationCategory cat = NotificationCategory.system;
    try {
      final catName = j['category'] as String?;
      if (catName != null) {
        cat = NotificationCategory.values.firstWhere(
          (c) => c.name == catName,
          orElse: () => NotificationCategory.system,
        );
      }
    } catch (_) {}

    DateTime time = DateTime.now();
    try {
      if (j['timestamp'] != null) {
        time = DateTime.parse(j['timestamp'] as String);
      }
    } catch (_) {}

    return NotificationLogEntry(
      id: j['id'] as String? ?? 'notif_${DateTime.now().microsecondsSinceEpoch}',
      title: j['title'] as String? ?? 'Notification',
      message: j['message'] as String? ?? '',
      timestamp: time,
      category: cat,
      channel: j['channel'] as String? ?? 'In-App Animated Banner',
      userIdentifier: j['userIdentifier'] as String? ?? 'Local Sanctuary User',
      isRead: j['isRead'] as bool? ?? false,
      targetModule: j['targetModule'] as String?,
    );
  }
}

/// Global helper for dispatching notification log records from any service or UI component.
class NotificationLogger {
  static const String storageKey = 'notification_logs';

  static String resolveActiveUser() {
    final user = SanctuarySupabaseService().currentUser;
    if (user != null && user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }
    return 'Local Sanctuary User';
  }

  static void record({
    required String title,
    required String message,
    NotificationCategory category = NotificationCategory.system,
    String channel = 'In-App Animated Banner',
    String? userIdentifier,
    String? targetModule,
  }) {
    final user = userIdentifier ?? resolveActiveUser();
    final entry = NotificationLogEntry(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${(100 + DateTime.now().microsecond % 900)}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      channel: channel,
      userIdentifier: user,
      isRead: false,
      targetModule: targetModule,
    );

    final current = LocalStore().readList(storageKey, NotificationLogEntry.fromJson) ?? _seed();
    final updated = [entry, ...current.take(199)];
    LocalStore().writeList(storageKey, updated.map((e) => e.toJson()).toList());
  }

  static List<NotificationLogEntry> _seed() {
    final now = DateTime.now();
    final activeUser = resolveActiveUser();

    return [
      NotificationLogEntry(
        id: 'seed_1',
        title: '🌅 Rise & Command the Day',
        message: 'A clean slate awaits. Knock out your #1 priority early and feel unstoppable!',
        timestamp: now.subtract(const Duration(minutes: 42)),
        category: NotificationCategory.dailyEngagement,
        channel: 'Device Notification Bar',
        userIdentifier: activeUser,
        isRead: false,
        targetModule: 'tasks',
      ),
      NotificationLogEntry(
        id: 'seed_2',
        title: '🎯 High-Priority Task Due',
        message: 'Complete Quarterly Life Synthesis is scheduled for today.',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
        category: NotificationCategory.reminder,
        channel: 'Device Notification Bar',
        userIdentifier: activeUser,
        isRead: false,
        targetModule: 'tasks',
      ),
      NotificationLogEntry(
        id: 'seed_3',
        title: '⚡ Nodo AI Memory Synchronized',
        message: 'Nodo has integrated your recent journal entries and wardrobe palette.',
        timestamp: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.aiAssistant,
        channel: 'In-App Animated Banner',
        userIdentifier: activeUser,
        isRead: true,
        targetModule: 'notes',
      ),
      NotificationLogEntry(
        id: 'seed_4',
        title: '🔥 Don\'t Break Your Habit Chain!',
        message: 'Your 7-day streak is on the line today! One tap to log your daily progress.',
        timestamp: now.subtract(const Duration(hours: 18)),
        category: NotificationCategory.dailyEngagement,
        channel: 'Device Notification Bar',
        userIdentifier: 'Local Sanctuary User',
        isRead: true,
        targetModule: 'habits',
      ),
      NotificationLogEntry(
        id: 'seed_5',
        title: 'Horology Escapement Alarm',
        message: 'Swiss escapement cadence chime. Time for evening meditation and stillness.',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        category: NotificationCategory.alarm,
        channel: 'Alarm Escapement',
        userIdentifier: 'Local Sanctuary User',
        isRead: true,
      ),
      NotificationLogEntry(
        id: 'seed_6',
        title: 'Sanctuary Cryptographic Vault Locked',
        message: '4-digit biometric vault engaged. On-device zero-knowledge cipher active.',
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        category: NotificationCategory.security,
        channel: 'In-App Animated Banner',
        userIdentifier: 'Admin Root',
        isRead: true,
        targetModule: 'settings',
      ),
    ];
  }
}

/// State notifier managing live notification history and persistence.
class NotificationLogNotifier extends StateNotifier<List<NotificationLogEntry>> {
  NotificationLogNotifier()
      : super(LocalStore().readList(
                NotificationLogger.storageKey,
                NotificationLogEntry.fromJson,
              ) ??
              NotificationLogger._seed()) {
    LocalStore().addWriteListener(_onStoreWrite);
  }

  void _onStoreWrite(String key) {
    if (key == NotificationLogger.storageKey) {
      final updated = LocalStore().readList(
        NotificationLogger.storageKey,
        NotificationLogEntry.fromJson,
      );
      if (updated != null) {
        state = updated;
      }
    }
  }

  void _persist(List<NotificationLogEntry> next) {
    state = next;
    LocalStore().writeList(
      NotificationLogger.storageKey,
      next.map((e) => e.toJson()).toList(),
    );
  }

  void logNotification({
    required String title,
    required String message,
    NotificationCategory category = NotificationCategory.system,
    String channel = 'In-App Animated Banner',
    String? userIdentifier,
    String? targetModule,
  }) {
    final user = userIdentifier ?? NotificationLogger.resolveActiveUser();
    final entry = NotificationLogEntry(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${(100 + DateTime.now().microsecond % 900)}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      channel: channel,
      userIdentifier: user,
      isRead: false,
      targetModule: targetModule,
    );
    _persist([entry, ...state.take(199)]);
  }

  void markAsRead(String id) {
    _persist(state.map((e) => e.id == id ? e.copyWith(isRead: true) : e).toList());
  }

  void markAllAsRead({String? user}) {
    _persist(state.map((e) {
      if (user == null || user == 'All Users' || e.userIdentifier == user) {
        return e.copyWith(isRead: true);
      }
      return e;
    }).toList());
  }

  void deleteEntry(String id) {
    _persist(state.where((e) => e.id != id).toList());
  }

  void clearAll({String? user}) {
    if (user == null || user == 'All Users') {
      _persist([]);
    } else {
      _persist(state.where((e) => e.userIdentifier != user).toList());
    }
  }

  int get unreadCount => state.where((e) => !e.isRead).length;

  int unreadCountForUser(String user) =>
      state.where((e) => !e.isRead && (user == 'All Users' || e.userIdentifier == user)).length;

  List<String> get availableUsers {
    final set = <String>{};
    final active = NotificationLogger.resolveActiveUser();
    set.add(active);
    for (final e in state) {
      if (e.userIdentifier.isNotEmpty) set.add(e.userIdentifier);
    }
    return set.toList();
  }
}

final notificationLogsProvider =
    StateNotifierProvider<NotificationLogNotifier, List<NotificationLogEntry>>((ref) {
  return NotificationLogNotifier();
});
