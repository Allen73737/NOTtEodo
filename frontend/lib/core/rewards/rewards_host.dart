import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editorial/view_style_chooser.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'reward_bus.dart';
import 'reward_ceremony.dart';
import 'rewards_ledger.dart';

/// Sits around the app shell and turns progress into moments: the day's streak on the
/// first open of each day (the welcome on the very first), badges as they are earned,
/// the daily goal when it is met, and a small progress note for everything else.
///
/// Ceremonies queue and play one at a time, so a welcome, its badge and a streak
/// milestone arrive in order rather than on top of each other.
class RewardsHost extends ConsumerStatefulWidget {
  final Widget child;
  const RewardsHost({super.key, required this.child});

  @override
  ConsumerState<RewardsHost> createState() => _RewardsHostState();
}

class _RewardsHostState extends ConsumerState<RewardsHost> with WidgetsBindingObserver {
  StreamSubscription<RewardAction>? _actions;
  Timer? _dailyTimer;
  final List<Future<void> Function()> _queue = [];
  bool _presenting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _actions = RewardBus.stream.listen(_onAction);
    // A moment's grace after the shell appears, so sign-in sync and the streak update land first.
    _scheduleDaily(const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _actions?.cancel();
    _dailyTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleDaily(const Duration(milliseconds: 900));
  }

  void _scheduleDaily(Duration after) {
    _dailyTimer?.cancel();
    _dailyTimer = Timer(after, _daily);
  }

  /// The rewards map, seeded on first use. Someone who already has items is not new:
  /// they are not welcomed again and keep "first" badges for what they have done.
  Map<String, dynamic> _seeded() {
    final s = ref.read(appSettingsProvider);
    if (RewardsLedger(s.rewards).seeded) return s.rewards;
    bool real<T>(List<T> items, String Function(T) id) => items.any((e) => !isSampleId(id(e)));
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);
    final used = <RewardAction>{
      if (real(ref.read(notesProvider), (e) => e.id)) RewardAction.note,
      if (real(tasks, (e) => e.id)) RewardAction.task,
      if (tasks.any((t) => t.completed && !isSampleId(t.id))) RewardAction.taskDone,
      if (real(ref.read(eventsProvider), (e) => e.id)) RewardAction.event,
      if (real(habits, (e) => e.id)) RewardAction.habit,
      if (real(ref.read(journalProvider), (e) => e.id)) RewardAction.journal,
      if (real(ref.read(expensesProvider).expenses, (e) => e.id)) RewardAction.expense,
      if (real(ref.read(travelProvider), (e) => e.id)) RewardAction.trip,
      if (real(ref.read(wardrobeProvider), (e) => e.id)) RewardAction.outfit,
      if (real(ref.read(moodboardProvider), (e) => e.id)) RewardAction.pin,
      if (real(ref.read(shoppingProvider), (e) => e.id)) RewardAction.shopping,
    };
    final next = RewardsLedger.seed(
      s.rewards,
      newUser: used.isEmpty && s.longestStreak <= 1,
      alreadyUsed: used,
      milestoneReached: s.lastMilestoneCelebrated,
      now: DateTime.now(),
    );
    ref.read(appSettingsProvider.notifier).setRewards(next);
    return next;
  }

  /// Once per day, after the streak service has marked today active: the streak screen,
  /// then the welcome badge (first day only) and any streak milestone badges.
  void _daily() {
    if (!mounted) return;
    if (ViewStyleChooser.needed) _enqueue(() => ViewStyleChooser.showIfNeeded(context));

    final s = ref.read(appSettingsProvider);
    final now = DateTime.now();
    final today = RewardsLedger.dayKey(now);
    if (s.lastActiveDate != today) return; // the lastActiveDate listener brings us back
    var m = _seeded();
    final ledger = RewardsLedger(m);
    if (ledger.streakSeen == today) return;

    final firstDay = !ledger.welcomed;
    m = {...m, 'streakSeen': today, 'welcomed': true};
    final badges = <(BadgeDef, String?)>[];
    if (firstDay && !ledger.has(Badges.firstLight.id)) {
      m = {...m, 'badges': {...ledger.badges, Badges.firstLight.id: today}};
      badges.add((Badges.firstLight, null));
    }
    final (withStreak, streakBadges) = RewardsLedger.awardStreak(m, s.activeStreak, now);
    m = withStreak;
    badges.addAll([for (final b in streakBadges) (b, '+1 streak freeze earned')]);
    ref.read(appSettingsProvider.notifier).setRewards(m);

    final moment = StreakMoment.of(
      streak: s.activeStreak,
      longest: s.longestStreak,
      firstDay: firstDay,
      freezeUsed: s.streakFreezeUsedDate == today,
      freezesLeft: s.streakFreezesCount,
      firstDayOfWeek: s.firstDayOfWeek,
      now: now,
    );
    _enqueue(() => RewardCeremony.streak(context, moment));
    for (final (badge, reward) in badges) {
      _enqueue(() => RewardCeremony.badge(context, badge, reward: reward));
    }
  }

  void _onAction(RewardAction action) {
    if (!mounted) return;
    final (next, outcome) = RewardsLedger.record(_seeded(), action, DateTime.now());
    ref.read(appSettingsProvider.notifier).setRewards(next);
    if (!UiPrefs.of(ref.read(appSettingsProvider)).celebrate) return;

    // Let the editor or sheet that created the item close first.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (outcome.badges.isEmpty && !outcome.goalJustMet) {
        if (!_presenting) RewardCeremony.progress(context, outcome);
        return;
      }
      if (outcome.goalJustMet) {
        final goal = GoalMoment(
          count: outcome.count,
          goal: outcome.goal,
          goalDays: outcome.goalDays,
          streak: ref.read(appSettingsProvider).activeStreak,
        );
        _enqueue(() => RewardCeremony.goal(context, goal));
      }
      for (final badge in outcome.badges) {
        _enqueue(() => RewardCeremony.badge(context, badge));
      }
    });
  }

  void _enqueue(Future<void> Function() ceremony) {
    _queue.add(ceremony);
    if (!_presenting) _drain();
  }

  Future<void> _drain() async {
    _presenting = true;
    while (_queue.isNotEmpty && mounted) {
      final next = _queue.removeAt(0);
      try {
        await next();
      } catch (_) {
        // A ceremony that cannot be shown is skipped; the reward itself is already saved.
      }
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    _presenting = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(appSettingsProvider.select((s) => s.lastActiveDate), (_, __) => _scheduleDaily(const Duration(milliseconds: 400)));
    return widget.child;
  }
}
