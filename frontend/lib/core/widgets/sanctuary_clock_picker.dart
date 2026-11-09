import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Opens the Sovereign Horological Analog Clock Picker (Dial mode)
/// styled in terracotta, gold, and deep obsidian.
Future<TimeOfDay?> showSanctuaryClockPicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
}) async {
  SanctuaryHapticEngine.dialDetent();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final picked = await showTimePicker(
    context: context,
    initialTime: initialTime,
    initialEntryMode: TimePickerEntryMode.dial,
    helpText: helpText ?? 'SELECT TIME ON CLOCK',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: isDark ? const Color(0xFF0D0B0A) : const Color(0xFFFAF5F2),
            dialBackgroundColor: isDark ? const Color(0xFF191614) : const Color(0xFFF2ECE6),
            dialHandColor: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
            dialTextColor: isDark ? const Color(0xFFF6F3ED) : AppColors.primary,
            entryModeIconColor: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
            hourMinuteColor: isDark ? const Color(0xFF26211E) : const Color(0xFFECE4DE),
            hourMinuteTextColor: isDark ? const Color(0xFFF6F3ED) : AppColors.primary,
            dayPeriodColor: isDark ? const Color(0xFF26211E) : const Color(0xFFECE4DE),
            dayPeriodTextColor: isDark ? const Color(0xFFF6F3ED) : AppColors.primary,
            dayPeriodBorderSide: BorderSide(
              color: isDark ? const Color(0xFF332D29) : const Color(0xFFE0D4C8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0),
                width: 1,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
              textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    SanctuaryHapticEngine.escapementTick();
  }
  return picked;
}

/// A precision analog micro-clock dial custom painter that renders
/// real-time hour and minute hands like a fine horological timepiece.
class HorologicalMiniClockDial extends StatelessWidget {
  final TimeOfDay time;
  final double size;
  final Color? accentColor;

  const HorologicalMiniClockDial({
    super.key,
    required this.time,
    this.size = 36.0,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? (isDark ? const Color(0xFFE8927C) : AppColors.secondary);
    final faceColor = isDark ? const Color(0xFF1A1715) : const Color(0xFFF2ECE6);
    final borderColor = isDark ? const Color(0xFF332D29) : const Color(0xFFDED4C7);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniClockPainter(
          time: time,
          accentColor: accent,
          faceColor: faceColor,
          borderColor: borderColor,
        ),
      ),
    );
  }
}

class _MiniClockPainter extends CustomPainter {
  final TimeOfDay time;
  final Color accentColor;
  final Color faceColor;
  final Color borderColor;

  _MiniClockPainter({
    required this.time,
    required this.accentColor,
    required this.faceColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dial Face
    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    // 2. Bezel Ring
    final bezelPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 0.6, bezelPaint);

    // 3. 12 Hour Index Ticks
    final tickPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi / 6);
      final isMajor = i % 3 == 0;
      final tickLength = isMajor ? radius * 0.22 : radius * 0.12;
      final start = Offset(
        center.dx + (radius - 2.5) * math.cos(angle),
        center.dy + (radius - 2.5) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 2.5 - tickLength) * math.cos(angle),
        center.dy + (radius - 2.5 - tickLength) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // 4. Hour Hand
    final hourVal = (time.hour % 12) + (time.minute / 60.0);
    final hourAngle = (hourVal * (math.pi / 6)) - (math.pi / 2);
    final hourLength = radius * 0.50;
    final hourPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + hourLength * math.cos(hourAngle), center.dy + hourLength * math.sin(hourAngle)),
      hourPaint,
    );

    // 5. Minute Hand
    final minAngle = (time.minute * (math.pi / 30)) - (math.pi / 2);
    final minLength = radius * 0.72;
    final minPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + minLength * math.cos(minAngle), center.dy + minLength * math.sin(minAngle)),
      minPaint,
    );

    // 6. Center Jewel Pin
    final centerPin = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, centerPin);
  }

  @override
  bool shouldRepaint(covariant _MiniClockPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.borderColor != borderColor;
  }
}

/// An interactive tactile clock button displaying the micro-dial and time
class HorologicalClockBadge extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay>? onTimeChanged;
  final String label;

  const HorologicalClockBadge({
    super.key,
    required this.time,
    this.onTimeChanged,
    this.label = 'SELECT TIME',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final bg = isDark ? const Color(0xFF141210) : const Color(0xFFF7F2EC);
    final border = isDark ? const Color(0xFF26211E) : const Color(0xFFE5DDD0);

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$min $period';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTimeChanged == null
          ? null
          : () async {
              final picked = await showSanctuaryClockPicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                onTimeChanged!(picked);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: edBox(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HorologicalMiniClockDial(time: time, size: 28, accentColor: accent),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: sub,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  timeStr,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 14, color: sub),
          ],
        ),
      ),
    );
  }
}
