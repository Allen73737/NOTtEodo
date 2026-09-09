import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.enamelColor = const Color(0xFF0F3854), // Royal Sapphire enamel default
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37), // 24K Gold wire boundary
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              enamelColor.withValues(alpha: 0.95),
              enamelColor,
              Color.lerp(enamelColor, Colors.black, 0.3)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: const Color(0xFFFFDF73)),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: const Color(0xFFFFDF73),
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
