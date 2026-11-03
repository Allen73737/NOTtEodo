import '../../../core/services/device_media_service.dart';
import '../../../core/widgets/app_toast_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/polaroid_flip_card.dart';
import '../../../core/widgets/ribbon_bookmark.dart';
import '../../../core/widgets/rubber_sticker_stamp.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/motion/motion.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';

class MoodboardScreen extends ConsumerWidget {
  const MoodboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;

    final pins = ref.watch(moodboardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
              Pressable(
                pressedScale: 0.95,
                hoverLift: 0,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTextColor,
                    side: BorderSide(color: isDark ? const Color(0xFF222733) : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () async {
                    final media = await DeviceMediaService().pickImage();
                    if (media != null) {
                      ref.read(moodboardProvider.notifier).addPin(
                        title: media.name,
                        imageUrl: media.path,
                        note: 'Uploaded from device',
                      );
                      if (context.mounted) {
                        AppToastEngine().showToast(
                          context,
                          title: 'Photo Pinned',
                          message: '"${media.name}" added to Moodboard.',
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.uploadCloud, size: 14),
                  label: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              Pressable(
                pressedScale: 0.95,
                hoverLift: 0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => openEntryEditor(context, EntryKind.pin),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Pin', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              ],
            );
            final narrow = constraints.maxWidth < 520;
            final header = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIFESTYLE', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Moodboard',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!narrow) actions,
              const SizedBox(width: 8),
              const RibbonBookmark(color: AppColors.secondary, height: 48),
            ],
          );
            return narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, const SizedBox(height: 12), actions])
                : header;
          }),
          const SizedBox(height: 24),

          // Rubber Stamp Header Card
          BentoPod(
            style: PodTextureStyle.glass,
            showWashiTape: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSPIRATION BOARD',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.goldLight : AppColors.secondary,
                        ),
                      ),
                      Text(
                        'Visual Cards & Ideas',
                        style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const RubberStickerStamp(style: RubberStampStyle.curated),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (pins.isEmpty)
            EmptyState(
              icon: LucideIcons.image,
              title: 'Your board is empty',
              message: 'Pin an image link with a note to collect ideas and inspiration.',
              action: TextButton(onPressed: () => openEntryEditor(context, EntryKind.pin), child: const Text('Add a pin')),
            )
          else
          // 3D Polaroid Flip Cards List with Staggered Ripple
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pins.length,
            itemBuilder: (context, idx) {
              final pin = pins[idx];
              return Reveal(style: RevealStyle.slideIn, distance: 18, child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: StaggeredEntrance(
                  index: idx,
                  stepDelayMs: 60,
                  child: Stack(
                    children: [
                      PolaroidFlipCard(
                        title: pin.title,
                        date: pin.date,
                        imageUrl: pin.imageUrl,
                        handwrittenNote: pin.note,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Edit pin',
                            icon: const Icon(LucideIcons.pencil, size: 15, color: Colors.white),
                            onPressed: () => openEntryEditor(context, EntryKind.pin, editing: pin),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            },
          ),
        ].revealed(),
      ),
    );
  }
}
