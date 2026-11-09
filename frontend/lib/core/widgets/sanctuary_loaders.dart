import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../brand/notteodo_monogram.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Signature brand loader: the NOTtEodo monogram inks itself with two ink pens,
/// catches a sheen of light, then lifts away, while a comet orbits the seal.
class MonogramLoader extends StatefulWidget {
  final double size;
  final String label;

  const MonogramLoader({
    super.key,
    this.size = 72,
    this.label = '',
  });

  @override
  State<MonogramLoader> createState() => _MonogramLoaderState();
}

class _MonogramLoaderState extends State<MonogramLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = NotteodoBrandInk.of(context);
    final markSize = widget.size * 0.58;

    final loader = SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // 0.00–0.55 draw in · 0.55–0.72 hold + sheen · 0.72–1.00 lift away from the start.
          final end = Curves.easeInOutCubic.transform((t / 0.55).clamp(0.0, 1.0));
          final start = Curves.easeInOutCubic.transform(((t - 0.72) / 0.28).clamp(0.0, 1.0));
          final sheen = t > 0.52 && t < 0.78 ? (t - 0.52) / 0.26 : null;
          final glow = math.sin((t * math.pi).clamp(0.0, math.pi));

          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _OrbitRingPainter(
                  angle: t * 2 * math.pi,
                  color: brand.accent,
                  accent: brand.support,
                  track: brand.track,
                ),
              ),
              CustomPaint(
                size: Size.square(markSize),
                painter: NotteodoMonogramPainter(
                  start: start,
                  end: end,
                  colors: [brand.accent, brand.support],
                  glow: glow,
                  sheen: sheen,
                  weight: widget.size < 56 ? 1.35 : 1.1,
                  showNibs: widget.size >= 56,
                ),
              ),
            ],
          );
        },
      ),
    );

    return Semantics(
      label: widget.label.isEmpty ? 'Loading' : widget.label,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          if (widget.label.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BreathingLabel(text: widget.label, color: brand.ink, accent: brand.accent),
          ],
        ],
      ),
    );
  }
}

/// Label whose trailing dots ripple, so a long wait still feels alive.
class _BreathingLabel extends StatefulWidget {
  final String text;
  final Color color;
  final Color accent;

  const _BreathingLabel({required this.text, required this.color, required this.accent});

  @override
  State<_BreathingLabel> createState() => _BreathingLabelState();
}

class _BreathingLabelState extends State<_BreathingLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.text.replaceAll(RegExp(r'[.…]+$'), '');
    final style = GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.2,
      color: widget.color.withValues(alpha: 0.62),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(base.toUpperCase(), style: style),
            const SizedBox(width: 3),
            for (var i = 0; i < 3; i++)
              Opacity(
                opacity: 0.25 + 0.75 * _pulse(_controller.value, i * 0.18),
                child: Text('.', style: style.copyWith(color: widget.accent)),
              ),
          ],
        );
      },
    );
  }
}

/// Inline spinner: a ink comet with a fading tail and a bright bead at its head.
/// Drop-in replacement for small `CircularProgressIndicator`s.
class OrbitLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const OrbitLoader({
    super.key,
    this.size = 18,
    this.color,
    this.strokeWidth = 2,
  });

  @override
  State<OrbitLoader> createState() => _OrbitLoaderState();
}

class _OrbitLoaderState extends State<OrbitLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = NotteodoBrandInk.of(context);
    final color = widget.color ?? brand.accent;

    return Semantics(
      label: 'Loading',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return CustomPaint(
              painter: _CometPainter(
                angle: t * 2 * math.pi,
                // The tail breathes between a short dash and a 3/4 sweep.
                sweep: math.pi * (0.55 + 0.85 * _pulse(t, 0)),
                color: color,
                strokeWidth: widget.strokeWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Three ink drops that rise in a wave, for "thinking" and typing states.
class InkDotsLoader extends StatefulWidget {
  final double dotSize;
  final List<Color>? colors;

  const InkDotsLoader({super.key, this.dotSize = 7, this.colors});

  @override
  State<InkDotsLoader> createState() => _InkDotsLoaderState();
}

class _InkDotsLoaderState extends State<InkDotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = NotteodoBrandInk.of(context);
    final palette = widget.colors ?? [brand.accent, Color.lerp(brand.accent, brand.support, 0.5)!, brand.support];
    final d = widget.dotSize;

    return Semantics(
      label: 'Thinking',
      child: SizedBox(
        height: d * 2.6,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 3; i++)
                  Builder(builder: (context) {
                    final p = _pulse(_controller.value, i * 0.16);
                    final c = palette[i % palette.length];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: d * 0.32),
                      child: Transform.translate(
                        offset: Offset(0, -p * d * 1.1),
                        child: Transform.scale(
                          scale: 0.78 + 0.22 * p,
                          child: Container(
                            width: d,
                            height: d,
                            decoration: edBox(
                              shape: BoxShape.circle,
                              color: c.withValues(alpha: 0.45 + 0.55 * p),
                              boxShadow: [
                                BoxShadow(color: c.withValues(alpha: 0.45 * p), blurRadius: d * 1.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Ink progress bar with a travelling sheen and a glowing leading bead.
/// Pass a [value] for determinate progress (changes animate smoothly) or leave it
/// null for an indeterminate glide.
class SilkProgressBar extends StatefulWidget {
  final double? value;
  final double height;
  final List<Color>? colors;
  final Color? trackColor;

  const SilkProgressBar({
    super.key,
    this.value,
    this.height = 6,
    this.colors,
    this.trackColor,
  });

  @override
  State<SilkProgressBar> createState() => _SilkProgressBarState();
}

class _SilkProgressBarState extends State<SilkProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = NotteodoBrandInk.of(context);
    final colors = widget.colors ?? [brand.accent, brand.support];
    final track = widget.trackColor ?? brand.track;
    final target = widget.value?.clamp(0.0, 1.0);

    Widget bar(double? value) => AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) => CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _SilkBarPainter(
              value: value,
              phase: _shimmer.value,
              colors: colors,
              track: track,
            ),
          ),
        );

    return Semantics(
      label: 'Progress',
      value: target == null ? null : '${(target * 100).round()}%',
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: target == null
            ? bar(null)
            : TweenAnimationBuilder<double>(
                tween: Tween(end: target),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => bar(v),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Smooth 0→1→0 pulse for a looping value with a phase offset.
double _pulse(double t, double phase) => 0.5 - 0.5 * math.cos(((t - phase) % 1.0) * 2 * math.pi);

class _OrbitRingPainter extends CustomPainter {
  final double angle;
  final Color color;
  final Color accent;
  final Color track;

  _OrbitRingPainter({required this.angle, required this.color, required this.accent, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 3;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track,
    );

    // Hairline minute track that slowly counter-rotates for depth.
    final tick = Paint()
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.28);
    for (var i = 0; i < 24; i++) {
      final a = -angle * 0.25 + i * math.pi / 12;
      final inner = r - (i % 6 == 0 ? 5.0 : 2.5);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * (r - 0.5),
        center + Offset(math.cos(a), math.sin(a)) * inner,
        tick,
      );
    }

    _CometPainter.drawComet(canvas, center, r, angle, math.pi * 0.9, color, 2.2, accent: accent);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) => old.angle != angle || old.color != color;
}

class _CometPainter extends CustomPainter {
  final double angle;
  final double sweep;
  final Color color;
  final double strokeWidth;

  _CometPainter({required this.angle, required this.sweep, required this.color, required this.strokeWidth});

  static void drawComet(
    Canvas canvas,
    Offset center,
    double r,
    double head,
    double sweep,
    Color color,
    double strokeWidth, {
    Color? accent,
  }) {
    final rect = Rect.fromCircle(center: center, radius: r);
    final tail = head - sweep;
    canvas.drawArc(
      rect,
      tail,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = accent ?? color,
    );

    final bead = center + Offset(math.cos(head), math.sin(head)) * r;
    canvas.drawCircle(
      bead,
      strokeWidth * 2.2,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 1.4),
    );
    canvas.drawCircle(bead, strokeWidth * 0.95, Paint()..color = Color.lerp(color, Colors.white, 0.55)!);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - strokeWidth * 1.5;
    drawComet(canvas, size.center(Offset.zero), r, angle, sweep, color, strokeWidth);
  }

  @override
  bool shouldRepaint(covariant _CometPainter old) =>
      old.angle != angle || old.sweep != sweep || old.color != color || old.strokeWidth != strokeWidth;
}

class _SilkBarPainter extends CustomPainter {
  final double? value;
  final double phase;
  final List<Color> colors;
  final Color track;

  _SilkBarPainter({required this.value, required this.phase, required this.colors, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final radius = Radius.circular(h / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, radius), Paint()..color = track);

    final double from;
    final double to;
    if (value == null) {
      // Indeterminate: a 35% ribbon gliding across with eased acceleration.
      final x = Curves.easeInOutSine.transform(phase) * 1.35 - 0.35;
      from = x.clamp(0.0, 1.0);
      to = (x + 0.35).clamp(0.0, 1.0);
    } else {
      from = 0;
      to = value!;
    }
    if (to <= from) return;

    final fill = Rect.fromLTRB(size.width * from, 0, size.width * to, h);
    final rrect = RRect.fromRectAndRadius(fill, radius);
    canvas.drawRRect(
      rrect.inflate(h * 0.4),
      Paint()
        ..color = colors.last.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h),
    );
    canvas.drawRRect(rrect, Paint()..color = colors.first);

    // Travelling sheen, clipped to the filled ribbon.
    canvas.save();
    canvas.clipRRect(rrect);
    final sx = fill.left + (fill.width + 80) * phase - 40;
    canvas.drawRect(
      Rect.fromLTWH(sx - 40, 0, 80, h),
      Paint()
        ..color = Colors.transparent,
    );
    canvas.restore();

    // Leading bead.
    if (fill.width > h) {
      final head = Offset(fill.right - h / 2, h / 2);
      canvas.drawCircle(
        head,
        h * 1.1,
        Paint()
          ..color = colors.last.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.8),
      );
      canvas.drawCircle(head, h * 0.32, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant _SilkBarPainter old) => old.value != value || old.phase != phase || old.track != track;
}
