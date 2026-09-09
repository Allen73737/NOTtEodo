import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

class WaxSealMeltCanvas extends StatefulWidget {
  final Widget child;
  final String sealInitial;
  final VoidCallback? onSealed;

  const WaxSealMeltCanvas({
    super.key,
    required this.child,
    this.sealInitial = 'N',
    this.onSealed,
  });

  @override
  State<WaxSealMeltCanvas> createState() => _WaxSealMeltCanvasState();
}

class _WaxSealMeltCanvasState extends State<WaxSealMeltCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _sealController;
  late Animation<double> _meltAnimation;
  late Animation<double> _stampAnimation;
  bool _isSealed = false;

  @override
  void initState() {
    super.initState();
    _sealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _meltAnimation = CurvedAnimation(
      parent: _sealController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _stampAnimation = CurvedAnimation(
      parent: _sealController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _sealController.dispose();
    super.dispose();
  }

  void _triggerSeal() {
    if (_isSealed) return;
    HapticFeedback.heavyImpact();
    setState(() => _isSealed = true);
    _sealController.forward(from: 0.0).then((_) {
      if (widget.onSealed != null) widget.onSealed!();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _triggerSeal,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_isSealed)
            AnimatedBuilder(
              animation: _sealController,
              builder: (context, _) {
                final meltScale = _meltAnimation.value;
                final stampScale = _stampAnimation.value;

                return Positioned(
                  top: 16,
                  right: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Liquid Wax Melt Puddle
                      CustomPaint(
                        size: Size(54 * meltScale, 54 * meltScale),
                        painter: _LiquidWaxPainter(progress: meltScale),
                      ),
                      // Embossed Initial Stamp
                      Transform.scale(
                        scale: stampScale,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFC05640),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE8927C), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              widget.sealInitial,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFEF9EE),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LiquidWaxPainter extends CustomPainter {
  final double progress;

  _LiquidWaxPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path();
    const points = 12;
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final offsetRadius = radius + math.sin(angle * 3 + progress * math.pi) * 4 * progress;
      final x = center.dx + offsetRadius * math.cos(angle);
      final y = center.dy + offsetRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWaxPainter oldDelegate) => oldDelegate.progress != progress;
}
