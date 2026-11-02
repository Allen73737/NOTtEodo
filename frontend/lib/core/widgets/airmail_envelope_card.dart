import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class AirmailEnvelopeCard extends StatelessWidget {
  final String title;
  final String flight;
  final String destination;
  final String date;

  const AirmailEnvelopeCard({
    super.key,
    required this.title,
    required this.flight,
    required this.destination,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.goldBorderDark : const Color(0xFFE5DFC9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF2A201A)).withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Airmail Top Diagonal Stripes
          SizedBox(
            height: 10,
            child: CustomPaint(
              painter: _AirmailStripePainter(),
              size: Size.infinite,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9725B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PAR AVION · AIR MAIL',
                          style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFD9725B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Postmark: $date',
                        style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Flight: $flight · Dest: $destination',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldLight : AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.flight_takeoff,
                      size: 18,
                      color: isDark ? AppColors.goldLight : AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AirmailStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = const Color(0xFF2C4347);
    final redPaint = Paint()..color = const Color(0xFFD9725B);

    double x = 0;
    bool isRed = true;

    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 16, size.height), isRed ? redPaint : bluePaint);
      x += 24;
      isRed = !isRed;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
