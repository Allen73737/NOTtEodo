import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

/// Kintsugi Golden Seam Revision History
/// Highlights modified text and diff seams with Japanese 24K gold lacquer fractures.
class KintsugiGoldSeam extends StatelessWidget {
  final String originalText;
  final String revisedText;
  final String authorOrDate;

  const KintsugiGoldSeam({
    super.key,
    required this.originalText,
    required this.revisedText,
    this.authorOrDate = 'Revision sealed',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161412) : const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _KintsugiFracturePainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'KINTSUGI REVISION SEAM',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authorOrDate,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  originalText,
                  style: GoogleFonts.spectral(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: const Color(0xFFD4AF37),
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  revisedText,
                  style: GoogleFonts.spectral(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE8E4D9) : const Color(0xFF2A2723),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KintsugiFracturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFE5C158)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFDF73).withValues(alpha: 0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    final random = math.Random(1337);
    final startY = size.height * 0.45;
    path.moveTo(0, startY);

    double currentX = 0;
    double currentY = startY;

    while (currentX < size.width) {
      currentX += 18 + random.nextDouble() * 22;
      currentY += (random.nextDouble() - 0.5) * 12;
      currentY = currentY.clamp(size.height * 0.3, size.height * 0.7);
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
