import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../systems/aesthetic_audio_service.dart';
import 'sparkle_explosion.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Full-screen celebratory Duolingo-style milestone achievement dialog.
/// Triggered when the user hits major streak milestones (Day 3, 7, 14, 30, 100).
class StreakMilestoneCelebrationDialog extends StatefulWidget {
  final int milestone;
  final int freezesAvailable;

  const StreakMilestoneCelebrationDialog({
    super.key,
    required this.milestone,
    required this.freezesAvailable,
  });

  static Future<void> show(
    BuildContext context, {
    required int milestone,
    required int freezesAvailable,
  }) async {
    HapticFeedback.heavyImpact();
    AestheticAudioService().playHapticTone(type: 'ritual');
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Milestone Celebration',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => StreakMilestoneCelebrationDialog(
        milestone: milestone,
        freezesAvailable: freezesAvailable,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<StreakMilestoneCelebrationDialog> createState() => _StreakMilestoneCelebrationDialogState();
}

class _StreakMilestoneCelebrationDialogState extends State<StreakMilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String _getMilestoneTitle() {
    switch (widget.milestone) {
      case 3:
        return 'Spark Ignited';
      case 7:
        return 'Flame Keeper';
      case 14:
        return 'Iron Will';
      case 30:
        return 'Sanctuary Master';
      case 100:
        return 'Centurion of Focus';
      default:
        return '${widget.milestone} Days of Grandeur';
    }
  }

  String _getMilestoneDescription() {
    switch (widget.milestone) {
      case 3:
        return 'Three deliberate days in a row. Your momentum is starting to build!';
      case 7:
        return 'One unbroken week of sanctuary discipline. You are among the top 10% of deliberate curators.';
      case 14:
        return 'Two weeks of pure focus. Consistency has now turned into a natural instinct.';
      case 30:
        return 'One whole month of unwavering commitment. Your habits define your craft.';
      case 100:
        return 'A rare century of discipline. 100 days of relentless, deliberate growth.';
      default:
        return 'Your unbroken commitment continues to elevate your daily sanctuary.';
    }
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD9725B);
    const terracotta = Color(0xFFE8927C);
    const darkCard = Color(0xFF141312);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle confetti explosion
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SparkleExplosion(
                    position: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                    particleCount: 40,
                    onComplete: () {},
                  );
                },
              ),
            ),
          ),

          // Central Milestone Card
          Container(
            width: 340,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            margin: const EdgeInsets.all(20),
            decoration: edBox(
              color: darkCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: gold.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: terracotta.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Glowing Flame Crest
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final glow = _glowController.value;
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: edBox(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFE8927C), Color(0xFF8A3022), Color(0xFF1A0A08)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: terracotta.withValues(alpha: 0.4 + (glow * 0.35)),
                              blurRadius: 20 + (glow * 14),
                              spreadRadius: 2 + (glow * 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🔥', style: TextStyle(fontSize: 40)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Milestone Title
                  Text(
                    '${widget.milestone}-DAY STREAK!',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: const Color(0xFFFAF7F2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Honorific Badge Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: edBox(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _getMilestoneTitle().toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text(
                    _getMilestoneDescription(),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.5,
                      color: const Color(0xFFB5AE9F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Bonus Streak Freeze Award Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: edBox(
                      color: const Color(0xFF1B1917),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2E2A26)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: edBox(
                            shape: BoxShape.circle,
                            color: const Color(0xFF252A30),
                            border: Border.all(color: const Color(0xFF4A6878).withValues(alpha: 0.5)),
                          ),
                          child: const Center(
                            child: Text('❄️', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+1 STREAK FREEZE EARNED',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF90B4CE),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.freezesAvailable} Freezes active to guard missed days',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFFEFE8DB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: terracotta,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        AestheticAudioService().playHapticTone(type: 'click');
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.flame, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Keep The Flame Alive',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
