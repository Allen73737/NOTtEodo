import 'package:flutter/material.dart';

class SunbeamShadowPass extends StatefulWidget {
  final Widget child;

  const SunbeamShadowPass({super.key, required this.child});

  @override
  State<SunbeamShadowPass> createState() => _SunbeamShadowPassState();
}

class _SunbeamShadowPassState extends State<SunbeamShadowPass> with SingleTickerProviderStateMixin {
  late AnimationController _sunbeamController;

  @override
  void initState() {
    super.initState();
    _sunbeamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sunbeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sunbeamController,
      builder: (context, _) {
        final val = _sunbeamController.value;

        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05 + (val * 0.04),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
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
