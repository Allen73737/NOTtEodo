import 'package:flutter/material.dart';

class MagnifyingGlassLens extends StatefulWidget {
  final Widget child;

  const MagnifyingGlassLens({super.key, required this.child});

  @override
  State<MagnifyingGlassLens> createState() => _MagnifyingGlassLensState();
}

class _MagnifyingGlassLensState extends State<MagnifyingGlassLens> {
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() => _touchPos = details.localPosition);
      },
      onPanEnd: (_) => setState(() => _touchPos = null),
      child: Stack(
        children: [
          widget.child,
          if (_touchPos != null)
            Positioned(
              left: _touchPos!.dx - 40,
              top: _touchPos!.dy - 40,
              child: IgnorePointer(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8927C), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
