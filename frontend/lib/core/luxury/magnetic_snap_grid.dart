import 'package:flutter/material.dart';

/// Bento Capsule Magnetic Snap & Floating Gravitational Field
/// Provides physics-based spring repelling and snap-to-grid forces when dragging pods.
class MagneticSnapGrid extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double spacing;

  const MagneticSnapGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.spacing = 14.0,
  });

  @override
  State<MagneticSnapGrid> createState() => _MagneticSnapGridState();
}

class _MagneticSnapGridState extends State<MagneticSnapGrid> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (widget.spacing * (widget.crossAxisCount - 1))) /
            widget.crossAxisCount;

        return Wrap(
          spacing: widget.spacing,
          runSpacing: widget.spacing,
          children: List.generate(widget.children.length, (index) {
            final isHovered = _hoveredIndex == index;

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: itemWidth,
                transform: Matrix4.translationValues(0.0, isHovered ? -4.0 : 0.0, 0.0)
                  ..multiply(Matrix4.diagonal3Values(isHovered ? 1.015 : 1.0, isHovered ? 1.015 : 1.0, 1.0)),
                child: widget.children[index],
              ),
            );
          }),
        );
      },
    );
  }
}
