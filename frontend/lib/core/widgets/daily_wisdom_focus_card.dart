import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'bento_pod.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'app_toast_engine.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

class WisdomItem {
  final String theme;
  final IconData icon;
  final String maxim;
  final String author;
  final String reflectionPrompt;

  const WisdomItem({
    required this.theme,
    required this.icon,
    required this.maxim,
    required this.author,
    required this.reflectionPrompt,
  });
}

/// Curated Daily Wisdom & Focus Maxim Card
/// Provides simple, accessible, inspiring thoughts and actionable daily reflection
/// without overly dense or pretentious vocabulary.
class DailyWisdomFocusCard extends StatefulWidget {
  final VoidCallback? onReflectInJournal;

  const DailyWisdomFocusCard({
    super.key,
    this.onReflectInJournal,
  });

  @override
  State<DailyWisdomFocusCard> createState() => _DailyWisdomFocusCardState();
}

class _DailyWisdomFocusCardState extends State<DailyWisdomFocusCard> {
  static const List<WisdomItem> _wisdomLibrary = [
    WisdomItem(
      theme: 'Clarity & Simplicity',
      icon: LucideIcons.compass,
      maxim:
          'Simplicity is about subtracting the obvious and adding the meaningful. Do fewer things with greater care.',
      author: 'John Maeda',
      reflectionPrompt:
          'What is one non-essential task on your list today that you can safely set aside?',
    ),
    WisdomItem(
      theme: 'Daily Momentum',
      icon: LucideIcons.zap,
      maxim:
          'Small, steady actions repeated every day quietly outperform rare bursts of heroic effort.',
      author: 'James Clear',
      reflectionPrompt:
          'What is one tiny 2-minute step you can take right now to create forward motion?',
    ),
    WisdomItem(
      theme: 'Inner Calm',
      icon: LucideIcons.shield,
      maxim:
          'You have power over your own mind, not outside events. Recognize this, and you will find calm strength.',
      author: 'Marcus Aurelius',
      reflectionPrompt:
          'Where can you pause for a deep breath before reacting to an urgent message today?',
    ),
    WisdomItem(
      theme: 'Deep Focus',
      icon: LucideIcons.target,
      maxim:
          'The shortest way to do many things is to only do one thing at a time with full presence.',
      author: 'Wolfgang Mozart',
      reflectionPrompt:
          'If you could only complete one meaningful task before sunset, which one moves the needle most?',
    ),
    WisdomItem(
      theme: 'Protecting Energy',
      icon: LucideIcons.sparkles,
      maxim:
          'Saying no to the good is what gives you the freedom to say yes to what truly matters.',
      author: 'Michael Hyatt',
      reflectionPrompt:
          'What healthy boundary will you protect today so your best focus stays intact?',
    ),
    WisdomItem(
      theme: 'Courage to Begin',
      icon: LucideIcons.flame,
      maxim:
          'The secret of getting ahead is simply getting started. Do not wait for conditions to be perfect.',
      author: 'Mark Twain',
      reflectionPrompt:
          'What important project are you putting off that is ready for a messy first draft?',
    ),
    WisdomItem(
      theme: 'Rest & Renewal',
      icon: LucideIcons.sun,
      maxim:
          'Rest is not a prize for finishing your work; it is the vital fuel that makes great work possible.',
      author: 'Arianna Huffington',
      reflectionPrompt:
          'How will you step away and give your mind space to recharge this evening?',
    ),
  ];

  late int _currentIndex;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    // Deterministic daily index based on day of year, but user can cycle freely
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    _currentIndex = dayOfYear % _wisdomLibrary.length;
  }

  void _nextWisdom() {
    SanctuaryHapticEngine.selection();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _wisdomLibrary.length;
      _isBookmarked = false;
    });
  }

  void _toggleBookmark() {
    SanctuaryHapticEngine.selection();
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    AppToastEngine().notify(
      title: _isBookmarked ? 'Saved to Favorites' : 'Removed from Favorites',
      message: _isBookmarked
          ? 'Wisdom pinned to your personal focus favorites.'
          : 'Wisdom removed.',
    );
  }

  void _copyWisdom(WisdomItem item) {
    SanctuaryHapticEngine.selection();
    Clipboard.setData(ClipboardData(
      text: '"${item.maxim}" — ${item.author}\n\nToday\'s Question: ${item.reflectionPrompt}',
    ));
    AppToastEngine().notify(
      title: 'Copied to Clipboard',
      message: 'Quote and reflection question ready to share or paste.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFBF8F2) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF6B655B);
    const terracotta = Color(0xFFD9725B);
    const sage = Color(0xFFE8927C);
    const gold = Color(0xFFD9725B);

    final item = _wisdomLibrary[_currentIndex];

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'DAILY WISDOM & FOCUS',
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon, size: 9, color: sage),
                            const SizedBox(width: 3.5),
                            Text(
                              item.theme.toUpperCase(),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: sage,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 17,
                      color: _isBookmarked ? gold : subtextColor,
                    ),
                    tooltip: 'Save Wisdom',
                    onPressed: _toggleBookmark,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.copy, size: 15, color: subtextColor),
                    tooltip: 'Copy Quote',
                    onPressed: () => _copyWisdom(item),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 15, color: terracotta),
                    tooltip: 'Next Thought',
                    onPressed: _nextWisdom,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Maxim / Quote
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(
              key: ValueKey('wisdom_content_$_currentIndex'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“',
                      style: GoogleFonts.spectral(
                        fontSize: 26,
                        height: 0.9,
                        fontWeight: FontWeight.bold,
                        color: terracotta.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.maxim,
                        style: GoogleFonts.spectral(
                          fontSize: 14.5,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    '— ${item.author}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Actionable Daily Reflection Prompt
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: edBox(
                    color: isDark
                        ? const Color(0xFF161412)
                        : const Color(0xFFF3ECE0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: terracotta.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1.5),
                        child: Icon(LucideIcons.helpCircle, size: 13, color: terracotta),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY\'S QUESTION',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: terracotta,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.reflectionPrompt,
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Interactive Footer Buttons
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.refreshCw, size: 11),
                label: Text(
                  'Next Insight',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: terracotta,
                  side: BorderSide(color: terracotta.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _nextWisdom,
              ),
              if (widget.onReflectInJournal != null)
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.penTool, size: 11),
                  label: Text(
                    'Journal This',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracotta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    SanctuaryHapticEngine.selection();
                    widget.onReflectInJournal!();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
