import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/brand/notteodo_monogram.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/widgets/sanctuary_loaders.dart';

/// Cinematic boot sequence: two ink pens ink the NOTtEodo monogram, the seal
/// catches the light, and the wordmark rises letter by letter.
///
/// Timeline (fractions of [_timeline]):
///   0.00–0.50  seal ring traces in · monogram drawn by two pens with nib sparks
///   0.48–0.66  bloom + seal ripple + sheen across the ink
///   0.50–0.80  wordmark letters rise in sequence
///   0.66–0.86  hairline rule unfurls · tagline settles
///   0.86–1.00  hold, then hand off to the app shell
class LogoRevealScreen extends StatefulWidget {
  final VoidCallback onRevealComplete;
  final bool? isDarkMode;

  const LogoRevealScreen({
    super.key,
    required this.onRevealComplete,
    this.isDarkMode,
  });

  @override
  State<LogoRevealScreen> createState() => _LogoRevealScreenState();
}

class _LogoRevealScreenState extends State<LogoRevealScreen> with TickerProviderStateMixin {
  static const String _wordmark = 'NOTtEodo';

  late final AnimationController _timeline;
  late final AnimationController _ambient;

  final List<_Mote> _motes = List.generate(26, _Mote.seeded);
  bool _hasCompleted = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Respect the OS "reduce motion" setting with a short, calm version.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _timeline.duration = const Duration(milliseconds: 1200);
    }
    _timeline.forward().whenComplete(_finishReveal);
  }

  void _finishReveal() {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    SanctuaryHapticEngine.dialDetent();
    widget.onRevealComplete();
  }

  @override
  void dispose() {
    _timeline.dispose();
    _ambient.dispose();
    super.dispose();
  }

  static double _span(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  String _stageLabel(double t) {
    if (t < 0.30) return 'Winding the movement';
    if (t < 0.60) return 'Unsealing your vault';
    if (t < 0.88) return 'Arranging your day';
    return 'Welcome';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);
    final brand = NotteodoBrandInk.forMode(isDark);
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2);
    final subtext = isDark ? const Color(0xFFA6A096) : const Color(0xFF6B7A82);

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finishReveal,
        child: AnimatedBuilder(
          animation: Listenable.merge([_timeline, _ambient]),
          builder: (context, _) {
            final t = _timeline.value;
            final bloom = _span(t, 0.42, 0.56) * (1 - 0.45 * _span(t, 0.62, 0.9));

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AtelierBackdropPainter(
                      motes: _motes,
                      drift: _ambient.value,
                      reveal: _span(t, 0.0, 0.4),
                      bloom: bloom,
                      isDark: isDark,
                      accent: brand.accent,
                      support: brand.support,
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSeal(t, bloom, brand),
                        const SizedBox(height: 34),
                        _buildWordmark(t, brand),
                        const SizedBox(height: 14),
                        _buildRule(t, brand),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _span(t, 0.70, 0.86),
                          child: Text(
                            'NOTES  ·  TASKS  ·  LIFE',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 5.0 - 1.6 * _span(t, 0.70, 0.9),
                              color: brand.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 44,
                  child: SafeArea(
                    top: false,
                    child: _buildBootFooter(t, brand, subtext),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeal(double t, double bloom, NotteodoBrandInk brand) {
    const double sealSize = 208;
    final draw = _span(t, 0.04, 0.50, Curves.easeInOutCubic);
    final sheen = t > 0.50 && t < 0.70 ? (t - 0.50) / 0.20 : null;

    return SizedBox.square(
      dimension: sealSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(sealSize),
            painter: _SealRingPainter(
              trace: _span(t, 0.0, 0.46, Curves.easeInOutCubic),
              spin: _ambient.value,
              ripple: _span(t, 0.48, 0.78, Curves.easeOutQuart),
              accent: brand.accent,
              support: brand.support,
              track: brand.track,
            ),
          ),
          CustomPaint(
            size: const Size.square(112),
            painter: NotteodoMonogramPainter(
              end: draw,
              colors: [brand.accent, Color.lerp(brand.accent, brand.support, 0.55)!],
              glow: identical(brand, NotteodoBrandInk.dark) ? 0.35 + 0.65 * bloom : 0.12 + 0.38 * bloom,
              sheen: sheen,
              weight: 1.12,
              showNibs: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordmark(double t, NotteodoBrandInk brand) {
    final style = GoogleFonts.bodoniModa(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.6,
      height: 1.0,
      color: brand.ink,
    );

    return Semantics(
      label: _wordmark,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _wordmark.length; i++)
              Builder(builder: (context) {
                final p = _span(t, 0.50 + i * 0.028, 0.66 + i * 0.028, Curves.easeOutBack);
                return Opacity(
                  opacity: p.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - p) * 18),
                    child: Text(_wordmark[i], style: style),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(double t, NotteodoBrandInk brand) {
    final p = _span(t, 0.66, 0.84, Curves.easeInOutCubic);
    return SizedBox(
      width: 200,
      height: 10,
      child: CustomPaint(painter: _AccentRulePainter(progress: p, accent: brand.accent)),
    );
  }

  Widget _buildBootFooter(double t, NotteodoBrandInk brand, Color subtext) {
    return Opacity(
      opacity: _span(t, 0.08, 0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            child: SilkProgressBar(value: t, height: 3, colors: [brand.accent, brand.support], trackColor: brand.track),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              _stageLabel(t).toUpperCase(),
              key: ValueKey(_stageLabel(t)),
              style: GoogleFonts.dmSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: subtext,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Opacity(
            opacity: 0.55 * _span(t, 0.25, 0.45),
            child: Text(
              'Tap anywhere to enter',
              style: GoogleFonts.spectral(fontSize: 12, fontStyle: FontStyle.italic, color: subtext),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline seal around the monogram: traces itself in, carries a slow comet,
/// and releases a single ripple when the mark is complete.
class _SealRingPainter extends CustomPainter {
  final double trace;
  final double spin;
  final double ripple;
  final Color accent;
  final Color support;
  final Color track;

  _SealRingPainter({
    required this.trace,
    required this.spin,
    required this.ripple,
    required this.accent,
    required this.support,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    const top = -math.pi / 2;

    // Expanding seal ripple.
    if (ripple > 0 && ripple < 1) {
      canvas.drawCircle(
        c,
        r * (0.62 + 0.55 * ripple),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * (1 - ripple) + 0.2
          ..color = accent.withValues(alpha: 0.55 * (1 - ripple)),
      );
    }

    // Outer hairline, traced clockwise from 12 o'clock.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      top,
      2 * math.pi * trace,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.55),
    );

    // Inner track ring.
    canvas.drawCircle(
      c,
      r - 14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track.withValues(alpha: trace),
    );

    // Minute ticks appear in the wake of the trace, slowly rotating.
    final tick = Paint()..strokeCap = StrokeCap.round;
    const count = 60;
    for (var i = 0; i < count; i++) {
      final frac = i / count;
      if (frac > trace) break;
      final a = top + frac * 2 * math.pi + spin * 2 * math.pi * 0.25;
      final major = i % 5 == 0;
      tick
        ..strokeWidth = major ? 1.6 : 0.9
        ..color = accent.withValues(alpha: major ? 0.7 : 0.32);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * (r - 4), c + dir * (r - (major ? 11 : 7)), tick);
    }

    // Orbiting comet once the ring is complete.
    if (trace >= 1) {
      final head = top + spin * 2 * math.pi * 3;
      const sweep = math.pi * 0.7;
      final rect = Rect.fromCircle(center: c, radius: r - 14);
      canvas.drawArc(
        rect,
        head - sweep,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.8
          ..shader = SweepGradient(
            endAngle: sweep,
            colors: [support.withValues(alpha: 0), support, accent],
            stops: const [0, 0.7, 1],
            transform: GradientRotation(head - sweep),
          ).createShader(rect),
      );
      final bead = c + Offset(math.cos(head), math.sin(head)) * (r - 14);
      canvas.drawCircle(
        bead,
        4.5,
        Paint()
          ..color = accent.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(bead, 1.8, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SealRingPainter old) =>
      old.trace != trace || old.spin != spin || old.ripple != ripple || old.accent != accent;
}

/// A ink hairline that unfurls from the centre with a diamond at its heart.
class _AccentRulePainter extends CustomPainter {
  final double progress;
  final Color accent;

  _AccentRulePainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final half = size.width / 2 * progress;
    final rect = Rect.fromLTRB(c.dx - half, c.dy - 0.5, c.dx + half, c.dy + 0.5);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: [
          accent.withValues(alpha: 0),
          accent,
          accent.withValues(alpha: 0),
        ]).createShader(rect),
    );

    final d = 3.6 * progress;
    final diamond = Path()
      ..moveTo(c.dx, c.dy - d)
      ..lineTo(c.dx + d, c.dy)
      ..lineTo(c.dx, c.dy + d)
      ..lineTo(c.dx - d, c.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _AccentRulePainter old) => old.progress != progress || old.accent != accent;
}

/// A speck of ink dust drifting through the atelier light.
class _Mote {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double sway;

  const _Mote(this.x, this.y, this.size, this.speed, this.opacity, this.sway);

  factory _Mote.seeded(int seed) {
    final rand = math.Random(seed * 739 + 17);
    return _Mote(
      rand.nextDouble(),
      rand.nextDouble(),
      rand.nextDouble() * 1.8 + 0.6,
      rand.nextDouble() * 0.5 + 0.25,
      rand.nextDouble() * 0.4 + 0.15,
      rand.nextDouble() * 2 * math.pi,
    );
  }
}

/// Soft radial light, faint guilloché rings and rising ink dust.
class _AtelierBackdropPainter extends CustomPainter {
  final List<_Mote> motes;
  final double drift;
  final double reveal;
  final double bloom;
  final bool isDark;
  final Color accent;
  final Color support;

  _AtelierBackdropPainter({
    required this.motes,
    required this.drift,
    required this.reveal,
    required this.bloom,
    required this.isDark,
    required this.accent,
    required this.support,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // The seal sits a little above centre once the wordmark stack is laid out.
    final c = Offset(size.width / 2, size.height / 2 - 70);
    final reach = size.longestSide * 0.62;

    canvas.drawCircle(
      c,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: (isDark ? 0.10 : 0.08) * reveal + 0.10 * bloom),
            support.withValues(alpha: (isDark ? 0.04 : 0.03) * reveal),
            accent.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: c, radius: reach)),
    );

    // Concentric guilloché rings, barely there.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = accent.withValues(alpha: (isDark ? 0.07 : 0.09) * reveal);
    for (var i = 1; i <= 5; i++) {
      final r = 140.0 + i * 46 + math.sin(drift * 2 * math.pi + i) * 3;
      canvas.drawCircle(c, r, ring);
    }

    final dot = Paint();
    for (final m in motes) {
      final y = (1 - ((m.y + drift * m.speed * 2) % 1.0)) * size.height;
      final x = m.x * size.width + math.sin(drift * 2 * math.pi * 2 + m.sway) * 12;
      final twinkle = 0.6 + 0.4 * math.sin(drift * 2 * math.pi * 6 + m.sway);
      dot.color = (m.size > 1.6 ? accent : (isDark ? Colors.white : accent))
          .withValues(alpha: (m.opacity * twinkle * reveal).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), m.size, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _AtelierBackdropPainter old) =>
      old.drift != drift || old.reveal != reveal || old.bloom != bloom || old.isDark != isDark;
}
