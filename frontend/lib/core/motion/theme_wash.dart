import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Theme switch as an ink wash: a disc of the destination canvas colour blooms from
/// the last touch point, the theme flips underneath it, and the wash dissolves to
/// reveal the re-lit interface — edged by a thin hairline meniscus as it travels.
class ThemeWash extends StatefulWidget {
  final Widget child;

  /// The in-app "Reduce motion" setting; the platform setting is honoured as well.
  final bool reduceMotion;

  const ThemeWash({super.key, required this.child, this.reduceMotion = false});

  @override
  State<ThemeWash> createState() => ThemeWashState();
}

class ThemeWashState extends State<ThemeWash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Offset? _lastPointer;
  Offset _origin = Offset.zero;
  bool _toDark = true;
  VoidCallback? _pendingApply;

  static const _darkCanvas = Color(0xFF000000);
  static const _lightCanvas = Color(0xFFFAF8F5);

  /// Runs [apply] (which should flip the theme) at the peak of a wash towards [toDark].
  void play({required bool toDark, required VoidCallback apply}) {
    final view = View.of(context);
    if (widget.reduceMotion || view.platformDispatcher.accessibilityFeatures.disableAnimations) {
      apply();
      return;
    }
    if (_controller.isAnimating) {
      // A second toggle mid-wash: settle immediately on the new choice.
      _pendingApply?.call();
      _pendingApply = null;
      apply();
      return;
    }
    final size = view.physicalSize / view.devicePixelRatio;
    setState(() {
      _toDark = toDark;
      _origin = _lastPointer ?? Offset(size.width - 48, 40);
      _pendingApply = apply;
    });
    _controller.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_pendingApply != null && _controller.value >= 0.5) {
        final apply = _pendingApply!;
        _pendingApply = null;
        apply();
      }
    });
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _lastPointer = e.position,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          if (_controller.isAnimating)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: _WashPainter(
                        progress: _controller.value,
                        origin: _origin,
                        color: _toDark ? _darkCanvas : _lightCanvas,
                        rim: _toDark ? const Color(0x66FFFFFF) : const Color(0x4416282C),
                      ),
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

class _WashPainter extends CustomPainter {
  final double progress;
  final Offset origin;
  final Color color;
  final Color rim;

  _WashPainter({required this.progress, required this.origin, required this.color, required this.rim});

  @override
  void paint(Canvas canvas, Size size) {
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - origin).distance).reduce(math.max);

    if (progress <= 0.5) {
      // Bloom: the disc grows to cover the screen.
      final t = Curves.easeInOutCubic.transform(progress / 0.5);
      final r = reach * t;
      canvas.drawCircle(origin, r, Paint()..color = color);
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = rim.withValues(alpha: 0.85 * (1 - t * 0.6))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    } else {
      // Dissolve: the wash thins out from the centre, revealing the new theme.
      final t = Curves.easeOutCubic.transform((progress - 0.5) / 0.5);
      final hole = reach * t;
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addOval(Rect.fromCircle(center: origin, radius: hole));
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 1 - t));
    }
  }

  @override
  bool shouldRepaint(covariant _WashPainter old) => old.progress != progress;
}
