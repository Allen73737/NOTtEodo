import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/editorial_mode.dart';
import 'cards_ceremony.dart';
import 'editorial_ceremony.dart';
import 'reward_bus.dart';
import 'rewards_ledger.dart';

/// Everything the day's streak screen shows.
class StreakMoment {
  final int streak;
  final int longest;

  /// The very first open: the screen doubles as the welcome.
  final bool firstDay;

  /// The streak lapsed and today starts again at one.
  final bool restarted;

  /// A streak freeze covered the missed days.
  final bool freezeUsed;
  final int freezesLeft;

  /// Seven days of the current week from the user's first weekday; true where active.
  final List<bool> week;
  final List<String> weekLetters;
  final int todayIndex;

  const StreakMoment({
    required this.streak,
    required this.longest,
    required this.firstDay,
    required this.restarted,
    required this.freezeUsed,
    required this.freezesLeft,
    required this.week,
    required this.weekLetters,
    required this.todayIndex,
  });

  /// Builds the week strip: the last [streak] days up to today are lit.
  factory StreakMoment.of({
    required int streak,
    required int longest,
    required bool firstDay,
    required bool freezeUsed,
    required int freezesLeft,
    required int firstDayOfWeek,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final todayIndex = (today.weekday - firstDayOfWeek + 7) % 7;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return StreakMoment(
      streak: streak,
      longest: longest,
      firstDay: firstDay,
      restarted: !firstDay && streak == 1 && longest > 1,
      freezeUsed: freezeUsed,
      freezesLeft: freezesLeft,
      week: [for (var i = 0; i < 7; i++) i <= todayIndex && todayIndex - i < streak],
      weekLetters: [for (var i = 0; i < 7; i++) letters[(firstDayOfWeek - 1 + i) % 7]],
      todayIndex: todayIndex,
    );
  }

  String get kicker {
    if (firstDay) return 'Welcome to NOTtEodo';
    if (freezeUsed) return 'Streak protected';
    if (restarted) return 'A new chapter';
    return 'Day streak';
  }

  /// One line under the number, in the voice of the app.
  String get line {
    if (firstDay) return 'Every good habit begins on a single page. This one is yours.';
    if (freezeUsed) {
      return 'A streak freeze kept your $streak days safe while you were away'
          '${freezesLeft > 0 ? ' · $freezesLeft left' : ''}.';
    }
    if (restarted) return 'Your longest run was $longest days. Today the count begins again.';
    if (streak >= 100) return 'A hundred days and more. This is simply who you are now.';
    if (streak >= 30) return 'A month and beyond, every single day. Remarkable.';
    if (streak >= 14) return 'Two weeks unbroken. Consistency has become instinct.';
    if (streak >= 7) return 'A full week, every day. Keep the flame alive.';
    if (streak >= 3) return 'Momentum is building. Come back tomorrow to keep it.';
    if (streak == 2) return 'Two days in a row. The beginning of something.';
    return 'Show up again tomorrow and watch the number grow.';
  }
}

/// Today's goal was just met.
class GoalMoment {
  final int count;
  final int goal;
  final int goalDays;
  final int streak;

  const GoalMoment({required this.count, required this.goal, required this.goalDays, required this.streak});
}

IconData rewardActionIcon(RewardAction a) => switch (a) {
      RewardAction.note => LucideIcons.penLine,
      RewardAction.task => LucideIcons.listTodo,
      RewardAction.taskDone => LucideIcons.checkCheck,
      RewardAction.event => LucideIcons.calendarDays,
      RewardAction.habit || RewardAction.habitDone => LucideIcons.repeat,
      RewardAction.journal => LucideIcons.bookOpen,
      RewardAction.expense => LucideIcons.wallet,
      RewardAction.trip => LucideIcons.plane,
      RewardAction.outfit => LucideIcons.shirt,
      RewardAction.pin => LucideIcons.pin,
      RewardAction.shopping => LucideIcons.shoppingBag,
    };

/// Presents rewards in the current view style: quiet and typographic in the editorial
/// view, animated and dimensional in the card view.
abstract final class RewardCeremony {
  static Future<void> streak(BuildContext context, StreakMoment m) =>
      _present(context, EditorialMode.active ? EditorialStreakPage(moment: m) : CardsStreakPage(moment: m));

  static Future<void> badge(BuildContext context, BadgeDef badge, {String? reward}) => _present(
        context,
        EditorialMode.active ? EditorialBadgePage(badge: badge, reward: reward) : CardsBadgePage(badge: badge, reward: reward),
      );

  static Future<void> goal(BuildContext context, GoalMoment m) =>
      _present(context, EditorialMode.active ? EditorialGoalPage(moment: m) : CardsGoalPage(moment: m));

  /// A small, self-dismissing note of progress toward today's goal.
  static void progress(BuildContext context, RewardOutcome o) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _clearToast();
    late final OverlayEntry entry;
    void done() {
      if (_toast == entry) _toast = null;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => EditorialMode.active
          ? EditorialProgressToast(outcome: o, onDone: done)
          : CardsProgressToast(outcome: o, onDone: done),
    );
    _toast = entry;
    overlay.insert(entry);
  }

  static OverlayEntry? _toast;

  static void _clearToast() {
    final t = _toast;
    _toast = null;
    if (t != null && t.mounted) t.remove();
  }

  /// Pushes a ceremony page. Each page runs its own entrance, so the route itself
  /// only cross-fades; editorial pages are opaque paper, card pages float over a scrim.
  static Future<void> _present(BuildContext context, Widget page) {
    _clearToast();
    return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: EditorialMode.active,
      barrierDismissible: false,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    ));
  }
}
