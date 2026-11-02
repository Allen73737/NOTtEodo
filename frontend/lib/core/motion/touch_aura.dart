import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// App-wide touch feedback: every press emits a fine ink ring and a few sparks at the
/// contact point, so every element — not only Material buttons — answers the finger.
///
/// Sits above the app as a non-interactive layer and only ticks while rings are alive.
class TouchAura extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const TouchAura({super.key, required this.child, required this.isDark});

  @override
  State<TouchAura> createState() => _TouchAuraState();
}

class _Ring {
  final Offset origin;
  final Duration born;
  final double seed;

  _Ring(this.origin, this.born, this.seed);
}

class _TouchAuraState extends State<TouchAura> with SingleTickerProviderStateMixin {
  static const Duration _life = Duration(milliseconds: 520);
  static const int _maxRings = 6;

  late final Ticker _ticker;
  final ValueNotifier<Duration> _clock = ValueNotifier(Duration.zero);
  final List<_Ring> _rings = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  void _tick(Duration elapsed) {
    _clock.value = elapsed;
    _rings.removeWhere((r) => elapsed - r.born > _life);
    if (_rings.isEmpty) _ticker.stop();
  }

  void _onDown(PointerDownEvent e) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    if (!_ticker.isActive) {
      _clock.value = Duration.zero;
      _ticker.start();
    }
    if (_rings.length >= _maxRings) _rings.removeAt(0);
    _rings.add(_Ring(e.position, _clock.value, _random.nextDouble()));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _AuraPainter(
                    rings: _rings,
                    clock: _clock,
                    life: _life,
                    // Neutral ink: white on black, midnight teal on cream.
                    color: widget.isDark ? const Color(0xFFFFFFFF) : const Color(0xFF16282C),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  final List<_Ring> rings;
  final ValueNotifier<Duration> clock;
  final Duration life;
  final Color color;

  _AuraPainter({required this.rings, required this.clock, required this.life, required this.color}) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.value;
    for (final ring in rings) {
      final t = ((now - ring.born).inMicroseconds / life.inMicroseconds).clamp(0.0, 1.0);
      final ease = Curves.easeOutCubic.transform(t);
      final fade = 1 - Curves.easeIn.transform(t);

      canvas.drawCircle(
        ring.origin,
        6 + 26 * ease,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * fade + 0.2
          ..color = color.withValues(alpha: 0.32 * fade),
      );

      // Five sparks thrown outward on a slightly randomised rosette.
      final spark = Paint()..color = color.withValues(alpha: 0.45 * fade);
      for (var i = 0; i < 5; i++) {
        final a = ring.seed * math.pi * 2 + i * math.pi * 2 / 5;
        final d = 8 + 30 * ease;
        canvas.drawCircle(ring.origin + Offset(math.cos(a), math.sin(a)) * d, 1.3 * fade, spark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) => old.color != color;
}
