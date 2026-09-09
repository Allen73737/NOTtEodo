import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141312),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5A4920), width: 1.2),
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
                  color: const Color(0xFFD4AF37),
                ),
              ),
              const Icon(Icons.compress, size: 16, color: Color(0xFFD4AF37)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Vertical Mercury Column Tube
              Container(
                width: 14,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0B0A),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFF8A7322), width: 1),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FractionallySizedBox(
                      heightFactor: clampedRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFE2E6EE),
                              Color(0xFFA8B0BE),
                              Color(0xFF6B7280),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4D8E0).withValues(alpha: 0.5),
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
                        color: const Color(0xFFE8E4D9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cognitive density load is within optimal equilibrium reserves.',
                      style: GoogleFonts.spectral(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.white54,
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
