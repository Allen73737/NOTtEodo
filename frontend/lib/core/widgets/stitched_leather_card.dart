import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class StitchedLeatherCard extends StatelessWidget {
  final String title;
  final String date;
  final String content;

  const StitchedLeatherCard({
    super.key,
    required this.title,
    required this.date,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF7F3E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9725B).withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // Stitched Thread Border Highlight
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _StitchPainter(),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('HAND-STITCHED LEATHER MEMOIR', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  ),
                  Text(date, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
              const SizedBox(height: 6),
              Text(content, style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor, height: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEAB368).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    // Top Dash
    double startX = 8.0;
    while (startX < size.width - 8) {
      canvas.drawLine(Offset(startX, 6), Offset(startX + dashWidth, 6), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
