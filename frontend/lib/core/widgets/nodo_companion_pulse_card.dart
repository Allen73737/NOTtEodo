import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'bento_pod.dart';
import 'nodo_avatar_widget.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Interactive Nodo AI Companion card providing dynamic daily wisdom,
/// playful companion roasts, and instant conversation hooks.
class NodoCompanionPulseCard extends ConsumerStatefulWidget {
  final VoidCallback onOpenAi;

  const NodoCompanionPulseCard({
    super.key,
    required this.onOpenAi,
  });

  @override
  ConsumerState<NodoCompanionPulseCard> createState() => _NodoCompanionPulseCardState();
}

class _NodoCompanionPulseCardState extends ConsumerState<NodoCompanionPulseCard> {
  int _currentQuoteIndex = 0;
  bool _isRoastMode = false;

  static const List<String> _wisdomQuotes = [
    'Mastery is not doing everything; it is fiercely protecting your focus on the single task that moves the needle today.',
    'A quiet mind moves mountains without making noise. Drop the urgency, keep the intensity.',
    'Two minutes aligning your compass right now saves two hours of reactive chaos this afternoon.',
    'Consistency conquers talent when talent rests. You showed up today; that is already half the battle.',
    'Clarity is an elimination game. What can you safely ignore today so the vital work can breathe?',
    'The best time to finish a hard task was this morning. The second best time is before you open another distraction.',
    'Rest is not a reward for work done; it is the prerequisite for genius. Take a deep breath.',
  ];

  static const List<String> _roastQuotes = [
    'I see you staring at your task list again. Staring at tasks doesn\'t mark them done, my friend.',
    'You have tasks due today, yet you\'re rearranging your font sizes. A classic executive procrastination technique.',
    'Statistically, you are about to check your phone again. Prove me wrong and finish this next task.',
    'Crossing off "make coffee" to feel accomplished? Bold strategy. Now tackle something with actual teeth.',
    'I am your AI companion, not an enabler. That high-priority item isn\'t going to complete itself while you stare at me.',
    'Your streak is strong, but your courage to open that #1 urgent task seems to be on low battery. Plug in.',
  ];

  String _getQuote(int tasksCount, int streak) {
    if (_isRoastMode) {
      if (tasksCount > 4) {
        return 'You have $tasksCount pending tasks waiting for you like abandoned houseplants. Pick the scariest one first!';
      }
      return _roastQuotes[_currentQuoteIndex % _roastQuotes.length];
    } else {
      if (streak >= 14 && _currentQuoteIndex == 0) {
        return '$streak days strong. You\'re officially harder to stop than an unchecked recurring subscription. Keep that flame burning!';
      }
      return _wisdomQuotes[_currentQuoteIndex % _wisdomQuotes.length];
    }
  }

  void _shuffleQuote({required bool roast}) {
    SanctuaryHapticEngine.selection();
    setState(() {
      _isRoastMode = roast;
      _currentQuoteIndex = Random().nextInt(roast ? _roastQuotes.length : _wisdomQuotes.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFBF8F2) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF6B655B);
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    const terracotta = Color(0xFFD9725B);
    const sage = Color(0xFF8FA878);

    final settings = ref.watch(appSettingsProvider);
    final tasks = ref.watch(tasksProvider);
    final pendingTasks = tasks.where((t) => !t.completed).length;
    final streak = settings.activeStreak;

    final quote = _getQuote(pendingTasks, streak);

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NodoAvatarWidget(
                size: 34,
                emotion: _isRoastMode ? NodoEmotion.sarcastic : NodoEmotion.thinking,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'NODO\'S COMPANION PULSE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: terracotta,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: edBox(
                            color: sage.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AI COMPANION',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _isRoastMode ? 'Affectionate reality check' : 'Philosophical daily focus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.messageSquare, size: 17, color: accentColor),
                tooltip: 'Chat with Nodo',
                onPressed: () {
                  SanctuaryHapticEngine.selection();
                  widget.onOpenAi();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speech Bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: edBox(
              color: isDark ? const Color(0xFF141210) : const Color(0xFFF9F4EB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: terracotta.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1.0,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.08),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                quote,
                key: ValueKey('$_isRoastMode-$_currentQuoteIndex-$pendingTasks-$streak'),
                style: GoogleFonts.spectral(
                  fontSize: 13.5,
                  height: 1.38,
                  fontStyle: FontStyle.italic,
                  color: primaryTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.sparkles, size: 12),
                label: Text('Inspire Me', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: terracotta,
                  side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                ),
                onPressed: () => _shuffleQuote(roast: false),
              ),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.flame, size: 12),
                label: Text('Roast My Focus', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isRoastMode ? terracotta : subtextColor,
                  side: BorderSide(color: (_isRoastMode ? terracotta : subtextColor).withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                ),
                onPressed: () => _shuffleQuote(roast: true),
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.bot, size: 12),
                label: Text('Talk to Nodo', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: terracotta,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                ),
                onPressed: () {
                  SanctuaryHapticEngine.selection();
                  widget.onOpenAi();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}