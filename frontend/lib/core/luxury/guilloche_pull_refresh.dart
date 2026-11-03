import 'dart:math';
import 'package:flutter/material.dart';

/// Haute Horlogerie Guilloché Dial Shimmer Pull-to-Refresh
/// Draws procedural Rose Engine hypotrochoid curves that expand
/// with gold specular reflections as the user pulls down.
class GuillochePullRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? dialColor;
  final Color? goldColor;

  const GuillochePullRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.dialColor,
    this.goldColor,
  });

  @override
  State<GuillochePullRefresh> createState() => _GuillochePullRefreshState();
}

class _GuillochePullRefreshState extends State<GuillochePullRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  double _pullDistance = 0.0;
  bool _isRefreshing = false;
  static const double _refreshTriggerDistance = 88.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _spinController.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        setState(() {
          _isRefreshing = false;
          _pullDistance = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = widget.goldColor ?? const Color(0xFFEAB368);
    final dial = widget.dialColor ?? (isDark ? const Color(0xFF141414) : const Color(0xFFFAF7F2));

    final progress = (_pullDistance / _refreshTriggerDistance).clamp(0.0, 1.5);
    final indicatorHeight = _isRefreshing ? 74.0 : _pullDistance.clamp(0.0, 110.0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isRefreshing) return false;
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < 0) {
            setState(() {
              _pullDistance = -notification.metrics.pixels;
            });
          } else if (_pullDistance > 0) {
            setState(() => _pullDistance = 0.0);
          }
        } else if (notification is ScrollEndNotification) {
          if (_pullDistance >= _refreshTriggerDistance) {
            _handleRefresh();
          } else if (_pullDistance > 0) {
            setState(() => _pullDistance = 0.0);
          }
        }
        return false;
      },
      child: Stack(
        children: [
          // Background Guilloché Dial Chamber
          if (indicatorHeight > 4)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: indicatorHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: dial,
                  border: Border(
                    bottom: BorderSide(
                      color: gold.withValues(alpha: 0.25 * progress.clamp(0.0, 1.0)),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _spinController,
                    builder: (context, child) {
                      final spinValue = _isRefreshing
                          ? _spinController.value * 2 * pi
                          : progress * pi;
                      return CustomPaint(
                        size: const Size(64, 64),
                        painter: _GuillochePainter(
                          progress: progress,
                          angle: spinValue,
                          goldColor: gold,
                          isRefreshing: _isRefreshing,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Main Scrollable Content offset by indicator
          Transform.translate(
            offset: Offset(0, indicatorHeight),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _GuillochePainter extends CustomPainter {
  final double progress;
  final double angle;
  final Color goldColor;
  final bool isRefreshing;

  _GuillochePainter({
    required this.progress,
    required this.angle,
    required this.goldColor,
    required this.isRefreshing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) * progress.clamp(0.2, 1.0);

    // 1. Concentric Bezel Rings
    final bezelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = goldColor.withValues(alpha: 0.45);
    canvas.drawCircle(center, maxRadius, bezelPaint);
    canvas.drawCircle(center, maxRadius * 0.72, bezelPaint..strokeWidth = 0.8);

    // 2. Mathematical Rose Engine Curves (Hypotrochoid)
    const int lobes = 12;
    final double R = maxRadius * 0.7;
    final double r = R / lobes;
    final double d = r * 1.8;

    final path = Path();
    final totalSteps = (2 * pi * lobes).toInt();
    bool first = true;

    for (int i = 0; i <= totalSteps; i++) {
      final double theta = (i / lobes) + angle;
      final double x = center.dx + (R - r) * cos(theta) + d * cos((R - r) * theta / r);
      final double y = center.dy + (R - r) * sin(theta) - d * sin((R - r) * theta / r);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final guillochePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = goldColor;

    canvas.drawPath(path, guillochePaint);

    // 3. Center Horological Pivot Jewel
    final jewelPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = goldColor;
    canvas.drawCircle(center, 3.0, jewelPaint);
    canvas.drawCircle(
      center,
      1.5,
      Paint()..color = isRefreshing ? const Color(0xFF86CBB0) : Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GuillochePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.angle != angle ||
        oldDelegate.isRefreshing != isRefreshing;
  }
}
