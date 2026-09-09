import 'package:flutter/material.dart';

class SakuraBreezeOverlay extends StatefulWidget {
  final Widget child;

  const SakuraBreezeOverlay({super.key, required this.child});

  @override
  State<SakuraBreezeOverlay> createState() => _SakuraBreezeOverlayState();
}

class _SakuraBreezeOverlayState extends State<SakuraBreezeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _breezeController;

  @override
  void initState() {
    super.initState();
    _breezeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _breezeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breezeController,
      builder: (context, _) {
        final progress = _breezeController.value;

        return Stack(
          children: [
            widget.child,
            Positioned(
              left: progress * MediaQuery.of(context).size.width,
              top: progress * 200,
              child: Opacity(
                opacity: 0.6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECE7),
                    shape: BoxShape.circle,
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
