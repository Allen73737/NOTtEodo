import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Torricellian Barometer Mercury Pressure Gauge
/// 19th-century blown glass and polished brass mercury barometer tracking
/// daily task density and cognitive atmospheric pressure with convex meniscus curves.
class TorricelliBarometerGauge extends StatelessWidget {
  final double pressureRatio; // 0.0 to 1.0 (e.g. 740mmHg to 780mmHg)
  final String statusDescription;

  const TorricelliBarometerGauge({
    super.key,
    required this.pressureRatio,
    this.statusDescription = '762 mmHg · Serene Atmosphere',
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = pressureRatio.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF100F0D) : const Color(0xFFFAF6EE);
    final borderColor = isDark ? const Color(0xFF3D331E) : const Color(0xFFE2D8C2);
    final tubeBg = isDark ? const Color(0xFF080706) : const Color(0xFFEDE6D8);
    const titleColor = Color(0xFFD4AF37);
    final textColor = isDark ? const Color(0xFFF2ECE1) : const Color(0xFF1C1B18);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF6E685E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: edBox(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF2A201A)).withValues(alpha: isDark ? 0.4 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TORRICELLIAN BAROMETER',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: titleColor,
                ),
              ),
              const Icon(Icons.compress, size: 16, color: titleColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Vertical Mercury Column Tube
              Container(
                width: 14,
                height: 100,
                decoration: edBox(
                  color: tubeBg,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: clampedRatio,
                      child: Container(
                        decoration: edBox(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                          color: const Color(0xFFB0B7C3),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0x66D4D8E0),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusDescription,
                      style: GoogleFonts.spectral(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cognitive density load is within optimal equilibrium reserves.',
                      style: GoogleFonts.spectral(
                        fontSize: 12,
                        height: 1.35,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
