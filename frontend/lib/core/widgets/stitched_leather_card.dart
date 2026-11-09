import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Clean, refined Journal Entry Card with luxury aesthetics.
/// Replaces faux skeuomorphic leather stitches with elegant bento-card craftsmanship.
class StitchedLeatherCard extends StatelessWidget {
  final String title;
  final String date;
  final String content;
  final String mood;
  final bool hasAudio;

  const StitchedLeatherCard({
    super.key,
    required this.title,
    required this.date,
    required this.content,
    this.mood = 'Reflective',
    this.hasAudio = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD4AF37);

    final badgeLabel = hasAudio || content.contains('🎙️')
        ? 'VOICE NOTE'
        : mood.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: edBox(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF22201D) : const Color(0xFFE8E2D6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: edBox(
                  color: (hasAudio ? terracotta : gold).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (hasAudio ? terracotta : gold).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAudio || content.contains('🎙️')) ...[
                      const Icon(LucideIcons.mic, size: 10, color: terracotta),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      badgeLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: hasAudio ? terracotta : gold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.bodoniModa(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: subtextColor,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
