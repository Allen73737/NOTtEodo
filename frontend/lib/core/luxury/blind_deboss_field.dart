import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blind Deboss Indented Text Field
/// Models a physical letterpress debossed impression stamped deeply
/// into premium cotton rag cardstock with directional inner shadows.
class BlindDebossField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const BlindDebossField({
    super.key,
    this.controller,
    required this.label,
    this.hintText = '',
    this.prefixIcon,
    this.obscureText = false,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFEAB368);

    final debossBg = isDark ? const Color(0xFF0D0D0E) : const Color(0xFFEFE9DE);
    final innerTopShadow = isDark ? Colors.black : const Color(0xFFCDC4B5);
    final innerBottomLight = isDark ? const Color(0xFF222225) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: isDark ? const Color(0xFF9E9A92) : const Color(0xFF6B655B),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: debossBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF242428) : const Color(0xFFD8CFBF),
              width: 1.2,
            ),
            boxShadow: [
              // Top-left inset dark shadow
              BoxShadow(
                color: innerTopShadow.withValues(alpha: isDark ? 0.9 : 0.6),
                offset: const Offset(1.5, 2.5),
                blurRadius: 4,
                spreadRadius: -1,
              ),
              // Bottom-right rim specular edge
              BoxShadow(
                color: innerBottomLight.withValues(alpha: isDark ? 0.12 : 0.8),
                offset: const Offset(-1, -1),
                blurRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            maxLines: maxLines,
            onChanged: onChanged,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: hintText,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 18, color: goldColor.withValues(alpha: 0.8))
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
