import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class StickyNotesFloatCanvas extends StatefulWidget {
  final Widget child;

  const StickyNotesFloatCanvas({super.key, required this.child});

  @override
  State<StickyNotesFloatCanvas> createState() => _StickyNotesFloatCanvasState();
}

class _StickyNotesFloatCanvasState extends State<StickyNotesFloatCanvas> {
  final List<Map<String, dynamic>> _notes = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._notes.map((n) {
          return Positioned(
            left: (n['pos'] as Offset).dx,
            top: (n['pos'] as Offset).dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  n['pos'] = (n['pos'] as Offset) + details.delta;
                });
              },
              child: Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: n['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 6),
                    ),
                  ],
                ),
                child: Text(
                  n['text'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
