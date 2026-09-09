import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Container(
      width: size,
      height: size * 1.15,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.45),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2.2),
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.3),
          colors: [
            Color(0xFF8B2500), // Deep Carnelian Red Stone
            Color(0xFF5A1400),
            Color(0xFF2E0A00),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x33D4AF37),
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
            color: const Color(0xFFFFDF73),
            shadows: const [
              Shadow(
                color: Colors.black87,
                offset: Offset(1.5, 2.0),
                blurRadius: 3.0,
              ),
              Shadow(
                color: Color(0xFFD4AF37),
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
