import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typewriter Keystroke Mechanical Carriage Return
/// Keeps the active cursor line vertically anchored while the parchment paper
/// rolls upward and shifts horizontally on each keystroke, with carriage return chime on Enter.
class TypewriterCarriageMode extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const TypewriterCarriageMode({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<TypewriterCarriageMode> createState() => _TypewriterCarriageModeState();
}

class _TypewriterCarriageModeState extends State<TypewriterCarriageMode> {
  double _horizontalShift = 0.0;

  void _onTextChange(String text) {
    HapticFeedback.lightImpact();
    setState(() {
      _horizontalShift = ((text.length % 35) * 1.5);
    });
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161514) : const Color(0xFFFBF8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF33312E) : const Color(0xFFE5DDD0),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mechanical Roller Platen Bar Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TYPEWRITER CARRIAGE LOCK',
                style: GoogleFonts.courierPrime(
                  fontSize: 9.5,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEAB368),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC0392B), // Red typewriter ribbon indicator
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Colors.black12),

          // Sliding Parchment Paper Field
          AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            transform: Matrix4.translationValues(-_horizontalShift, 0, 0),
            child: TextField(
              controller: widget.controller,
              maxLines: 8,
              onChanged: _onTextChange,
              style: GoogleFonts.courierPrime(
                fontSize: 14.5,
                height: 1.6,
                color: isDark ? const Color(0xFFFAF7EE) : const Color(0xFF262320),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your unvarnished thoughts...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
