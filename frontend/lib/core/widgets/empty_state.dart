import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';

/// Standard empty state: a softly breathing icon with paper slips drifting around it,
/// a serif headline and one line of guidance. Use one per empty list across modules.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 7))
    ..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtext = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final paper = isDark ? const Color(0xFF141414) : Colors.white;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          SizedBox(
            width: 168,
            height: 118,
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) => CustomPaint(
                painter: _SlipsPainter(
                  t: Motion.reduced(context) ? 0 : _drift.value,
                  paper: paper,
                  edge: ink.withValues(alpha: isDark ? 0.18 : 0.12),
                  accent: accent,
                ),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, math.sin(_drift.value * math.pi * 2) * 3),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.12),
                        border: Border.all(color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Icon(widget.icon, size: 26, color: accent),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: ink),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, height: 1.45, color: subtext),
            ),
          ),
          if (widget.action != null) ...[
            const SizedBox(height: 18),
            widget.action!,
          ],
        ],
      ),
    ),
  );
  }
}

/// Four paper slips circling symmetrically behind the icon, balanced across quadrants.
class _SlipsPainter extends CustomPainter {
  final double t;
  final Color paper;
  final Color edge;
  final Color accent;

  _SlipsPainter({required this.t, required this.paper, required this.edge, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 4; i++) {
      final phase = t * math.pi * 2 + i * math.pi / 2;
      final pos = c + Offset(math.cos(phase) * 54, math.sin(phase) * 22);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.sin(phase) * 0.28 + (i.isEven ? 0.15 : -0.15));
      final rect = RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -18, 28, 36), const Radius.circular(4));
      canvas.drawRRect(rect.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.06));
      canvas.drawRRect(rect, Paint()..color = paper);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = edge,
      );
      final rule = Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      rule.color = accent.withValues(alpha: 0.55);
      canvas.drawLine(const Offset(-8, -8), const Offset(6, -8), rule);
      rule.color = edge;
      canvas.drawLine(const Offset(-8, -2), const Offset(8, -2), rule);
      canvas.drawLine(const Offset(-8, 4), const Offset(4, 4), rule);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SlipsPainter old) => old.t != t || old.paper != paper;
}
