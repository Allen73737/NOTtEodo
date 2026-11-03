import 'package:flutter/material.dart';

class BioluminescentGlowDrift extends StatefulWidget {
  final Widget child;

  const BioluminescentGlowDrift({super.key, required this.child});

  @override
  State<BioluminescentGlowDrift> createState() => _BioluminescentGlowDriftState();
}

class _BioluminescentGlowDriftState extends State<BioluminescentGlowDrift> with SingleTickerProviderStateMixin {
  late AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, _) {
        final val = _driftController.value;

        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 40 + (val * 30),
              right: 30 + (val * 20),
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8927C).withValues(alpha: 0.12 * val),
                  ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
