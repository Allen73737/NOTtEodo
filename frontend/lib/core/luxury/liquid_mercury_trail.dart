import 'package:flutter/material.dart';

/// Liquid Mercury Cursor & Touch Trail
/// Renders an organic viscous droplet that glides behind touch and cursor
/// interactions with surface tension elasticity and metallic specular sheen.
class LiquidMercuryTrail extends StatefulWidget {
  final Widget child;
  final bool enableTrail;

  const LiquidMercuryTrail({
    super.key,
    required this.child,
    this.enableTrail = true,
  });

  @override
  State<LiquidMercuryTrail> createState() => _LiquidMercuryTrailState();
}

class _LiquidMercuryTrailState extends State<LiquidMercuryTrail>
    with SingleTickerProviderStateMixin {
  final List<Offset> _points = [];
  Offset _currentPos = Offset.zero;
  bool _isVisible = false;
  late AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_decayTrail)
      ..repeat();
  }

  void _decayTrail() {
    if (_points.isNotEmpty && mounted) {
      setState(() {
        if (_points.length > 1) {
          _points.removeAt(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event) {
    if (!widget.enableTrail) return;
    setState(() {
      _currentPos = event.localPosition;
      _isVisible = true;
      _points.add(event.localPosition);
      if (_points.length > 8) {
        _points.removeAt(0);
      }
    });
  }

  void _onPointerExit(PointerEvent event) {
    setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onPointerMove,
      onExit: _onPointerExit,
      child: Listener(
        onPointerMove: _onPointerMove,
        onPointerUp: (_) => setState(() => _isVisible = false),
        child: Stack(
          children: [
            widget.child,
            if (_isVisible && widget.enableTrail)
              IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MercuryDropletPainter(
                    currentPos: _currentPos,
                    trail: List.from(_points),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MercuryDropletPainter extends CustomPainter {
  final Offset currentPos;
  final List<Offset> trail;

  _MercuryDropletPainter({required this.currentPos, required this.trail});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw trail connecting droplets
    for (int i = 0; i < trail.length; i++) {
      final t = (i + 1) / trail.length;
      final radius = 3.5 + (t * 6.5);
      final alpha = (t * 0.45).clamp(0.0, 1.0);

      final trailPaint = Paint()
        ..color = const Color(0xFFD4D8E0).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(trail[i], radius, trailPaint);
    }

    // 2. Main High-Surface-Tension Mercury Orb
    const orbRadius = 10.0;
    final orbRect = Rect.fromCircle(center: currentPos, radius: orbRadius);

    // Mercury Sphere
    canvas.drawCircle(currentPos, orbRadius, Paint()..color = const Color(0xFFC0C4CC));

    // High specular glint dot
    final glintPos = currentPos + const Offset(-3, -3);
    canvas.drawCircle(glintPos, 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MercuryDropletPainter oldDelegate) {
    return oldDelegate.currentPos != currentPos || oldDelegate.trail.length != trail.length;
  }
}
