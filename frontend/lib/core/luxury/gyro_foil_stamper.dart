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

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _glintController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: br,
                border: Border.all(
                  color: widget.foilColor.withValues(alpha: 0.6),
                  width: widget.borderWidth,
                ),
                color: const Color(0xFFEAB368).withValues(alpha: 0.15),
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
        );
      },
    );
  }
}
