import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wax Seal Melting & Compression Ritual
/// Completing habit streaks triggers an interactive ritual: hot crimson wax
/// pools outward and holding your thumb compresses the molten wax into an embossed monogram stamp.
class WaxMeltCompressionRitual extends StatefulWidget {
  final VoidCallback onSealed;
  final String monogramLetter;

  const WaxMeltCompressionRitual({
    super.key,
    required this.onSealed,
    this.monogramLetter = 'N',
  });

  @override
  State<WaxMeltCompressionRitual> createState() => _WaxMeltCompressionRitualState();
}

class _WaxMeltCompressionRitualState extends State<WaxMeltCompressionRitual>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  bool _isSealed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isSealed) {
        setState(() => _isSealed = true);
        HapticFeedback.heavyImpact();
        widget.onSealed();
      }
    });
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isSealed) {
      HapticFeedback.lightImpact();
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isSealed) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (!_isSealed) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final progress = _pressController.value;
          final waxRadius = 38.0 + (progress * 14.0);

          return Container(
            width: 110,
            height: 110,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Spreading Molten Wax Pool
                Container(
                  width: waxRadius * 2,
                  height: waxRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFC0392B), // Deep Carmine
                        Color(0xFF8B0000), // Bloodstone Wax
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B0000).withValues(alpha: 0.4),
                        blurRadius: 14 + (progress * 8),
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),

                // 2. Brass Stamper Impression / Monogram
                Transform.scale(
                  scale: 0.85 + (progress * 0.15),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEAB368).withValues(alpha: 0.7 + (progress * 0.3)),
                        width: 1.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.monogramLetter,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFF0D0),
                        ),
                      ),
                    ),
                  ),
                ),

                // Helper text
                if (!_isSealed && progress < 0.1)
                  Positioned(
                    bottom: 2,
                    child: Text(
                      'HOLD TO SEAL',
                      style: GoogleFonts.dmSans(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
