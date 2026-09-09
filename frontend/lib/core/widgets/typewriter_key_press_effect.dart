import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TypewriterKeyPressEffect extends StatelessWidget {
  final Widget child;

  const TypewriterKeyPressEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      child: child,
    );
  }
}
