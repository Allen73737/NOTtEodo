import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clous de Paris (Hobnail) Tactile Surface Toggle
/// 3D pyramid guilloché toggle with diamond-faceted specular lighting on state change.
class ClousDeParisToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const ClousDeParisToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 64.0,
    this.height = 36.0,
  });

  @override
  State<ClousDeParisToggle> createState() => _ClousDeParisToggleState();
}

class _ClousDeParisToggleState extends State<ClousDeParisToggle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: widget.value
                ? const Color(0xFFD4AF37)
                : const Color(0xFF8A8478).withValues(alpha: 0.4),
            width: 1.5,
          ),
          color: widget.value ? const Color(0xFFD4AF37) : const Color(0xFF1E1E20),
          boxShadow: [
            BoxShadow(
              color: widget.value
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                  : Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment:
                  widget.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: widget.height - 6,
                height: widget.height - 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.value ? const Color(0xFFFFF0D0) : const Color(0xFFE8E8E8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _HobnailTexturePainter(isActive: widget.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HobnailTexturePainter extends CustomPainter {
  final bool isActive;

  _HobnailTexturePainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isActive ? const Color(0xFF7A6214) : const Color(0xFF404040))
          .withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Small 2x2 hobnail grid indentations
    final step = size.width / 3;
    for (int r = 1; r <= 2; r++) {
      for (int c = 1; c <= 2; c++) {
        canvas.drawCircle(Offset(c * step, r * step), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HobnailTexturePainter oldDelegate) =>
      oldDelegate.isActive != isActive;
}
