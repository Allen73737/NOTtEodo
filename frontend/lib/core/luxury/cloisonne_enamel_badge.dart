import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Cloisonné Vitreous Enamel Badge
/// Semi-translucent jewel enamel fused inside 24K gold wire cell borders (cloisons).
class CloisonneEnamelBadge extends StatelessWidget {
  final String label;
  final Color enamelColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const CloisonneEnamelBadge({
    super.key,
    required this.label,
    this.enamelColor = const Color(0xFF1A2C30), // Midnight-teal enamel default
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: edBox(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37), // 24K Gold wire boundary
            width: 1.5,
          ),
          color: isDark ? const Color(0xFF1C1917) : const Color(0xFFF5EFEB),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: const Color(0xFFFFDF73)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: const Color(0xFFFFDF73),
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
