import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';
import '../systems/aesthetic_audio_service.dart';
import '../widgets/sparkle_explosion.dart';
import 'reward_ceremony.dart';
import 'rewards_ledger.dart';

// Card-view ceremonies: dimensional and alive. Cards flip in out of the dark, a flame
// is drawn and flickers, medals spin to a landing under turning light, and embers
// drift up the whole time. Each page runs one timeline plus one ambient loop.

const _peach = Color(0xFFFFB199);
const _blush = Color(0xFFFFE3D6);
const _rose = Color(0xFFE8927C);
const _terracotta = Color(0xFFD9725B);
const _ember = Color(0xFF8C3E2D);
const _cardTop = Color(0xFF1C1412);
const _cardBottom = Color(0xFF0B0908);
const _linen = Color(0xFFF6F3ED);
const _mutedLinen = Color(0xFFB5AE9F);

double _iv(double t, double a, double b, [Curve curve = Motion.silk]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// Medal finishes by tier as (highlight, body, shadow).
const medalTiers = <(Color, Color, Color)>[
  (Color(0xFFF0B9A2), Color(0xFFB87358), Color(0xFF6E3524)),
  (Color(0xFFFFC9B8), Color(0xFFE8927C), Color(0xFFAD4E38)),
  (Color(0xFFF1C9DF), Color(0xFFC27BA4), Color(0xFF6A2F51)),
  (Color(0xFFFFE3D2), Color(0xFFE4A383), Color(0xFF8C3E2D)),
];

/// Timeline, ambient loop and confetti shared by the card ceremonies.
mixin _CardsTimeline<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController timeline = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  late final AnimationController loop = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  bool reduced = false;
  bool burst = false;

  /// Timeline position at which confetti fires and the big haptic lands.
  double get impactAt;

  @override
  void initState() {
    super.initState();
    timeline.addListener(() {
      if (!burst && timeline.value >= impactAt) {
        setState(() => burst = !reduced);
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (timeline.value > 0 || timeline.isAnimating) return;
    reduced = Motion.reduced(context);
    if (reduced) {
      timeline.value = 1;
    } else {
      timeline.forward();
      loop.repeat();
      AestheticAudioService().playHapticTone(type: 'ritual');
    }
  }

  @override
  void dispose() {
    timeline.dispose();
    loop.dispose();
    super.dispose();
  }

  void close() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
  }

  /// Dark, blurred stage with drifting embers and a breathing glow; [build] draws the
  /// content for the current timeline position.
  Widget stage(Widget Function(double t, double l) build, {bool rays = false, Color glow = _terracotta}) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => timeline.value > 0.85 ? close() : timeline.animateTo(1, duration: Motion.standard),
        child: AnimatedBuilder(
          animation: Listenable.merge([timeline, loop]),
          builder: (context, _) {
            final t = timeline.value;
            final l = loop.value;
            final fade = _iv(t, 0, 0.18, Curves.easeOut);
            return Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16 * fade, sigmaY: 16 * fade),
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.78 * fade)),
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: fade,
                    child: CustomPaint(painter: _StagePainter(loop: l, glow: glow, rays: rays ? _iv(t, 0.4, 0.75) : 0)),
                  ),
                ),
                SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: build(t, l)))),
                if (burst)
                  SparkleExplosion(
                    position: Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.4),
                    particleCount: 56,
                    onComplete: () {},
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Flips [child] up out of the screen plane on a perspective hinge, landing with a
/// little overshoot.
Widget _flipIn(double p, Widget child) {
  final m = Matrix4.identity()
    ..setEntry(3, 2, 0.0015)
    ..translateByDouble(0, (1 - p) * 90, 0, 1)
    ..rotateX((1 - p) * 1.25)
    ..scaleByDouble(0.86 + 0.14 * p, 0.86 + 0.14 * p, 1, 1);
  return Opacity(opacity: (p * 2.2).clamp(0.0, 1.0), child: Transform(alignment: Alignment.center, transform: m, child: child));
}

Widget _riseIn(double p, Widget child, {double dy = 18}) => Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, (1 - p) * dy), child: child),
    );

/// Pops in with an elastic overshoot.
Widget _popIn(double p, Widget child) {
  final s = p <= 0 ? 0.0 : Curves.elasticOut.transform(p.clamp(0.0, 1.0));
  return Opacity(opacity: (p * 3).clamp(0.0, 1.0), child: Transform.scale(scale: s, child: child));
}

/// Paints [child] with a warm gradient and a highlight that sweeps across at [sweep]
/// (-0.3 → 1.3 crosses once).
Widget _shimmerText(Widget child, double sweep) {
  final s = sweep.clamp(-0.3, 1.3);
  return ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (r) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [_terracotta, _rose, _blush, _rose, _terracotta],
      stops: [0, (s - 0.18).clamp(0.0, 1.0), s.clamp(0.0, 1.0), (s + 0.18).clamp(0.0, 1.0), 1],
    ).createShader(r),
    child: child,
  );
}

class _CeremonyCard extends StatelessWidget {
  final Widget child;
  const _CeremonyCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = math.min(380.0, MediaQuery.sizeOf(context).width - 32);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_cardTop, _cardBottom]),
        border: Border.all(color: _rose.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: _terracotta.withValues(alpha: 0.28), blurRadius: 48, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 40, offset: const Offset(0, 18)),
        ],
      ),
      child: child,
    );
  }
}

class _Kicker extends StatelessWidget {
  final String text;
  const _Kicker(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _terracotta.withValues(alpha: 0.14),
        border: Border.all(color: _rose.withValues(alpha: 0.45)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: _peach),
      ),
    );
  }
}

/// Gradient pill with a light sweep that runs along it on the ambient loop.
class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double loop;
  final VoidCallback onTap;

  const _GlowButton({required this.label, required this.icon, required this.loop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sweep = ((loop * 2) % 1) * 2.4 - 0.7;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [_rose, _terracotta, Color(0xFFB4533D)]),
            boxShadow: [BoxShadow(color: _terracotta.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(sweep, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0),
                        ], stops: const [0.3, 0.5, 0.7]),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: Colors.white),
                    const SizedBox(width: 9),
                    Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)),
                  ],
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

class CardsStreakPage extends StatefulWidget {
  final StreakMoment moment;
  const CardsStreakPage({super.key, required this.moment});

  @override
  State<CardsStreakPage> createState() => _CardsStreakPageState();
}

class _CardsStreakPageState extends State<CardsStreakPage> with TickerProviderStateMixin, _CardsTimeline {
  @override
  double get impactAt => 0.5;

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    final from = m.firstDay || m.restarted || m.freezeUsed ? 0 : math.max(0, m.streak - 1);
    return stage((t, l) {
      final count = _iv(t, 0.3, 0.55, Curves.easeOutCubic);
      final shown = (from + (m.streak - from) * count).round();
      return _flipIn(
        _iv(t, 0, 0.36, Motion.settle),
        _CeremonyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _riseIn(_iv(t, 0.12, 0.35), _Kicker(m.kicker)),
              const SizedBox(height: 8),
              SizedBox.square(
                dimension: 168,
                child: CustomPaint(
                  painter: _OrbitPainter(loop: l, ignite: _iv(t, 0.14, 0.5, Motion.settle), freeze: m.freezeUsed),
                  child: Center(
                    child: Transform.scale(
                      scale: _iv(t, 0.14, 0.5, Motion.settle),
                      child: SizedBox(
                        width: 78,
                        height: 100,
                        child: CustomPaint(painter: FlamePainter(loop: l, frost: m.freezeUsed)),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.55 + 0.45 * _iv(t, 0.3, 0.62, Curves.elasticOut),
                child: Opacity(
                  opacity: _iv(t, 0.28, 0.4),
                  child: _shimmerText(
                    Text('$shown', style: GoogleFonts.spaceGrotesk(fontSize: 84, height: 1, fontWeight: FontWeight.w700, letterSpacing: -3)),
                    _iv(t, 0.5, 0.85) * 1.6 - 0.3,
                  ),
                ),
              ),
              _riseIn(
                _iv(t, 0.48, 0.66),
                Text('DAY STREAK', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 3.2, color: _mutedLinen)),
              ),
              const SizedBox(height: 14),
              _riseIn(
                _iv(t, 0.55, 0.74),
                Text(m.line, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: _linen.withValues(alpha: 0.82))),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _WeekChip(
                          letter: m.weekLetters[i],
                          lit: m.week[i],
                          today: i == m.todayIndex,
                          pop: _iv(t, 0.6 + i * 0.035, 0.86 + i * 0.035, Curves.linear),
                          loop: l,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _riseIn(
                _iv(t, 0.84, 1),
                _GlowButton(
                  label: m.firstDay ? "Let's begin" : 'Keep it burning',
                  icon: LucideIcons.flame,
                  loop: l,
                  onTap: close,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _WeekChip extends StatelessWidget {
  final String letter;
  final bool lit;
  final bool today;
  final double pop;
  final double loop;

  const _WeekChip({required this.letter, required this.lit, required this.today, required this.pop, required this.loop});

  @override
  Widget build(BuildContext context) {
    final pulse = today ? (math.sin(loop * math.pi * 6) + 1) / 2 : 0.0;
    return Column(
      children: [
        _popIn(
          pop,
          SizedBox.square(
            dimension: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (today)
                  Container(
                    width: 34 + 8 * pulse,
                    height: 34 + 8 * pulse,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _rose.withValues(alpha: 0.55 * (1 - pulse)), width: 1.4),
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: lit ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_peach, _terracotta]) : null,
                    color: lit ? null : Colors.white.withValues(alpha: 0.04),
                    border: lit ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    boxShadow: lit ? [BoxShadow(color: _terracotta.withValues(alpha: 0.5), blurRadius: 12)] : null,
                  ),
                  child: lit ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: pop.clamp(0.0, 1.0),
          child: Text(
            letter,
            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: today ? _peach : _mutedLinen.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

/// A drawn flame: a soft glow, an outer tongue that sways, and a bright core.
class FlamePainter extends CustomPainter {
  final double loop;
  final bool frost;

  FlamePainter({required this.loop, required this.frost});

  Path _tongue(Size s, double sway, double lift) {
    final w = s.width, h = s.height;
    final tipX = w * 0.5 + sway * w * 0.12;
    final tipY = h * (0.02 - lift);
    return Path()
      ..moveTo(w * 0.5, h)
      ..cubicTo(w * 0.06, h, -w * 0.02, h * 0.6, w * 0.24, h * 0.34)
      ..cubicTo(w * 0.27, h * 0.5, w * 0.38, h * 0.55, w * 0.42, h * 0.47)
      ..cubicTo(w * 0.36, h * 0.28, tipX - w * 0.1, h * 0.14, tipX, tipY)
      ..cubicTo(w * 0.8, h * 0.2, w * 1.04, h * 0.48, w * 0.96, h * 0.7)
      ..cubicTo(w * 0.92, h * 0.92, w * 0.76, h, w * 0.5, h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = loop * math.pi * 2;
    final sway = math.sin(a * 5) * 0.6 + math.sin(a * 11) * 0.4;
    final lift = (math.sin(a * 7) + 1) * 0.02;
    final outer = _tongue(size, sway, lift);
    final colors = frost
        ? const [Color(0xFFDCEBF5), Color(0xFF90B4CE), Color(0xFF4A6878)]
        : const [_peach, _terracotta, _ember];

    canvas.drawPath(
      outer,
      Paint()
        ..color = colors[1].withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: colors).createShader(Offset.zero & size),
    );

    // Bright core, anchored at the base and swaying a little against the outer tongue.
    canvas.save();
    canvas.translate(size.width * 0.5, size.height);
    canvas.scale(0.52, 0.56);
    canvas.translate(-size.width * 0.5, -size.height);
    canvas.drawPath(
      _tongue(size, -sway * 0.7, lift * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.white, frost ? const Color(0xFFDCEBF5) : _blush, colors[0].withValues(alpha: 0.6)],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FlamePainter old) => old.loop != loop || old.frost != frost;
}

/// Glow behind the flame, a dashed orbit and three sparks travelling round it.
class _OrbitPainter extends CustomPainter {
  final double loop;
  final double ignite;
  final bool freeze;

  _OrbitPainter({required this.loop, required this.ignite, required this.freeze});

  @override
  void paint(Canvas canvas, Size size) {
    if (ignite <= 0) return;
    final c = size.center(Offset.zero);
    final tint = freeze ? const Color(0xFF90B4CE) : _terracotta;
    final breathe = (math.sin(loop * math.pi * 4) + 1) / 2;
    canvas.drawCircle(
      c,
      58 * ignite + 6 * breathe,
      Paint()
        ..shader = RadialGradient(colors: [tint.withValues(alpha: 0.5), tint.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: 72)),
    );

    final r = size.shortestSide / 2 - 8;
    final spin = loop * math.pi * 2;
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _rose.withValues(alpha: 0.28 * ignite);
    const dashes = 36;
    for (var i = 0; i < dashes; i++) {
      final start = spin * 0.5 + i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, math.pi / dashes, false, dash);
    }
    for (var k = 0; k < 3; k++) {
      final ang = -spin * 1.5 + k * 2 * math.pi / 3;
      final p = c + Offset(math.cos(ang), math.sin(ang)) * r;
      canvas.drawCircle(p, 7, Paint()
        ..color = _peach.withValues(alpha: 0.35 * ignite)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(p, 2.6, Paint()..color = _blush.withValues(alpha: ignite));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.loop != loop || old.ignite != ignite;
}

/// Embers rising through the dark, a soft glow at centre and, for badges, slow light rays.
class _StagePainter extends CustomPainter {
  final double loop;
  final Color glow;
  final double rays;

  _StagePainter({required this.loop, required this.glow, required this.rays});

  static final List<(double, double, double, double)> _embers = () {
    final r = math.Random(7);
    return [for (var i = 0; i < 34; i++) (r.nextDouble(), 0.5 + r.nextDouble(), 0.8 + r.nextDouble() * 2.2, r.nextDouble())];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final breathe = (math.sin(loop * math.pi * 2) + 1) / 2;
    final glowR = size.shortestSide * (0.55 + 0.05 * breathe);
    canvas.drawCircle(
      c,
      glowR,
      Paint()..shader = RadialGradient(colors: [glow.withValues(alpha: 0.26), glow.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: glowR)),
    );

    if (rays > 0) {
      final len = size.longestSide * 0.7;
      final paint = Paint()
        ..shader = RadialGradient(colors: [_peach.withValues(alpha: 0.2 * rays), _peach.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: len));
      const count = 14;
      final turn = loop * math.pi * 2 / 3;
      for (var i = 0; i < count; i++) {
        final a = turn + i * 2 * math.pi / count;
        const half = math.pi / count / 2.2;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(c.dx + math.cos(a - half) * len, c.dy + math.sin(a - half) * len)
            ..lineTo(c.dx + math.cos(a + half) * len, c.dy + math.sin(a + half) * len)
            ..close(),
          paint,
        );
      }
    }

    for (final (x, speed, radius, phase) in _embers) {
      final p = (loop * speed * 3 + phase) % 1;
      final y = size.height * (1.05 - p * 1.1);
      final dx = math.sin((p * 3 + phase) * math.pi * 2) * 14;
      final alpha = math.sin(p * math.pi) * 0.7;
      final pos = Offset(size.width * x + dx, y);
      canvas.drawCircle(pos, radius * 2.4, Paint()
        ..color = _terracotta.withValues(alpha: alpha * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(pos, radius * 0.7, Paint()..color = _peach.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) => old.loop != loop || old.rays != rays || old.glow != glow;
}

// --- Badge ------------------------------------------------------------------------

class CardsBadgePage extends StatefulWidget {
  final BadgeDef badge;
  final String? reward;
  const CardsBadgePage({super.key, required this.badge, this.reward});

  @override
  State<CardsBadgePage> createState() => _CardsBadgePageState();
}

class _CardsBadgePageState extends State<CardsBadgePage> with TickerProviderStateMixin, _CardsTimeline {
  @override
  double get impactAt => 0.52;

  @override
  Widget build(BuildContext context) {
    final b = widget.badge;
    final tier = medalTiers[b.tier.clamp(0, medalTiers.length - 1)];
    final width = math.min(380.0, MediaQuery.sizeOf(context).width - 32);
    return stage(rays: true, glow: tier.$2, (t, l) {
      final spinP = _iv(t, 0.04, 0.52, Curves.easeOutCubic);
      final land = _iv(t, 0.04, 0.56, Motion.settle);
      final flash = _iv(t, 0.52, 0.85, Curves.easeOut);
      final sheen = t < 0.95 ? _iv(t, 0.58, 0.9) * 1.6 - 0.3 : ((l * 2) % 1) * 3 - 0.8;
      final medal = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY((1 - spinP) * math.pi * 4)
        ..scaleByDouble(0.2 + 0.8 * land, 0.2 + 0.8 * land, 1, 1);
      final bob = math.sin(l * math.pi * 2) * 4 * _iv(t, 0.6, 1);
      return SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (flash > 0 && flash < 1)
                    Container(
                      width: 150 + 140 * flash,
                      height: 150 + 140 * flash,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: tier.$1.withValues(alpha: 0.7 * (1 - flash)), width: 3 * (1 - flash) + 0.5),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, bob),
                    child: Opacity(
                      opacity: _iv(t, 0.02, 0.12),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: medal,
                        child: SizedBox(
                          width: 170,
                          height: 200,
                          child: CustomPaint(
                            painter: MedalPainter(tier: tier, rim: l * math.pi * 2, sheen: sheen),
                            child: Align(
                              alignment: const Alignment(0, -0.22),
                              child: Icon(b.icon, size: 54, color: Colors.white, shadows: [Shadow(color: tier.$3, blurRadius: 10)]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _popIn(_iv(t, 0.56, 0.8, Curves.linear), const _Kicker('Badge unlocked')),
            const SizedBox(height: 14),
            _riseIn(
              _iv(t, 0.62, 0.82),
              _shimmerText(
                Text(b.title, textAlign: TextAlign.center, style: GoogleFonts.bodoniModa(fontSize: 34, height: 1.1, fontWeight: FontWeight.w700)),
                _iv(t, 0.7, 0.98) * 1.6 - 0.3,
              ),
            ),
            const SizedBox(height: 10),
            _riseIn(
              _iv(t, 0.68, 0.88),
              Text(b.line, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14.5, height: 1.5, color: _linen.withValues(alpha: 0.82))),
            ),
            if (widget.reward != null) ...[
              const SizedBox(height: 16),
              _popIn(
                _iv(t, 0.74, 0.96, Curves.linear),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF90B4CE).withValues(alpha: 0.12),
                    border: Border.all(color: const Color(0xFF90B4CE).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.snowflake, size: 15, color: Color(0xFF90B4CE)),
                      const SizedBox(width: 8),
                      Text(widget.reward!, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: const Color(0xFFDCEBF5))),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            _riseIn(_iv(t, 0.84, 1), _GlowButton(label: 'Wear it proudly', icon: LucideIcons.award, loop: l, onTap: close)),
          ],
        ),
      );
    });
  }
}

/// A medal on a split ribbon: a turning gradient rim, a domed face, an engraved ring
/// and a band of light that glides across.
class MedalPainter extends CustomPainter {
  final (Color, Color, Color) tier;
  final double rim;
  final double sheen;

  MedalPainter({required this.tier, required this.rim, required this.sheen});

  @override
  void paint(Canvas canvas, Size size) {
    final (light, body, shadow) = tier;
    final r = size.width / 2 - 4;
    final c = Offset(size.width / 2, r + 4);

    // Ribbon tails behind the medal.
    for (final side in [-1.0, 1.0]) {
      final x = c.dx + side * r * 0.32;
      final tail = Path()
        ..moveTo(x - r * 0.24, c.dy + r * 0.5)
        ..lineTo(x + r * 0.24, c.dy + r * 0.5)
        ..lineTo(x + r * 0.24 + side * 8, size.height)
        ..lineTo(x + side * 8, size.height - 16)
        ..lineTo(x - r * 0.24 + side * 8, size.height)
        ..close();
      canvas.drawPath(tail, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shadow, body]).createShader(tail.getBounds()));
    }

    canvas.drawCircle(c + const Offset(0, 8), r, Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = SweepGradient(colors: [light, body, shadow, body, light], transform: GradientRotation(rim)).createShader(rect),
    );
    final face = r - 9;
    canvas.drawCircle(
      c,
      face,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-0.35, -0.45), radius: 1.1, colors: [light, body, shadow])
            .createShader(Rect.fromCircle(center: c, radius: face)),
    );
    canvas.drawCircle(c, face - 9, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.32));
    for (var i = 0; i < 32; i++) {
      final a = i * math.pi * 2 / 32;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (face - 4), 1.1, Paint()..color = Colors.white.withValues(alpha: 0.28));
    }

    if (sheen > -0.3 && sheen < 1.3) {
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      final x = rect.left + rect.width * sheen;
      final band = Rect.fromCenter(center: Offset(x, c.dy), width: r * 0.7, height: r * 3);
      canvas.translate(x, c.dy);
      canvas.rotate(0.45);
      canvas.translate(-x, -c.dy);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0),
          ]).createShader(band),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MedalPainter old) => old.rim != rim || old.sheen != sheen || old.tier != tier;
}

// --- Daily goal -------------------------------------------------------------------

class CardsGoalPage extends StatefulWidget {
  final GoalMoment moment;
  const CardsGoalPage({super.key, required this.moment});

  @override
  State<CardsGoalPage> createState() => _CardsGoalPageState();
}

class _CardsGoalPageState extends State<CardsGoalPage> with TickerProviderStateMixin, _CardsTimeline {
  @override
  double get impactAt => 0.55;

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    return stage((t, l) {
      final from = (m.goal - 1) / m.goal;
      final fill = from + (1 - from) * _iv(t, 0.22, 0.55, Curves.easeInOutCubic);
      final done = t >= 0.55;
      final burst = _iv(t, 0.55, 0.88, Curves.easeOut);
      return _flipIn(
        _iv(t, 0, 0.34, Motion.settle),
        _CeremonyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _riseIn(_iv(t, 0.1, 0.3), const _Kicker("Today's goal")),
              const SizedBox(height: 16),
              SizedBox.square(
                dimension: 184,
                child: CustomPaint(
                  painter: _GoalRingPainter(fill: fill, segments: m.goal, burst: burst, loop: l),
                  child: Center(
                    child: done
                        ? _popIn(_iv(t, 0.55, 0.85, Curves.linear), const Icon(LucideIcons.check, size: 64, color: _blush))
                        : Text(
                            '${m.count - 1}/${m.goal}',
                            style: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.w700, color: _linen.withValues(alpha: 0.9)),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _riseIn(
                _iv(t, 0.58, 0.78),
                _shimmerText(
                  Text('Daily goal complete!', textAlign: TextAlign.center, style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.w700)),
                  _iv(t, 0.65, 0.95) * 1.6 - 0.3,
                ),
              ),
              const SizedBox(height: 8),
              _riseIn(
                _iv(t, 0.62, 0.82),
                Text(
                  '${m.count} things done today. That is a day well kept.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: _linen.withValues(alpha: 0.8)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (final (i, (icon, value, label)) in [
                    (LucideIcons.flame, '${m.streak}', 'day streak'),
                    (LucideIcons.target, '${m.goalDays}', m.goalDays == 1 ? 'good day' : 'good days'),
                    (LucideIcons.sparkles, '${m.count}', 'done today'),
                  ].indexed)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 5, right: i == 2 ? 0 : 5),
                        child: _popIn(_iv(t, 0.66 + i * 0.06, 0.92 + i * 0.06, Curves.linear), _StatChip(icon: icon, value: value, label: label)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _riseIn(_iv(t, 0.84, 1), _GlowButton(label: 'Onward', icon: LucideIcons.arrowRight, loop: l, onTap: close)),
            ],
          ),
        ),
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: _rose.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: _rose),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: _linen)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: 11, color: _mutedLinen)),
        ],
      ),
    );
  }
}

/// The goal as a ring of segments, filling with a warm sweep; on completion a shock
/// ring flies outward.
class _GoalRingPainter extends CustomPainter {
  final double fill;
  final int segments;
  final double burst;
  final double loop;

  _GoalRingPainter({required this.fill, required this.segments, required this.burst, required this.loop});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 14;
    final rect = Rect.fromCircle(center: c, radius: r);
    const gap = 0.16;
    final seg = 2 * math.pi / segments;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.07);
    final lit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [_peach, _rose, _terracotta, _peach],
        transform: GradientRotation(-math.pi / 2 + loop * math.pi * 2),
      ).createShader(rect);
    for (var i = 0; i < segments; i++) {
      final start = -math.pi / 2 + i * seg + gap / 2;
      final sweep = seg - gap;
      canvas.drawArc(rect, start, sweep, false, track);
      final segFill = ((fill * segments) - i).clamp(0.0, 1.0);
      if (segFill > 0) canvas.drawArc(rect, start, sweep * segFill, false, lit);
    }
    if (fill >= 1) {
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = _terracotta.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }
    if (burst > 0 && burst < 1) {
      canvas.drawCircle(c, r + 50 * burst, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - burst)
        ..color = _peach.withValues(alpha: 0.8 * (1 - burst)));
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) => old.fill != fill || old.burst != burst || old.loop != loop;
}

// --- Progress toast ---------------------------------------------------------------

/// A glass pill that springs down from the top: the action's icon inside a ring that
/// fills toward today's goal, and a "+1" that pops.
class CardsProgressToast extends StatefulWidget {
  final RewardOutcome outcome;
  final VoidCallback onDone;
  const CardsProgressToast({super.key, required this.outcome, required this.onDone});

  @override
  State<CardsProgressToast> createState() => _CardsProgressToastState();
}

class _CardsProgressToastState extends State<CardsProgressToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
    ..forward().whenComplete(widget.onDone);

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? _linen : const Color(0xFF1C1917);
    final sub = dark ? _mutedLinen : const Color(0xFF6B635A);
    final over = o.count > o.goal;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final drop = _iv(t, 0, 0.24, Curves.elasticOut);
              final out = _iv(t, 0.88, 1, Curves.easeInCubic);
              final from = ((o.count - 1) / o.goal).clamp(0.0, 1.0);
              final to = (o.count / o.goal).clamp(0.0, 1.0);
              final fill = from + (to - from) * _iv(t, 0.14, 0.45, Curves.easeInOutCubic);
              final sweep = _iv(t, 0.25, 0.6) * 1.8 - 0.4;
              return Opacity(
                opacity: (_iv(t, 0, 0.06) * (1 - out)).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - drop) * -70 - out * 40),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * drop,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: dark ? const Color(0xE6141010) : Colors.white.withValues(alpha: 0.86),
                              border: Border.all(color: _rose.withValues(alpha: dark ? 0.3 : 0.4)),
                              boxShadow: [BoxShadow(color: _terracotta.withValues(alpha: 0.22), blurRadius: 26, offset: const Offset(0, 10))],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: FractionalTranslation(
                                    translation: Offset(sweep, 0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          _peach.withValues(alpha: 0),
                                          _peach.withValues(alpha: 0.22),
                                          _peach.withValues(alpha: 0),
                                        ], stops: const [0.35, 0.5, 0.65]),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox.square(
                                      dimension: 40,
                                      child: CustomPaint(
                                        painter: _MiniRingPainter(fill: fill, dark: dark),
                                        child: Icon(rewardActionIcon(o.action), size: 16, color: _terracotta),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(rewardActionLabel(o.action), style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                                          const SizedBox(height: 1),
                                          Text(
                                            over ? 'Goal met · extra credit today' : '${o.count} of ${o.goal} toward today\'s goal',
                                            style: GoogleFonts.dmSans(fontSize: 12, color: sub),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _popIn(
                                      _iv(t, 0.18, 0.5, Curves.linear),
                                      _shimmerText(
                                        Text('+1', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700)),
                                        sweep,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double fill;
  final bool dark;

  _MiniRingPainter({required this.fill, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 3;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.08));
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fill,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(colors: [_peach, _terracotta, _peach], transform: GradientRotation(-math.pi / 2)).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) => old.fill != fill || old.dark != dark;
}
