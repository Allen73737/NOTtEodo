import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Champlevé Carved Metric Bas-Relief
/// Deeply carved metal troughs filled with polished colored lacquer pigments
/// displaying budget allocation and financial reserves.
class ChampleveMetricGauge extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final Color lacquerColor;
  final String displayValue;

  const ChampleveMetricGauge({
    super.key,
    required this.label,
    required this.value,
    this.lacquerColor = const Color(0xFF1E6B52), // Deep Emerald Lacquer
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141312),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5A4D28),
          width: 1.2,
        ),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: const Color(0xFFE8927C),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayValue,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Chiseled Trough Gauge
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0909),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF332B1A), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fillWidth = constraints.maxWidth * clampedValue;
                return Stack(
                  children: [
                    Container(
                      width: fillWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: lacquerColor,
                        boxShadow: [
                          BoxShadow(
                            color: lacquerColor.withValues(alpha: 0.45),
                            blurRadius: 6,
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
