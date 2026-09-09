import 'package:flutter/material.dart';

class EclipsePhaseGlowHeader extends StatefulWidget {
  final double size;

  const EclipsePhaseGlowHeader({super.key, this.size = 80.0});

  @override
  State<EclipsePhaseGlowHeader> createState() => _EclipsePhaseGlowHeaderState();
}

class _EclipsePhaseGlowHeaderState extends State<EclipsePhaseGlowHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
        final offset = (_controller.value - 0.5) * widget.size * 0.4;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Golden Corona
              Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFFFFD700), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
              ),
              // Dark Moon Disc
              Transform.translate(
                offset: Offset(offset, 0),
                child: Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF000000),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
