import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lost-Wax (Cire Perdue) Casting Progress Bar
/// Ancient metallurgical lost-wax casting: molten red-hot liquid bronze flows down
/// a fine jewelry sprue channel, filling engraved metric investment molds.
class CirePerdueProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;

  const CirePerdueProgressBar({
    super.key,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF100F0D) : const Color(0xFFFAF6EE);
    final borderColor = isDark ? const Color(0xFF3D331E) : const Color(0xFFE2D8C2);
    final trackBg = isDark ? const Color(0xFF080706) : const Color(0xFFEDE6D8);
    const goldColor = Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF2A201A)).withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: goldColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(clampedProgress * 100).toInt()}% CAST',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF7A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: trackBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * clampedProgress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FF5500),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
