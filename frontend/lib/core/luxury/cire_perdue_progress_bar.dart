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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131210),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF523D1F), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              Text(
                '${(clampedProgress * 100).toInt()}% CAST',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: const Color(0xFFFF7A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF090807),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF382914), width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * clampedProgress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B3A0F),
                            Color(0xFFFF5500),
                            Color(0xFFFFB347),
                          ],
                        ),
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
