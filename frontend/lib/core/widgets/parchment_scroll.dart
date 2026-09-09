import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class ParchmentScrollCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;

  const ParchmentScrollCard({
    super.key,
    required this.title,
    required this.content,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF6E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Parchment Top Wooden Scroll Handle Roller
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C4347) : const Color(0xFFDED8C4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PARCHMENT SCROLL DOCUMENT', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                    Text(date, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 8),
                Text(content, style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor, height: 1.6)),
              ],
            ),
          ),

          // Parchment Bottom Wooden Scroll Handle Roller
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C4347) : const Color(0xFFDED8C4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
