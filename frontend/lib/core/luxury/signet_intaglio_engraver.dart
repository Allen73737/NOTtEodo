import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Bespoke Signet Ring Intaglio Engraver
/// Carved gold and carnelian signet ring face: custom interlocking cipher monogram
/// for personal wax stamping and cryptographic key identification.
class SignetIntaglioEngraver extends StatelessWidget {
  final String monogram;
  final double size;

  const SignetIntaglioEngraver({
    super.key,
    this.monogram = 'NV',
    this.size = 88.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size * 1.15,
      decoration: edBox(
        borderRadius: BorderRadius.circular(size * 0.45),
        border: Border.all(color: const Color(0xFFB5505E), width: 2.2),
        color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFF3ECE0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x33B5505E),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          monogram.toUpperCase(),
          style: GoogleFonts.cinzelDecorative(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: const Color(0xFFE2B6BB),
            shadows: const [
              Shadow(
                color: Colors.black87,
                offset: Offset(1.5, 2.0),
                blurRadius: 3.0,
              ),
              Shadow(
                color: Color(0xFFB5505E),
                offset: Offset(-0.8, -0.8),
                blurRadius: 1.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
