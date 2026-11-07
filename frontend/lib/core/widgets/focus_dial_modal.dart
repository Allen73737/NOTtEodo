import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../luxury/breguet_hands_tracker.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';

/// Interactive Watchmaker Focus Dial Modal
/// Offers an immersive desk/stand timer with the Breguet hands dial,
/// sound controls, and clean, accessible controls.
class FocusDialModal extends ConsumerWidget {
  final Duration focusLeft;
  final Duration focusTotal;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onOpenSoundSelector;

  const FocusDialModal({
    super.key,
    required this.focusLeft,
    required this.focusTotal,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
    required this.onOpenSoundSelector,
  });

  static void show(
    BuildContext context, {
    required Duration focusLeft,
    required Duration focusTotal,
    required bool isRunning,
    required VoidCallback onToggle,
    required VoidCallback onReset,
    required VoidCallback onOpenSoundSelector,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FocusDialModal(
        focusLeft: focusLeft,
        focusTotal: focusTotal,
        isRunning: isRunning,
        onToggle: onToggle,
        onReset: onReset,
        onOpenSoundSelector: onOpenSoundSelector,
      ),
    );
  }

  String _formatMmSs(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFBF8F2) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF6B655B);
    const terracotta = Color(0xFFD9725B);
    const sage = Color(0xFF8FA878);
    const gold = Color(0xFFD4AF37);

    final settings = ref.watch(appSettingsProvider);
    final totalSec = focusTotal.inSeconds;
    final leftSec = focusLeft.inSeconds;
    final progress = totalSec > 0 ? (1.0 - (leftSec / totalSec)).clamp(0.0, 1.0) : 0.0;

    final mediaQuery = MediaQuery.of(context);
    final dialSize = (mediaQuery.size.width * 0.48).clamp(140.0, 220.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0A09) : const Color(0xFFFAF7F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF26221E) : const Color(0xFFE2DCCF),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        mediaQuery.padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: subtextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'WATCHMAKER FOCUS DIAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                            color: terracotta,
                          ),
                        ),
                      ),
                      if (isRunning)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: sage.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: sage,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'RUNNING',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: sage,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 18, color: subtextColor),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // The Breguet Hands Focus Dial
            BreguetHandsTracker(
              progress: progress,
              size: dialSize,
              centerCaption: isRunning ? 'FOCUSED FLOW' : '25-MIN SESSION',
              timeRemainingText: _formatMmSs(focusLeft),
              isRunning: isRunning,
              onTap: () {
                SanctuaryHapticEngine.selection();
                onToggle();
              },
            ),
            const SizedBox(height: 14),

            // Status message
            Text(
              isRunning
                  ? 'Stay immersed. Every second builds quiet mastery.'
                  : (focusLeft == focusTotal
                      ? 'Ready to begin your session. Tap play to focus.'
                      : 'Session paused. Tap to resume when ready.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: subtextColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Primary Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw),
                  color: subtextColor,
                  iconSize: 22,
                  tooltip: 'Reset Session',
                  onPressed: () {
                    SanctuaryHapticEngine.selection();
                    onReset();
                  },
                ),
                const SizedBox(width: 16),

                // Large Play/Pause Button
                ElevatedButton(
                  onPressed: () {
                    SanctuaryHapticEngine.selection();
                    onToggle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracotta,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    elevation: 4,
                  ),
                  child: Icon(
                    isRunning ? LucideIcons.pause : LucideIcons.play,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Soundtrack button
                IconButton(
                  icon: Icon(
                    settings.focusLoopSound == 'none'
                        ? LucideIcons.volumeX
                        : LucideIcons.headphones,
                  ),
                  color: isRunning ? gold : subtextColor,
                  iconSize: 22,
                  tooltip: 'Focus Soundtracks',
                  onPressed: () {
                    SanctuaryHapticEngine.selection();
                    onOpenSoundSelector();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ambient Sound Status Pill
            InkWell(
              onTap: onOpenSoundSelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161412) : const Color(0xFFEDE6DA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isRunning ? gold : subtextColor).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.music,
                      size: 13,
                      color: isRunning ? gold : subtextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      settings.focusLoopSound == 'none'
                          ? 'Silent Focus (Tap to choose sound)'
                          : 'Audio: ${settings.focusLoopSound}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.chevronRight, size: 13, color: subtextColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
