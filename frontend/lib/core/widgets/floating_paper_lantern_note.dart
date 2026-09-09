import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingPaperLanternNote extends StatefulWidget {
  final Widget child;

  const FloatingPaperLanternNote({super.key, required this.child});

  @override
  State<FloatingPaperLanternNote> createState() => _FloatingPaperLanternNoteState();
}

class _FloatingPaperLanternNoteState extends State<FloatingPaperLanternNote>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final floatY = math.sin(_controller.value * math.pi) * 6;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  blurRadius: 16 + _controller.value * 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
