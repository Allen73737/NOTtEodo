import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/polaroid_flip_card.dart';
import '../../../core/widgets/ribbon_bookmark.dart';
import '../../../core/widgets/rubber_sticker_stamp.dart';
import '../../../core/widgets/fluid_ui_effects.dart';

class MoodboardScreen extends StatelessWidget {
  const MoodboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;

    final List<Map<String, String>> pins = [
      {
        'title': 'Minimal Editorial Glass',
        'date': 'Aug 24, 2026',
        'image': 'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?auto=format&fit=crop&w=600&q=80',
        'note': 'Inspired by Google Stitch editorial design system. Bodoni Moda headlines paired with DM Sans body typography.',
      },
      {
        'title': 'Anjuna Beach Sunset Villa',
        'date': 'Aug 22, 2026',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=600&q=80',
        'note': 'Private pool villa reserved for Goa trip. Golden hour lighting inspiration.',
      },
      {
        'title': 'Linen & Loafers Lookbook',
        'date': 'Aug 20, 2026',
        'image': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=600&q=80',
        'note': 'Beige linen shirt with olive trousers and leather loafers. Serene summer aesthetic.',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EDITORIAL VISUAL INSPIRATION', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Moodboard & Pins',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const RibbonBookmark(color: AppColors.secondary, height: 48),
            ],
          ),
          const SizedBox(height: 24),

          // Rubber Stamp Header Card
          BentoPod(
            style: PodTextureStyle.glass,
            showWashiTape: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TACTILE CURATION BOARD', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                    Text('3 Interactive 3D Flip Cards', style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
                  ],
                ),
                const RubberStickerStamp(style: RubberStampStyle.curated),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3D Polaroid Flip Cards List with Staggered Ripple
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pins.length,
            itemBuilder: (context, idx) {
              final pin = pins[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: StaggeredEntrance(
                  index: idx,
                  stepDelayMs: 60,
                  child: PolaroidFlipCard(
                    title: pin['title']!,
                    date: pin['date']!,
                    imageUrl: pin['image']!,
                    handwrittenNote: pin['note']!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
