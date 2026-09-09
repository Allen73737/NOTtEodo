import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Astrolabe Celestial Calendar Date Picker
/// Replaces generic calendar date pickers with dual interlocking brass armillary
/// rings framing lunar phases, solar signs, and the selected day aperture.
class AstrolabeDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const AstrolabeDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<AstrolabeDatePicker> createState() => _AstrolabeDatePickerState();
}

class _AstrolabeDatePickerState extends State<AstrolabeDatePicker>
    with SingleTickerProviderStateMixin {
  late DateTime _currentDate;
  double _ringRotation = 0.0;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _shiftDay(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentDate = _currentDate.add(Duration(days: delta));
      _ringRotation += (delta * (pi / 15));
    });
    widget.onDateSelected(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFEAB368);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F10) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: goldColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CELESTIAL ASTROLABE',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: goldColor,
            ),
          ),
          const SizedBox(height: 16),

          // Central Astrolabe Rings & Date Aperture
          SizedBox(
            height: 170,
            width: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Brass Bezel with Tick Marks
                AnimatedRotation(
                  turns: _ringRotation / (2 * pi),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: CustomPaint(
                    size: const Size(170, 170),
                    painter: _AstrolabeRingPainter(goldColor: goldColor, isDark: isDark),
                  ),
                ),

                // Inner Focal Aperture Window
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF18181A) : const Color(0xFFFFFFFF),
                    border: Border.all(color: goldColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentDate.day.toString().padLeft(2, '0'),
                        style: GoogleFonts.bodoniModa(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        _getMonthName(_currentDate.month).toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Astrolabe Stepping Levers (Prev / Next Day)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, color: goldColor, size: 28),
                onPressed: () => _shiftDay(-1),
                tooltip: 'Previous Day',
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentDate.year} • SOL',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.arrow_right, color: goldColor, size: 28),
                onPressed: () => _shiftDay(1),
                tooltip: 'Next Day',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _AstrolabeRingPainter extends CustomPainter {
  final Color goldColor;
  final bool isDark;

  _AstrolabeRingPainter({required this.goldColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // 1. Outer Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = goldColor.withValues(alpha: 0.6);
    canvas.drawCircle(center, outerRadius - 2, ringPaint);

    // 2. Astrological Tick Radii
    final tickPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 36; i++) {
      final angle = i * (pi / 18);
      final isMajor = i % 3 == 0;
      final len = isMajor ? 10.0 : 5.0;

      final start = Offset(
        center.dx + (outerRadius - len - 3) * cos(angle),
        center.dy + (outerRadius - len - 3) * sin(angle),
      );
      final end = Offset(
        center.dx + (outerRadius - 3) * cos(angle),
        center.dy + (outerRadius - 3) * sin(angle),
      );

      canvas.drawLine(start, end, tickPaint..strokeWidth = isMajor ? 1.5 : 0.8);
    }
  }

  @override
  bool shouldRepaint(covariant _AstrolabeRingPainter oldDelegate) => false;
}
