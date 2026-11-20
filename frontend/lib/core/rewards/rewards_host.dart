import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/view_style_chooser.dart';
import '../services/nudge_host.dart';
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
  /// they are not welcomed again and keep the badges for what they have already done.
  Map<String, dynamic> _seeded() {
    final s = ref.read(appSettingsProvider);
    final ledger = RewardsLedger(s.rewards);
    if (ledger.seeded && ledger.upgraded) return s.rewards;
    int real<T>(Iterable<T> items, String Function(T) id) => items.where((e) => !isSampleId(id(e))).length;
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider).where((h) => !isSampleId(h.id));
    final totals = <RewardAction, int>{
      RewardAction.note: real(ref.read(notesProvider), (e) => e.id),
      RewardAction.task: real(tasks, (e) => e.id),
      RewardAction.taskDone: real(tasks.where((t) => t.completed), (e) => e.id),
      RewardAction.event: real(ref.read(eventsProvider), (e) => e.id),
      RewardAction.habit: habits.length,
      RewardAction.habitDone: habits.fold(0, (p, h) => p + h.completedDays.length),
      RewardAction.journal: real(ref.read(journalProvider), (e) => e.id),
      RewardAction.expense: real(ref.read(expensesProvider).expenses, (e) => e.id),
      RewardAction.trip: real(ref.read(travelProvider), (e) => e.id),
      RewardAction.outfit: real(ref.read(wardrobeProvider), (e) => e.id),
      RewardAction.pin: real(ref.read(moodboardProvider), (e) => e.id),
      RewardAction.shopping: real(ref.read(shoppingProvider), (e) => e.id),
    }..removeWhere((_, n) => n == 0);
    final counts = {for (final e in totals.entries) e.key.name: e.value};
    final now = DateTime.now();
    final next = ledger.seeded
        ? RewardsLedger.upgrade(s.rewards, totals: counts, now: now)
        : RewardsLedger.seed(
            s.rewards,
            newUser: totals.isEmpty && s.longestStreak <= 1,
            alreadyUsed: totals.keys.toSet(),
            milestoneReached: s.lastMilestoneCelebrated,
            now: now,
            totals: counts,
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
    m = RewardsLedger.markActive({...m, 'streakSeen': today, 'welcomed': true}, now, streak: s.activeStreak);
    final badges = <(BadgeDef, String?)>[];
    if (firstDay && !ledger.has(Badges.firstLight.id)) {
      m = {...m, 'badges': {...ledger.badges, Badges.firstLight.id: today}};
      badges.add((Badges.firstLight, null));
    }
    final (withStreak, streakBadges) = RewardsLedger.awardStreak(m, s.activeStreak, now);
    m = withStreak;
    badges.addAll([for (final b in streakBadges) (b, '+1 streak freeze earned')]);

    final moment = StreakMoment.of(
      streak: s.activeStreak,
      longest: s.longestStreak,
      firstDay: firstDay,
      freezeUsed: s.streakFreezeUsedDate == today,
      freezesLeft: s.streakFreezesCount,
      firstDayOfWeek: s.firstDayOfWeek,
      now: now,
      repairLost: ledger.repairOffer(today),
    );
    for (final (badge, happened) in [(Badges.comeback, moment.restarted), (Badges.iceShield, moment.freezeUsed)]) {
      if (!happened) continue;
      final (next, isNew) = RewardsLedger.awardOnce(m, badge, now);
      m = next;
      if (isNew) badges.add((badge, null));
    }
    ref.read(appSettingsProvider.notifier).setRewards(m);
    _enqueue(() => RewardCeremony.streak(context, moment));
    for (final (badge, reward) in badges) {
      _enqueue(() => RewardCeremony.badge(context, badge, reward: reward));
    }
  }

  void _onAction(RewardAction action) {
    if (!mounted) return;
    final now = DateTime.now();
    final habitStreak = action == RewardAction.habitDone
        ? ref.read(habitsProvider).where((h) => h.isDoneOn(now)).fold(0, (p, h) => h.streakAt(now) > p ? h.streakAt(now) : p)
        : 0;
    final (next, outcome) = RewardsLedger.record(_seeded(), action, now, habitStreak: habitStreak);
    final settings = ref.read(appSettingsProvider.notifier);
    settings.setRewards(next);
    final repaired = outcome.repaired;
    if (repaired != null) {
      // Today joins the restored run.
      final restored = repaired + 1;
      settings.setActiveStreak(restored);
      if (restored > ref.read(appSettingsProvider).longestStreak) settings.setLongestStreak(restored);
    }
    if (!UiPrefs.of(ref.read(appSettingsProvider)).celebrate) return;

    // Let the editor or sheet that created the item close first.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final level = outcome.levelUp;
      if (repaired != null) {
        final medal = BadgeDef(
          'repair',
          'Your ${repaired + 1}-day streak is back',
          'You did ${RewardsLedger.repairActions} things today and won it back. Repairs can be used once a month.',
          LucideIcons.flame,
          tier: 2,
        );
        _enqueue(() => RewardCeremony.badge(context, medal));
      }
      if (outcome.badges.isEmpty && !outcome.goalJustMet && level == null && repaired == null) {
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
      if (level != null) {
        final medal = BadgeDef(
          'level_${level.level}',
          'Level ${level.level} · ${level.title}',
          'You reached level ${level.level}. ${level.toNext} more points to ${level.nextTitle}.',
          LucideIcons.trendingUp,
          tier: (level.level ~/ 3).clamp(1, 3),
        );
        _enqueue(() => RewardCeremony.badge(context, medal));
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
    return NudgeHost(child: widget.child);
  }
}
