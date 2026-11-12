import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../luxury/breguet_hands_tracker.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';

/// Interactive Watchmaker Focus Dial Modal
/// Offers an immersive desk/stand timer with customizable duration (5 to 180 min),
/// Breguet hands dial, sound controls, and clean Tuscan terracotta styling (no gold/yellow).
class FocusDialModal extends ConsumerStatefulWidget {
  final Duration focusLeft;
  final Duration focusTotal;
  final bool isRunning;
  final VoidCallback? onToggle;
  final VoidCallback? onReset;
  final VoidCallback? onOpenSoundSelector;

  const FocusDialModal({
    super.key,
    required this.focusLeft,
    required this.focusTotal,
    required this.isRunning,
    this.onToggle,
    this.onReset,
    this.onOpenSoundSelector,
  });

  static void show(
    BuildContext context, {
    Duration focusLeft = const Duration(minutes: 25),
    Duration focusTotal = const Duration(minutes: 25),
    bool isRunning = false,
    VoidCallback? onToggle,
    VoidCallback? onReset,
    VoidCallback? onOpenSoundSelector,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
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

  @override
  ConsumerState<FocusDialModal> createState() => _FocusDialModalState();
}

class _FocusDialModalState extends ConsumerState<FocusDialModal> {
  late int _durationMinutes;
  late int _secondsLeft;
  late bool _isRunning;
  Timer? _countdownTimer;

  static const List<int> _presetMinutes = [15, 25, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.focusTotal.inMinutes > 0 ? widget.focusTotal.inMinutes : 25;
    _secondsLeft = widget.focusLeft.inSeconds > 0 ? widget.focusLeft.inSeconds : (_durationMinutes * 60);
    _isRunning = widget.isRunning;

    if (_isRunning) {
      _startInternalTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startInternalTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft % 2 == 0) {
          SanctuaryHapticEngine.escapementTick();
        }
      } else {
        timer.cancel();
        setState(() {
          _isRunning = false;
        });
        SanctuaryHapticEngine.sealImpression();
      }
    });
  }

  void _toggleTimer() {
    SanctuaryHapticEngine.selection();
    if (_isRunning) {
      _countdownTimer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_secondsLeft <= 0) {
        _secondsLeft = _durationMinutes * 60;
      }
      setState(() => _isRunning = true);
      _startInternalTimer();
    }
    widget.onToggle?.call();
  }

  void _resetTimer() {
    SanctuaryHapticEngine.selection();
    _countdownTimer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _durationMinutes * 60;
    });
    widget.onReset?.call();
  }

  void _setDuration(int mins) {
    SanctuaryHapticEngine.dialDetent();
    _countdownTimer?.cancel();
    setState(() {
      _durationMinutes = mins;
      _secondsLeft = mins * 60;
      _isRunning = false;
    });
  }

  String _formatMmSs(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFBF8F2) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF6B655B);
    const terracotta = Color(0xFFD9725B);
    const sage = Color(0xFFE8927C);

    final settings = ref.watch(appSettingsProvider);
    final totalSec = _durationMinutes * 60;
    final progress = totalSec > 0 ? (1.0 - (_secondsLeft / totalSec)).clamp(0.0, 1.0) : 0.0;

    final mediaQuery = MediaQuery.of(context);
    final dialSize = (mediaQuery.size.width * 0.48).clamp(140.0, 220.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF26221E) : const Color(0xFFE2DCCF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.25),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
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
                          border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'WATCHMAKER FOCUS DIAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                            color: terracotta,
                          ),
                        ),
                      ),
                      if (_isRunning)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: sage.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: sage.withValues(alpha: 0.3)),
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
                                  fontSize: 11,
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
              centerCaption: _isRunning ? 'FOCUSED FLOW' : '$_durationMinutes-MIN SESSION',
              timeRemainingText: _formatMmSs(_secondsLeft),
              isRunning: _isRunning,
              onTap: _toggleTimer,
            ),
            const SizedBox(height: 14),

            // Interactive Duration Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final mins in _presetMinutes)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('${mins}m'),
                        selected: _durationMinutes == mins,
                        onSelected: (selected) {
                          if (selected) _setDuration(mins);
                        },
                        selectedColor: terracotta,
                        backgroundColor: isDark ? const Color(0xFF161412) : const Color(0xFFEDE6DA),
                        labelStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _durationMinutes == mins ? Colors.white : primaryTextColor,
                        ),
                        side: BorderSide(
                          color: _durationMinutes == mins
                              ? terracotta
                              : (isDark ? const Color(0xFF2C2622) : const Color(0xFFDDD5C7)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Custom Slider Duration Adjuster
            Row(
              children: [
                Icon(LucideIcons.clock, size: 14, color: subtextColor),
                const SizedBox(width: 8),
                Text(
                  'Custom: ${_durationMinutes}m',
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    activeColor: terracotta,
                    inactiveColor: isDark ? const Color(0xFF221F1C) : const Color(0xFFE5DDD0),
                    onChanged: (val) {
                      _setDuration(val.round());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status message
            Text(
              _isRunning
                  ? 'Stay immersed. Every second builds quiet mastery.'
                  : (_secondsLeft == totalSec
                      ? 'Ready to begin your $_durationMinutes-minute session. Tap play to focus.'
                      : 'Session paused. Tap to resume when ready.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: subtextColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

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
                  onPressed: _resetTimer,
                ),
                const SizedBox(width: 16),

                // Large Play/Pause Button
                ElevatedButton(
                  onPressed: _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracotta,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    elevation: 4,
                  ),
                  child: Icon(
                    _isRunning ? LucideIcons.pause : LucideIcons.play,
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
                  color: _isRunning ? terracotta : subtextColor,
                  iconSize: 22,
                  tooltip: 'Focus Soundtracks',
                  onPressed: () {
                    SanctuaryHapticEngine.selection();
                    widget.onOpenSoundSelector?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ambient Sound Status Pill
            InkWell(
              onTap: widget.onOpenSoundSelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161412) : const Color(0xFFEDE6DA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_isRunning ? terracotta : subtextColor).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.music,
                      size: 13,
                      color: _isRunning ? terracotta : subtextColor,
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
