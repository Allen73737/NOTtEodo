import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'aesthetic_widget_models.dart';
import 'homescreen_fast_data_cache.dart';
import '../../motion/pressable.dart';

/// Top-level builder rendering the aesthetic Pinterest-vibe widget for any module.
class AestheticHomescreenWidgetCard extends StatelessWidget {
  final AestheticWidgetConfig config;
  final VoidCallback? onTap;

  const AestheticHomescreenWidgetCard({
    super.key,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final size = config.size;

    return Pressable(
      pressedScale: 0.97,
      hoverLift: 2,
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.85), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Subtle luxury diagonal grain
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
            ),

            // Module-specific content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: _buildModuleContent(context),
              ),
            ),

            // Top Washi Tape strip (Pinterest signature)
            Positioned(
              top: -4,
              left: size.width * 0.28,
              child: WashiTapeStrip(
                style: config.tapeStyle,
                width: 76,
                angle: -0.04,
              ),
            ),

            // Vintage postal stamp / seal (optional)
            if (config.showStamp)
              Positioned(
                top: 8,
                right: 8,
                child: VintagePostalStamp(
                  label: config.stampLabel,
                  theme: theme,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleContent(BuildContext context) {
    switch (config.type) {
      case AestheticWidgetType.stickyNote:
        return _StickyNoteContent(config: config);
      case AestheticWidgetType.ritualChecklist:
        return _RitualChecklistContent(config: config);
      case AestheticWidgetType.moodboardPolaroid:
        return _MoodboardPolaroidContent(config: config);
      case AestheticWidgetType.atelierOotd:
        return _AtelierOotdContent(config: config);
      case AestheticWidgetType.vaultTreasury:
        return _VaultTreasuryContent(config: config);
      case AestheticWidgetType.voiceMemoir:
        return _VoiceMemoirContent(config: config);
      case AestheticWidgetType.airmailTravel:
        return _AirmailTravelContent(config: config);
      case AestheticWidgetType.horologyClock:
        return _HorologyClockContent(config: config);
    }
  }
}

// -----------------------------------------------------------------------------
// 1. NOTES: Sticky Note & Quick Capture
// -----------------------------------------------------------------------------
class _StickyNoteContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _StickyNoteContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final isWide = config.size != WidgetGridSize.compact;
    final noteSnapshot = HomescreenFastDataCache().note;

    final title = config.customTitle ?? noteSnapshot?.title ?? 'Quiet Architecture';
    final subtitle = config.customSubtitle ??
        noteSnapshot?.content ??
        'Simplicity is the keynote of all true elegance. Leave space between every commitment.';
    final tagLabel = (noteSnapshot != null && noteSnapshot.tag.isNotEmpty)
        ? '#${noteSnapshot.tag.toUpperCase()}'
        : '#ESSAY';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.feather, size: 15, color: theme.accentColor),
            const SizedBox(width: 5),
            Text(
              'MEMO',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.bodoniModa(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: theme.textColor,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.45,
              color: theme.textMutedColor,
            ),
            maxLines: isWide ? 4 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.cardSurfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                tagLabel,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentColor,
              ),
              child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2. HABITS & TASKS: Daily Ritual Checklist
// -----------------------------------------------------------------------------
class _RitualChecklistContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _RitualChecklistContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final rituals = HomescreenFastDataCache().rituals;

    final items = (rituals != null && rituals.topTasks.isNotEmpty)
        ? rituals.topTasks.take(3).map((t) => (t.title, t.isCompleted)).toList()
        : const [
            ('Morning horology focus', true),
            ('Draft design manifesto', true),
            ('Matcha & evening reading', false),
          ];

    final completedCount = rituals?.habitsCompletedToday ?? items.where((i) => i.$2).length;
    final totalCount = rituals?.totalHabits ?? items.length;
    final title = config.customTitle ??
        (rituals != null && rituals.streakDays > 0
            ? 'Rituals · ${rituals.streakDays}d Streak'
            : 'Today’s Discipline');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, size: 15, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  'RITUALS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: theme.cardSurfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$completedCount/$totalCount DONE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.bodoniModa(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return Row(
                children: [
                  Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: item.$2 ? theme.accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: item.$2 ? theme.accentColor : theme.borderColor,
                        width: 1.4,
                      ),
                    ),
                    child: item.$2
                        ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: item.$2 ? theme.textMutedColor : theme.textColor,
                        decoration: item.$2 ? TextDecoration.lineThrough : null,
                        decorationColor: theme.textMutedColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. MOODBOARD: Pinterest Polaroid Pin
// -----------------------------------------------------------------------------
class _MoodboardPolaroidContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _MoodboardPolaroidContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final moodboard = HomescreenFastDataCache().moodboard;
    final title = config.customTitle ?? (moodboard != null ? '“${moodboard.title}”' : '“Autumn in Saint-Germain”');
    final tag = moodboard != null && moodboard.tag.isNotEmpty ? moodboard.tag.toUpperCase() : 'PIN 04';

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardSurfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.image,
                  size: 38,
                  color: theme.accentColor.withValues(alpha: 0.5),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.bodoniModa(
            fontSize: 14.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. WARDROBE: Atelier Vibe of the Day (OOTD)
// -----------------------------------------------------------------------------
class _AtelierOotdContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _AtelierOotdContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final wardrobe = HomescreenFastDataCache().wardrobe;
    final title = config.customTitle ?? wardrobe?.title ?? 'Cashmere & Wool Noir';
    final subtitle = wardrobe != null
        ? '${wardrobe.occasion} · ${wardrobe.vibe}'
        : 'Editorial Silhouette #08';

    final palette = [
      const Color(0xFF141414),
      const Color(0xFFD9725B),
      const Color(0xFFD4AF37),
      const Color(0xFFFAF5F2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  'OUTFIT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(LucideIcons.sun, size: 13, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  '19°C',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.bodoniModa(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 12.5,
            color: theme.textMutedColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              'PALETTE:',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.textMutedColor,
              ),
            ),
            const SizedBox(width: 8),
            ...palette.map(
              (c) => Container(
                margin: const EdgeInsets.only(right: 6),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. EXPENSES: Sovereign Treasury Ledger
// -----------------------------------------------------------------------------
class _VaultTreasuryContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _VaultTreasuryContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final treasury = HomescreenFastDataCache().treasury;

    final spentStr = config.customTitle ??
        (treasury != null
            ? '${treasury.currency}${treasury.monthlySpent.toStringAsFixed(0)}'
            : '\$84.50');
    final burnPercent = treasury != null && treasury.monthlyBudget > 0
        ? (treasury.monthlySpent / treasury.monthlyBudget * 100).round()
        : 34;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.shieldCheck, size: 15, color: theme.accentColor),
            const SizedBox(width: 5),
            Text(
              'BUDGET',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'MONTHLY OUTFLOW',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: theme.textMutedColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          spentStr,
          style: GoogleFonts.bodoniModa(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.cardSurfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Burn Rate: $burnPercent%',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              Icon(LucideIcons.trendingUp, size: 14, color: theme.accentColor),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 6. MEMOIRS: Vintage Voice Tape
// -----------------------------------------------------------------------------
class _VoiceMemoirContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _VoiceMemoirContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final voice = HomescreenFastDataCache().voice;
    final title = config.customTitle ?? voice?.title ?? 'Thoughts on Stillness';
    final duration = voice?.duration ?? '02:14 / 04:30';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.mic, size: 14, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  'VOICE NOTE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'REC',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.bodoniModa(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: theme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        // Vintage Cassette Reel Graphic
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardSurfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CassetteSpool(color: theme.textColor),
              Row(
                children: List.generate(
                  8,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 2.5,
                    height: (i % 2 == 0 ? 14.0 : 8.0) + (i % 3 * 3),
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              _CassetteSpool(color: theme.textColor),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              duration,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textMutedColor,
              ),
            ),
            Icon(LucideIcons.play, size: 16, color: theme.textColor),
          ],
        ),
      ],
    );
  }
}

class _CassetteSpool extends StatelessWidget {
  final Color color;
  const _CassetteSpool({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. TRAVEL: Airmail Travel Pass
// -----------------------------------------------------------------------------
class _AirmailTravelContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _AirmailTravelContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final travel = HomescreenFastDataCache().travel;
    final destination = config.customTitle ?? travel?.destination ?? 'Tokyo, Japan';
    final countdown = travel?.countdown ?? '14 DAYS';
    final status = travel?.status ?? 'AF274';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plane, size: 14, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  'AIRMAIL PASS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
            Text(
              countdown.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CDG',
              style: GoogleFonts.bodoniModa(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
            Icon(LucideIcons.planeTakeoff, size: 18, color: theme.accentColor),
            Text(
              'HND',
              style: GoogleFonts.bodoniModa(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.cardSurfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  destination.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 8. CLOCK: Guilloché Horology Clock
// -----------------------------------------------------------------------------
class _HorologyClockContent extends StatelessWidget {
  final AestheticWidgetConfig config;
  const _HorologyClockContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = config.paperTheme;
    final horology = HomescreenFastDataCache().horology;
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final quote = config.customSubtitle ??
        horology?.quote ??
        '“Time is the substance from which I am made.”';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clock, size: 14, color: theme.accentColor),
            const SizedBox(width: 4),
            Text(
              'FOCUS CLOCK',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$hour:$minute',
          style: GoogleFonts.bodoniModa(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.textColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          quote,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: theme.textMutedColor,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Aesthetic Visual Details: Washi Tape & Postal Stamp
// -----------------------------------------------------------------------------
class WashiTapeStrip extends StatelessWidget {
  final WashiTapeStyle style;
  final double width;
  final double height;
  final double angle;

  const WashiTapeStrip({
    super.key,
    required this.style,
    this.width = 72,
    this.height = 18,
    this.angle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, height),
        painter: _WashiTapePainter(color: style.color),
      ),
    );
  }
}

class _WashiTapePainter extends CustomPainter {
  final Color color;
  const _WashiTapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Left torn edge
    path.moveTo(0, 0);
    const teeth = 5;
    final toothH = size.height / teeth;
    for (int i = 0; i < teeth; i++) {
      path.lineTo(i.isEven ? 3.0 : 0.0, (i + 1) * toothH);
    }
    // Bottom
    path.lineTo(size.width, size.height);
    // Right torn edge
    for (int i = teeth; i > 0; i--) {
      path.lineTo(size.width - (i.isEven ? 3.0 : 0.0), (i - 1) * toothH);
    }
    // Top
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WashiTapePainter oldDelegate) => oldDelegate.color != color;
}

class VintagePostalStamp extends StatelessWidget {
  final String label;
  final AestheticPaperTheme theme;

  const VintagePostalStamp({
    super.key,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.7),
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: theme.accentColor.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
