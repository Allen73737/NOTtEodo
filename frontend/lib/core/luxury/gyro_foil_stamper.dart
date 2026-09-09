import 'dart:math';
import 'package:flutter/material.dart';

/// Foil Stamping Emboss Light Reflector
/// Dynamically sweeps metallic specular glints across embossed foil text and badges
/// driven by pointer coordinates or gyroscopic orientation.
class GyroFoilStamper extends StatefulWidget {
  final Widget child;
  final Color foilColor;
  final Color baseColor;
  final double borderWidth;
  final BorderRadius? borderRadius;

  const GyroFoilStamper({
    super.key,
    required this.child,
    this.foilColor = const Color(0xFFEAB368),
    this.baseColor = const Color(0xFFB8860B),
    this.borderWidth = 1.5,
    this.borderRadius,
  });

  @override
  State<GyroFoilStamper> createState() => _GyroFoilStamperState();
}

class _GyroFoilStamperState extends State<GyroFoilStamper>
    with SingleTickerProviderStateMixin {
  late AnimationController _glintController;
  Offset _pointerOffset = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _glintController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _glintController.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerEvent event, BoxConstraints constraints) {
    setState(() {
      _pointerOffset = Offset(
        (event.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
        (event.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onPointerHover(e, constraints),
          child: AnimatedBuilder(
            animation: _glintController,
            builder: (context, child) {
              // Combine continuous idle shimmer with pointer position
              final sweepT = (_glintController.value * 2 * pi) + (_pointerOffset.dx * pi);
              final glintAngle = sweepT % (2 * pi);

              return Container(
                decoration: BoxDecoration(
                  borderRadius: br,
                  border: Border.all(
                    color: widget.foilColor.withValues(alpha: 0.6),
                    width: widget.borderWidth,
                  ),
                  gradient: SweepGradient(
                    center: Alignment(
                      (_pointerOffset.dx * 2) - 1.0,
                      (_pointerOffset.dy * 2) - 1.0,
                    ),
                    colors: [
                      widget.baseColor.withValues(alpha: 0.15),
                      widget.foilColor.withValues(alpha: 0.35),
                      const Color(0xFFFFF7EA).withValues(alpha: 0.8),
                      widget.foilColor.withValues(alpha: 0.35),
                      widget.baseColor.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    transform: GradientRotation(glintAngle),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.foilColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.child,
              );
            },
          ),
        );
      },
    );
  }
}
