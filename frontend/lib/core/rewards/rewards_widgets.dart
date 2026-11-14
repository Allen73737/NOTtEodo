import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/editorial_kit.dart';
import '../editorial/editorial_mode.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import '../widgets/bento_pod.dart';
import 'cards_ceremony.dart';
import 'reward_ceremony.dart';
import 'rewards_ledger.dart';

/// Replays today's streak screen on demand.
void showTodaysStreak(BuildContext context, AppSettings s) {
  final today = RewardsLedger.dayKey(DateTime.now());
  RewardCeremony.streak(
    context,
    StreakMoment.of(
      streak: s.activeStreak,
      longest: s.longestStreak,
      firstDay: false,
      freezeUsed: s.streakFreezeUsedDate == today,
      freezesLeft: s.streakFreezesCount,
      firstDayOfWeek: s.firstDayOfWeek,
    ),
  );
}

/// Card view: a living flame inside a ring that fills toward today's goal, beside the
/// app streak. Tap to see the day's streak.
class DailyGoalOrb extends ConsumerStatefulWidget {
  const DailyGoalOrb({super.key});

  @override
  ConsumerState<DailyGoalOrb> createState() => _DailyGoalOrbState();
}

class _DailyGoalOrbState extends ConsumerState<DailyGoalOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 5));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appSettingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = RewardsLedger(s.rewards).countOn(RewardsLedger.dayKey(DateTime.now()));
    const goal = RewardsLedger.dailyGoal;
    final met = count >= goal;
    final accent = dark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);
    return Semantics(
      button: true,
      label: '${s.activeStreak} day streak, $count of $goal done today',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => showTodaysStreak(context, s),
        child: RepaintBoundary(
          child: OffscreenPause(
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: dark ? const Color(0xFF0E0B0A) : Colors.white,
                border: Border.all(color: accent.withValues(alpha: met ? 0.6 : 0.3)),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: met ? 0.32 : 0.12), blurRadius: met ? 18 : 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: (count / goal).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 900),
                    curve: Motion.settle,
                    builder: (context, fill, _) => AnimatedBuilder(
                      animation: _loop,
                      builder: (context, _) => SizedBox.square(
                        dimension: 40,
                        child: CustomPaint(
                          painter: _OrbRingPainter(fill: fill, loop: _loop.value, dark: dark),
                          child: Center(
                            child: SizedBox(width: 15, height: 20, child: CustomPaint(painter: FlamePainter(loop: _loop.value, frost: false))),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.activeStreak}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        met ? 'GOAL MET' : '$count/$goal TODAY',
                        style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbRingPainter extends CustomPainter {
  final double fill;
  final double loop;
  final bool dark;

  _OrbRingPainter({required this.fill, required this.loop, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 3;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r - 2, Paint()
      ..shader = RadialGradient(colors: [const Color(0xFFD9725B).withValues(alpha: dark ? 0.22 : 0.14), Colors.transparent]).createShader(rect));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.08));
    if (fill <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fill,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: const [Color(0xFFFFB199), Color(0xFFD9725B), Color(0xFFFFB199)],
          transform: GradientRotation(loop * math.pi * 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_OrbRingPainter old) => old.fill != fill || old.loop != loop || old.dark != dark;
}

/// Every badge, earned ones first. Tap an earned badge to relive its moment.
class BadgeShelf extends ConsumerWidget {
  const BadgeShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = RewardsLedger(ref.watch(appSettingsProvider.select((s) => s.rewards)));
    final earned = ledger.earned;
    final locked = [for (final b in Badges.all) if (!ledger.has(b.id)) b];
    return EditorialMode.active ? _editorial(context, earned, locked) : _cards(context, earned, locked);
  }

  Widget _editorial(BuildContext context, List<BadgeDef> earned, List<BadgeDef> locked) {
    final ed = Ed.of(context);
    Widget seal(BadgeDef b, bool has) {
      final item = SizedBox(
        width: 78,
        child: Column(
          children: [
            SizedBox.square(
              dimension: 56,
              child: CustomPaint(
                painter: _MiniSealPainter(earned: has, accent: ed.accent, faint: ed.faint),
                child: Icon(b.icon, size: 20, color: has ? ed.ink : ed.faint),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              b.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: ed.meta.copyWith(fontSize: 12, height: 1.25, color: has ? ed.ink : ed.muted),
            ),
          ],
        ),
      );
      return Tooltip(
        message: b.line,
        child: has ? GestureDetector(onTap: () => RewardCeremony.badge(context, b), child: item) : item,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${earned.length} of ${Badges.all.length} earned. Tap one to relive it.', style: ed.meta),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 18,
          children: [for (final b in earned) seal(b, true), for (final b in locked) seal(b, false)],
        ),
      ],
    );
  }

  Widget _cards(BuildContext context, List<BadgeDef> earned, List<BadgeDef> locked) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917);
    final sub = dark ? const Color(0xFFA6A096) : const Color(0xFF6B635A);
    const accent = Color(0xFFD9725B);
    Widget medal(BadgeDef b, bool has) {
      final tier = medalTiers[b.tier.clamp(0, medalTiers.length - 1)];
      Widget art = SizedBox(
        width: 62,
        height: 74,
        child: CustomPaint(
          painter: MedalPainter(tier: tier, rim: b.id.hashCode % 6 / 1.0, sheen: -1),
          child: Align(
            alignment: const Alignment(0, -0.24),
            child: Icon(has ? b.icon : LucideIcons.lock, size: 20, color: Colors.white),
          ),
        ),
      );
      if (!has) {
        art = Opacity(opacity: 0.32, child: ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscale), child: art));
      }
      final item = SizedBox(
        width: 84,
        child: Column(
          children: [
            art,
            const SizedBox(height: 8),
            Text(
              b.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w600, color: has ? ink : sub),
            ),
          ],
        ),
      );
      return Tooltip(
        message: b.line,
        child: has ? Pressable(onTap: () => RewardCeremony.badge(context, b), child: item) : item,
      );
    }

    final all = [for (final b in earned) (b, true), for (final b in locked) (b, false)];
    return BentoPod(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('BADGES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accent)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: accent.withValues(alpha: 0.12)),
                child: Text(
                  '${earned.length} / ${Badges.all.length}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) => Reveal(style: RevealStyle.pop, child: medal(all[i].$1, all[i].$2)),
            ),
          ),
        ],
      ),
    );
  }

  static const List<double> _greyscale = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

class _MiniSealPainter extends CustomPainter {
  final bool earned;
  final Color accent;
  final Color faint;

  _MiniSealPainter({required this.earned, required this.accent, required this.faint});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = earned ? 1 : 0.8
      ..color = earned ? accent : faint;
    if (earned) {
      canvas.drawCircle(c, r, line);
      canvas.drawCircle(c, r - 5, line..strokeWidth = 0.6);
    } else {
      // Dotted rim for badges still to come.
      const dots = 28;
      for (var i = 0; i < dots; i++) {
        final a = i * 2 * math.pi / dots;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 0.7, Paint()..color = faint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniSealPainter old) => old.earned != earned || old.accent != accent || old.faint != faint;
}
