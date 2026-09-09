import 'dart:math';
import 'package:flutter/material.dart';

class OrigamiUnfoldModal extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;

  const OrigamiUnfoldModal({
    super.key,
    required this.child,
    required this.onClose,
  });

  @override
  State<OrigamiUnfoldModal> createState() => _OrigamiUnfoldModalState();
}

class _OrigamiUnfoldModalState extends State<OrigamiUnfoldModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _unfoldAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _unfoldAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _unfoldAnimation,
      builder: (context, child) {
        final angle = (1.0 - _unfoldAnimation.value) * (pi / 2);
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle)
            ..multiply(Matrix4.diagonal3Values(_unfoldAnimation.value, _unfoldAnimation.value, 1.0)),
          alignment: Alignment.center,
          child: widget.child,
        );
      },
    );
  }
}
