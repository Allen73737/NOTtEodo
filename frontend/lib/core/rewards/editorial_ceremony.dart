import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../editorial/editorial_kit.dart';
import '../motion/motion.dart';
import 'reward_ceremony.dart';
import 'rewards_ledger.dart';

// Editorial ceremonies: words on paper. One hairline drawn in accent, type that settles
// into focus, and nothing that looks like a box. Each page runs a single timeline.

/// Progress of [t] through the window [a]–[b], eased.
double _iv(double t, double a, double b, [Curve curve = Motion.silk]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// Fades [child] in while it rises [dy] pixels into place.
Widget _rise(double p, Widget child, {double dy = 14}) => Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, (1 - p) * dy), child: child),
    );

/// Like [_rise], but the type comes into focus from a soft blur.
Widget _focus(double p, Widget child) => Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: ImageFiltered(
        enabled: p < 0.98,
        imageFilter: ui.ImageFilter.blur(sigmaX: (1 - p) * 8, sigmaY: (1 - p) * 8),
        child: child,
      ),
    );

/// Shared timeline and page frame for the editorial ceremonies.
mixin _EdTimeline<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController timeline = AnimationController(vsync: this, duration: duration);

  Duration get duration => const Duration(milliseconds: 2400);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (timeline.isAnimating || timeline.value > 0) return;
    if (Motion.reduced(context)) {
      timeline.value = 1;
    } else {
      timeline.forward();
    }
  }

  @override
  void dispose() {
    timeline.dispose();
    super.dispose();
  }

  void close() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
  }

  Widget frame(Ed ed, Widget Function(double t) build) {
    return Material(
      color: ed.paper,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Once everything has arrived, a tap anywhere moves on.
        onTap: () => timeline.value > 0.85 ? close() : timeline.animateTo(1, duration: Motion.standard),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AnimatedBuilder(animation: timeline, builder: (_, __) => build(timeline.value)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget continueLink(Ed ed, double p) {
    return _rise(
      p,
      Semantics(
        button: true,
        label: 'Continue',
        child: InkWell(
          onTap: close,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue', style: ed.action),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 16, color: ed.accent),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: p,
                    child: Container(height: 1, color: ed.accent.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Streak -----------------------------------------------------------------------

class EditorialStreakPage extends StatefulWidget {
  final StreakMoment moment;
  const EditorialStreakPage({super.key, required this.moment});

  @override
  State<EditorialStreakPage> createState() => _EditorialStreakPageState();
}

class _EditorialStreakPageState extends State<EditorialStreakPage> with SingleTickerProviderStateMixin, _EdTimeline {
  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final m = widget.moment;
    final from = m.firstDay || m.restarted || m.freezeUsed ? m.streak : math.max(0, m.streak - 1);
    return frame(ed, (t) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rise(_iv(t, 0, 0.25), Text(m.kicker.toUpperCase(), textAlign: TextAlign.center, style: ed.label.copyWith(color: ed.accent))),
          const SizedBox(height: 28),
          SizedBox.square(
            dimension: 224,
            child: CustomPaint(
              painter: _HairlineRing(progress: _iv(t, 0.06, 0.6, Curves.easeInOutCubic), accent: ed.accent, faint: ed.faint),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RollingNumeral(
                      from: from,
                      to: m.streak,
                      progress: _iv(t, 0.2, 0.62),
                      style: ed.display.copyWith(fontSize: 92, height: 1, letterSpacing: -2),
                    ),
                    const SizedBox(height: 6),
                    _rise(_iv(t, 0.4, 0.7), Text('day streak', style: ed.meta.copyWith(fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _focus(_iv(t, 0.45, 0.75), Text(m.line, textAlign: TextAlign.center, style: ed.standfirst.copyWith(fontStyle: FontStyle.italic))),
          const SizedBox(height: 36),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _WeekMark(
                    letter: m.weekLetters[i],
                    lit: m.week[i],
                    today: i == m.todayIndex,
                    progress: _iv(t, 0.55 + i * 0.035, 0.78 + i * 0.035, Motion.settle),
                    ed: ed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 44),
          continueLink(ed, _iv(t, 0.8, 1)),
        ],
      );
    });
  }
}

/// A number that rolls up from [from] to [to]: the old figure lifts away as the new one
/// rises beneath it.
class _RollingNumeral extends StatelessWidget {
  final int from;
  final int to;
  final double progress;
  final TextStyle style;

  const _RollingNumeral({required this.from, required this.to, required this.progress, required this.style});

  @override
  Widget build(BuildContext context) {
    final h = (style.fontSize ?? 48) * 1.05;
    final p = progress;
    if (from == to) return _focus(p, Text('$to', style: style));
    return ClipRect(
      child: SizedBox(
        height: h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(offset: Offset(0, -p * h), child: Opacity(opacity: 1 - p, child: Text('$from', style: style))),
            Transform.translate(offset: Offset(0, (1 - p) * h), child: Opacity(opacity: p, child: Text('$to', style: style))),
          ],
        ),
      ),
    );
  }
}

class _WeekMark extends StatelessWidget {
  final String letter;
  final bool lit;
  final bool today;
  final double progress;
  final Ed ed;

  const _WeekMark({required this.letter, required this.lit, required this.today, required this.progress, required this.ed});

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.2);
    return Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Column(
        children: [
          Text(letter, style: ed.label.copyWith(color: today ? ed.ink : ed.muted, letterSpacing: 0)),
          const SizedBox(height: 12),
          SizedBox.square(
            dimension: 18,
            child: CustomPaint(painter: _DotPainter(lit: lit, today: today, p: p, accent: ed.accent, faint: ed.faint)),
          ),
        ],
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final bool lit;
  final bool today;
  final double p;
  final Color accent;
  final Color faint;

  _DotPainter({required this.lit, required this.today, required this.p, required this.accent, required this.faint});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (lit) {
      canvas.drawCircle(c, 3.6 * p, Paint()..color = accent);
    } else {
      canvas.drawCircle(c, 3.2, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = faint);
    }
    if (today) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 8.2),
        -math.pi / 2,
        2 * math.pi * p.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.p != p || old.lit != lit || old.accent != accent;
}

/// A faint full circle with an accent hairline drawn around it, ending in a small bead.
class _HairlineRing extends CustomPainter {
  final double progress;
  final Color accent;
  final Color faint;

  _HairlineRing({required this.progress, required this.accent, required this.faint});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = faint.withValues(alpha: 0.55 * progress.clamp(0.0, 1.0)));
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
    final head = c + Offset(math.cos(-math.pi / 2 + sweep), math.sin(-math.pi / 2 + sweep)) * r;
    canvas.drawCircle(head, 2.6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_HairlineRing old) => old.progress != progress || old.accent != accent;
}

// --- Badge ------------------------------------------------------------------------

class EditorialBadgePage extends StatefulWidget {
  final BadgeDef badge;
  final String? reward;
  const EditorialBadgePage({super.key, required this.badge, this.reward});

  @override
  State<EditorialBadgePage> createState() => _EditorialBadgePageState();
}

class _EditorialBadgePageState extends State<EditorialBadgePage> with SingleTickerProviderStateMixin, _EdTimeline {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final b = widget.badge;
    return frame(ed, (t) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rise(_iv(t, 0, 0.25), Text('BADGE EARNED', style: ed.label.copyWith(color: ed.accent))),
          const SizedBox(height: 30),
          SizedBox.square(
            dimension: 196,
            child: CustomPaint(
              painter: _SealPainter(
                rings: _iv(t, 0.05, 0.55, Curves.easeInOutCubic),
                ticks: _iv(t, 0.2, 0.8, Curves.easeOut),
                accent: ed.accent,
                ink: ed.ink,
              ),
              child: Center(child: _focus(_iv(t, 0.35, 0.7), Icon(b.icon, size: 42, color: ed.ink))),
            ),
          ),
          const SizedBox(height: 30),
          _focus(_iv(t, 0.45, 0.75), Text(b.title, textAlign: TextAlign.center, style: ed.title.copyWith(fontSize: 34))),
          const SizedBox(height: 12),
          _rise(_iv(t, 0.55, 0.85), Text(b.line, textAlign: TextAlign.center, style: ed.standfirst)),
          if (widget.reward != null) ...[
            const SizedBox(height: 20),
            _rise(_iv(t, 0.65, 0.9), Text(widget.reward!.toUpperCase(), textAlign: TextAlign.center, style: ed.label.copyWith(color: ed.accent))),
          ],
          const SizedBox(height: 44),
          continueLink(ed, _iv(t, 0.8, 1)),
        ],
      );
    });
  }
}

/// An engraved seal: two concentric hairlines drawn in, then a ring of fine ticks
/// pressed in around the rim.
class _SealPainter extends CustomPainter {
  final double rings;
  final double ticks;
  final Color accent;
  final Color ink;

  _SealPainter({required this.rings, required this.ticks, required this.accent, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 2;
    final inner = outer - 16;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = accent;
    canvas.drawArc(Rect.fromCircle(center: c, radius: outer), -math.pi / 2, 2 * math.pi * rings, false, line);
    final innerP = ((rings - 0.25) / 0.75).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: c, radius: inner), math.pi / 2, -2 * math.pi * innerP, false, line..strokeWidth = 0.8);

    const count = 60;
    final tick = Paint()
      ..strokeWidth = 0.8
      ..color = ink.withValues(alpha: 0.35);
    final shown = (count * ticks).floor();
    for (var i = 0; i < shown; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / count;
      final dir = Offset(math.cos(a), math.sin(a));
      final long = i % 5 == 0;
      canvas.drawLine(c + dir * (inner + 4), c + dir * (inner + (long ? 11 : 8)), tick);
    }
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.rings != rings || old.ticks != ticks || old.accent != accent;
}

// --- Daily goal -------------------------------------------------------------------

class EditorialGoalPage extends StatefulWidget {
  final GoalMoment moment;
  const EditorialGoalPage({super.key, required this.moment});

  @override
  State<EditorialGoalPage> createState() => _EditorialGoalPageState();
}

class _EditorialGoalPageState extends State<EditorialGoalPage> with SingleTickerProviderStateMixin, _EdTimeline {
  static const _numerals = ['I', 'II', 'III', 'IV', 'V'];

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final m = widget.moment;
    return frame(ed, (t) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rise(_iv(t, 0, 0.25), Text("TODAY'S GOAL", style: ed.label.copyWith(color: ed.accent))),
          const SizedBox(height: 22),
          _focus(_iv(t, 0.08, 0.5), Text('A day\nwell kept.', textAlign: TextAlign.center, style: ed.display.copyWith(fontSize: 48))),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < m.goal; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 58,
                        height: 2,
                        child: Stack(
                          children: [
                            Container(color: ed.faint.withValues(alpha: 0.5)),
                            FractionallySizedBox(
                              widthFactor: _iv(t, 0.3 + i * 0.12, 0.5 + i * 0.12, Curves.easeInOutCubic),
                              child: Container(color: ed.accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _iv(t, 0.35 + i * 0.12, 0.55 + i * 0.12),
                        child: Text(_numerals[i % _numerals.length], style: ed.label.copyWith(letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 34),
          _rise(
            _iv(t, 0.62, 0.85),
            Text(
              '${m.count} things done today. Small, steady, yours.',
              textAlign: TextAlign.center,
              style: ed.standfirst.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 14),
          _rise(
            _iv(t, 0.7, 0.92),
            Text(
              '${m.goalDays} good ${m.goalDays == 1 ? 'day' : 'days'}  ·  ${m.streak}-day streak'.toUpperCase(),
              textAlign: TextAlign.center,
              style: ed.label,
            ),
          ),
          const SizedBox(height: 44),
          continueLink(ed, _iv(t, 0.82, 1)),
        ],
      );
    });
  }
}

// --- Progress toast ---------------------------------------------------------------

/// A quiet line above the dock: what was just done, and how far today's goal has come,
/// with a hairline that extends to the new mark.
class EditorialProgressToast extends StatefulWidget {
  final RewardOutcome outcome;
  final VoidCallback onDone;
  const EditorialProgressToast({super.key, required this.outcome, required this.onDone});

  @override
  State<EditorialProgressToast> createState() => _EditorialProgressToastState();
}

class _EditorialProgressToastState extends State<EditorialProgressToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final o = widget.outcome;
    final over = o.count > o.goal;
    final bottom = MediaQuery.paddingOf(context).bottom + 96;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final inP = _iv(t, 0, 0.12);
                final outP = _iv(t, 0.86, 1, Curves.easeIn);
                final from = ((o.count - 1) / o.goal).clamp(0.0, 1.0);
                final to = (o.count / o.goal).clamp(0.0, 1.0);
                final fill = from + (to - from) * _iv(t, 0.1, 0.4, Curves.easeInOutCubic);
                return Opacity(
                  opacity: (inP * (1 - outP)).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - inP) * 10 + outP * 6),
                    child: Material(
                      color: ed.paper,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(rewardActionIcon(o.action), size: 15, color: ed.muted),
                                const SizedBox(width: 10),
                                Expanded(child: Text(rewardActionLabel(o.action), style: ed.meta.copyWith(color: ed.ink))),
                                Text(
                                  over ? 'GOAL MET · ${o.count} TODAY' : '${o.count} OF ${o.goal} TODAY',
                                  style: ed.label.copyWith(color: ed.accent, letterSpacing: 1.2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 1,
                              child: Stack(
                                children: [
                                  Container(color: ed.faint.withValues(alpha: 0.5)),
                                  FractionallySizedBox(widthFactor: fill, child: Container(color: ed.accent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
