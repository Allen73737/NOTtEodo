import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'bento_pod.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// The 5 visual evolutionary tiers for user daily streaks in NOTtEodo.
enum StreakFlameTier {
  kindlingSpark(
    level: 1,
    name: 'Kindling Spark',
    minDays: 1,
    glyph: '✨',
    badgeTitle: 'SPARK',
    description: 'A gentle ember ignited in the quiet sanctuary. The journey begins with showing up.',
    glowColor: Color(0xFFE8927C),
  ),
  brassLantern(
    level: 2,
    name: 'Brass Lantern',
    minDays: 4,
    glyph: '🏮',
    badgeTitle: 'LANTERN',
    description: 'A steady, windproof glow forged through consecutive daily discipline.',
    glowColor: Color(0xFFD9725B),
  ),
  sacredHearth(
    level: 3,
    name: 'Sacred Hearth',
    minDays: 8,
    glyph: '🔥',
    badgeTitle: 'HEARTH',
    description: 'A roaring hearth radiating clarity, creative flow, and uninterrupted momentum.',
    glowColor: Color(0xFFE07A5F),
  ),
  supernovaCorona(
    level: 4,
    name: 'Supernova Corona',
    minDays: 15,
    glyph: '⚡',
    badgeTitle: 'SUPERNOVA',
    description: 'A radiant celestial corona of compounding focus. You are unstoppable.',
    glowColor: Color(0xFFD9725B),
  ),
  sovereignPhoenix(
    level: 5,
    name: 'Golden Phoenix',
    minDays: 30,
    glyph: '👑',
    badgeTitle: 'GOLDEN PHOENIX',
    description: 'Mastery built on unyielding daily consistency and presence.',
    glowColor: Color(0xFFE8927C),
  );

  final int level;
  final String name;
  final int minDays;
  final String glyph;
  final String badgeTitle;
  final String description;
  final Color glowColor;

  const StreakFlameTier({
    required this.level,
    required this.name,
    required this.minDays,
    required this.glyph,
    required this.badgeTitle,
    required this.description,
    required this.glowColor,
  });

  static StreakFlameTier fromDays(int days) {
    if (days >= 30) return sovereignPhoenix;
    if (days >= 15) return supernovaCorona;
    if (days >= 8) return sacredHearth;
    if (days >= 4) return brassLantern;
    return kindlingSpark;
  }

  StreakFlameTier? get nextTier {
    final nextLevel = level + 1;
    for (final t in StreakFlameTier.values) {
      if (t.level == nextLevel) return t;
    }
    return null;
  }
}

/// Eye-catching visual badge that animates with a breathing aura and orbiting stardust sparks.
class StreakFlameTierBadge extends StatefulWidget {
  final int days;
  final double size;
  final bool showTierLabel;
  final VoidCallback? onTap;

  const StreakFlameTierBadge({
    super.key,
    required this.days,
    this.size = 46.0,
    this.showTierLabel = false,
    this.onTap,
  });

  @override
  State<StreakFlameTierBadge> createState() => _StreakFlameTierBadgeState();
}

class _StreakFlameTierBadgeState extends State<StreakFlameTierBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = StreakFlameTier.fromDays(widget.days);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(widget.size),
      onTap: widget.onTap ?? () {
        SanctuaryHapticEngine.selection();
        StreakFlameEvolutionSheet.show(context, widget.days);
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final pulseVal = _pulseCtrl.value;
          final haloScale = 1.0 + (0.12 * pulseVal);
          final haloOpacity = 0.25 + (0.25 * pulseVal);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ambient Halo
                  Transform.scale(
                    scale: haloScale,
                    child: Container(
                      width: widget.size * 0.95,
                      height: widget.size * 0.95,
                      decoration: edBox(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tier.glowColor.withValues(alpha: haloOpacity),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Core Badge Circle
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: edBox(
                      shape: BoxShape.circle,
                      color: tier.glowColor.withValues(alpha: isDark ? 0.16 : 0.12),
                      border: Border.all(
                        color: tier.glowColor.withValues(alpha: 0.65),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tier.glyph,
                        style: TextStyle(
                          fontSize: widget.size * 0.48,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // Orbiting Micro Sparkle for High Tiers
                  if (tier.level >= 3)
                    Transform.rotate(
                      angle: pulseVal * math.pi * 2,
                      child: Transform.translate(
                        offset: Offset(widget.size * 0.44, 0),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: edBox(
                            shape: BoxShape.circle,
                            color: tier.glowColor,
                            boxShadow: [
                              BoxShadow(
                                color: tier.glowColor,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.showTierLabel) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tier.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tier.glowColor,
                      ),
                    ),
                    Text(
                      'Tier ${tier.level} · ${widget.days}d Active',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Detailed bottom modal sheet displaying all 5 Flame Evolution Tiers and user progression.
class StreakFlameEvolutionSheet extends StatelessWidget {
  final int days;

  const StreakFlameEvolutionSheet({super.key, required this.days});

  static Future<void> show(BuildContext context, int days) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => StreakFlameEvolutionSheet(days: days),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFBF8F2) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF6B655B);
    final cardBg = isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2);
    final borderColor = isDark ? const Color(0xFF2A2622) : const Color(0xFFEADBCE);

    final currentTier = StreakFlameTier.fromDays(days);
    final nextTier = currentTier.nextTier;

    double progress = 1.0;
    int daysRemaining = 0;
    if (nextTier != null) {
      final range = nextTier.minDays - currentTier.minDays;
      final currentSpan = (days - currentTier.minDays).clamp(0, range);
      progress = (currentSpan / range).clamp(0.0, 1.0);
      daysRemaining = (nextTier.minDays - days).clamp(1, 999);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: edBox(
              color: subtextColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLAME EVOLUTION',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: currentTier.glowColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Sanctuary Fire',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: subtextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),

          // Content List
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Active Tier Hero Pod
                BentoPod(
                  style: PodTextureStyle.paper,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          StreakFlameTierBadge(
                            days: days,
                            size: 58,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentTier.name,
                                      style: GoogleFonts.bodoniModa(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: edBox(
                                        color: currentTier.glowColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: currentTier.glowColor.withValues(alpha: 0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: currentTier.glowColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentTier.description,
                                  style: GoogleFonts.spectral(
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (nextTier != null) ...[
                        const SizedBox(height: 16),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Next: ${nextTier.name}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              '$daysRemaining days remaining',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: currentTier.glowColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: isDark ? const Color(0xFF26221E) : const Color(0xFFE8DFD3),
                            valueColor: AlwaysStoppedAnimation<Color>(currentTier.glowColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // All 5 Tiers Roadmap
                Text(
                  'ALL SANCTUARY TIERS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 10),
                ...StreakFlameTier.values.map((tier) {
                  final isCurrent = tier == currentTier;
                  final isUnlocked = days >= tier.minDays;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: edBox(
                      color: isCurrent
                          ? tier.glowColor.withValues(alpha: isDark ? 0.12 : 0.08)
                          : (isDark ? const Color(0xFF1B1917) : const Color(0xFFF2ECE1)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? tier.glowColor
                            : (isUnlocked ? tier.glowColor.withValues(alpha: 0.3) : borderColor),
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: edBox(
                            shape: BoxShape.circle,
                            color: tier.glowColor.withValues(alpha: isUnlocked ? 0.18 : 0.06),
                          ),
                          child: Center(
                            child: Text(
                              tier.glyph,
                              style: TextStyle(
                                fontSize: 20,
                                color: isUnlocked ? null : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tier.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked ? primaryTextColor : subtextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${tier.minDays}d+',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tier.glowColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tier.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spectral(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Icon(LucideIcons.checkCircle2, size: 18, color: tier.glowColor)
                        else if (isUnlocked)
                          Icon(LucideIcons.check, size: 16, color: subtextColor)
                        else
                          Icon(LucideIcons.lock, size: 15, color: subtextColor.withValues(alpha: 0.5)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

