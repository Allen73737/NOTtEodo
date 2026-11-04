import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'aesthetic_widget_models.dart';

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16282C).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 16, color: theme.accentColor),
            const SizedBox(width: 4),
            Text(
              'MEMO',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          config.customTitle ?? 'Quiet Architecture',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 16,
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
            config.customSubtitle ??
                'Simplicity is the keynote of all true elegance. Leave space between every commitment.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              height: 1.4,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.cardSurfaceColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '#ESSAY',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentColor,
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
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
    final items = [
      ('Morning horology focus', true),
      ('Draft design manifesto', true),
      ('Matcha & evening reading', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RITUALS',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.accentColor,
              ),
            ),
            Text(
              '2/3 DONE',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: theme.textMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          config.customTitle ?? 'Today’s Discipline',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.$2 ? theme.accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: item.$2 ? theme.accentColor : theme.borderColor,
                        width: 1.2,
                      ),
                    ),
                    child: item.$2
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
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

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardSurfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.landscape_rounded,
                  size: 40,
                  color: theme.accentColor.withValues(alpha: 0.4),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PIN 04',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
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
          config.customTitle ?? '“Autumn in Saint-Germain”',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 13,
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
    final palette = [
      const Color(0xFF16282C),
      const Color(0xFFD9725B),
      const Color(0xFFC9A227),
      const Color(0xFFE8EFE9),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ATELIER',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.accentColor,
              ),
            ),
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 12, color: theme.accentColor),
                const SizedBox(width: 3),
                Text(
                  '19°C',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
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
          config.customTitle ?? 'Cashmere & Wool Noir',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          'Editorial Silhouette #08',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: theme.textMutedColor,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              'PALETTE:',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: theme.textMutedColor,
              ),
            ),
            const SizedBox(width: 6),
            ...palette.map(
              (c) => Container(
                margin: const EdgeInsets.only(right: 5),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 14, color: theme.accentColor),
            const SizedBox(width: 4),
            Text(
              'TREASURY',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'DAILY ALLOTMENT',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: theme.textMutedColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          config.customTitle ?? '\$84.50',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
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
              Text(
                'Burn Rate: 34%',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              Icon(Icons.arrow_upward_rounded, size: 12, color: theme.accentColor),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMOIR',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.accentColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'REC',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          config.customTitle ?? 'Thoughts on Stillness',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: theme.textColor,
          ),
          maxLines: 1,
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
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 2.5,
                    height: (i % 2 == 0 ? 14.0 : 8.0) + (i % 3 * 3),
                    color: theme.accentColor,
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
              '02:14 / 04:30',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: theme.textMutedColor,
              ),
            ),
            Icon(Icons.play_arrow_rounded, size: 16, color: theme.textColor),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AIRMAIL PASS',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: theme.accentColor,
              ),
            ),
            Text(
              '14 DAYS',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 9,
                fontWeight: FontWeight.w700,
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
              style: TextStyle(
                fontFamily: 'Bodoni Moda',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
            Icon(Icons.flight_takeoff_rounded, size: 16, color: theme.accentColor),
            Text(
              'HND',
              style: TextStyle(
                fontFamily: 'Bodoni Moda',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: theme.cardSurfaceColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                config.customTitle ?? 'TOKYO EXPEDITION',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              Text(
                'AF274',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
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
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SANCTUARY HOROLOGY',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: theme.accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$hour:$minute',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.textColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CHRONOMÈTRE · 28,800 VPH',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.6),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: theme.accentColor.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
