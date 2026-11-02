import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/motion/motion.dart';

class HabitRewardsSheet extends StatefulWidget {
  final String habitTitle;
  final int streakDays;

  const HabitRewardsSheet({
    super.key,
    required this.habitTitle,
    required this.streakDays,
  });

  @override
  State<HabitRewardsSheet> createState() => _HabitRewardsSheetState();
}

class _HabitRewardsSheetState extends State<HabitRewardsSheet> with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF4F1EA) : AppColors.primary;

    return Stack(
      children: [
        // Confetti Particle Painter
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              painter: _ConfettiPainter(progress: _confettiController.value),
              size: Size.infinite,
            );
          },
        ),

        // Celebratory Dialog Container
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF142428) : AppColors.background,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.secondary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.flame, size: 38, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text('STREAK FLAME UNLOCKED!', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.secondary)),
                const SizedBox(height: 6),
                Text('${widget.streakDays}-DAY RITUAL STREAK!', style: GoogleFonts.bodoniModa(fontSize: 26, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                Text('You completed "${widget.habitTitle}". Serene consistency brings mastery!', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 24),

                Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                  label: Text('Claim Rewards & Continue', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFD9725B),
      const Color(0xFFEAB368),
      const Color(0xFF86CBB0),
      const Color(0xFFB5C9BE),
    ];

    for (int i = 0; i < 40; i++) {
      final x = (sin(i * 99 + progress * 5) * 0.5 + 0.5) * size.width;
      final y = (progress * size.height * 1.2 + i * 20) % size.height;
      final color = colors[i % colors.length];

      final p = Paint()..color = color.withValues(alpha: 1.0 - progress * 0.5);
      canvas.drawCircle(Offset(x, y), 5 + (i % 4).toDouble(), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
