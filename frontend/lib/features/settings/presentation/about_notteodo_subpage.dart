import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/curator_feedback_dialog.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import 'settings_subpages.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Dedicated About NOTtEodo Subpage
/// Details app architecture, design philosophy, version changelog, and team credits.
class AboutNotteodoSubpage extends StatelessWidget {
  const AboutNotteodoSubpage({super.key});

  void _shareApp(BuildContext context) {
    SanctuaryHapticEngine.selection();
    Clipboard.setData(const ClipboardData(
      text: 'NOTtEodo — A free, private, all-in-one daily organizer for notes, tasks, habits, expenses, and focus.',
    ));
    AppToastEngine().notify(
      title: 'Link Copied',
      message: 'NOTtEodo introduction copied to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    const terracotta = Color(0xFF8E2433);

    final specs = [
      {'label': 'Client Framework', 'val': 'Flutter 3.x Engine'},
      {'label': 'Data Storage', 'val': 'Saved on your phone (Offline-first)'},
      {'label': 'Security', 'val': 'Strong device encryption (AES-256)'},
      {'label': 'Design Style', 'val': 'Clean cards & reading mode'},
      {'label': 'Audio', 'val': 'Calming background sounds'},
      {'label': 'Privacy', 'val': '100% private, no tracking, no ads'},
    ];

    final highlights = [
      {
        'title': 'Watchmaker Focus Dial',
        'desc': 'A simple Pomodoro focus timer to help you work, read, or study without distractions.',
        'icon': LucideIcons.timer,
      },
      {
        'title': 'Daily Reflection & Quotes',
        'desc': 'Thoughtful daily questions, positive quotes, and quick notes to start each day with a clear mind.',
        'icon': LucideIcons.quote,
      },
      {
        'title': 'Habit Streaks',
        'desc': 'Track your good habits and watch your streak flame grow as you complete goals every day.',
        'icon': LucideIcons.flame,
      },
      {
        'title': 'Nodo AI Companion',
        'desc': 'A friendly helper to give you tips, review your daily tasks, and help you plan your week.',
        'icon': LucideIcons.bot,
      },
      {
        'title': 'Locked Vault & Fingerprint',
        'desc': 'Keep your private notes, passwords, and sensitive information secure behind a PIN or fingerprint.',
        'icon': LucideIcons.shieldCheck,
      },
      {
        'title': 'Emergency Recovery Key',
        'desc': 'A simple 16-character backup code so you never lose your account, data, or password.',
        'icon': LucideIcons.keyRound,
      },
    ];

    return SettingsSubpageScaffold(
      categoryLabel: 'About & Information',
      title: 'About NOTtEodo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monogram Emblem & Version Card
          BentoPod(
            style: PodTextureStyle.glass,
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const StitchMonogramNWidget(size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'NOTtEodo',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: edBox(
                      color: terracotta.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'v2.5.0 · Production Edition',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: terracotta,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A simple, private, all-in-one daily organizer.\nNo ads, no subscriptions, and 100% free.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: subtextColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // The Philosophy Section
          Text(
            'OUR PROMISE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: terracotta,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: edBox(
              color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Built to help you focus, with zero distractions.',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Most productivity apps today are filled with annoying ads, expensive monthly subscriptions, and constant notifications. NOTtEodo is built to be simple, peaceful, and completely private. Everything you write stays safely on your phone so you can organize your daily life with peace of mind.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Highlights of v2.6.0
          Text(
            'KEY FEATURES',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: terracotta,
            ),
          ),
          const SizedBox(height: 10),
          ...highlights.map((h) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: edBox(
                color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF221E1C) : const Color(0xFFE5DDD0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: edBox(
                      color: terracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(h['icon'] as IconData, size: 16, color: terracotta),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['title'] as String,
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h['desc'] as String,
                          style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 18),

          // Technical Specs Grid
          Text(
            'TECHNICAL SPECIFICATIONS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: terracotta,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: edBox(
              color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF262220) : const Color(0xFFE5DDD0),
              ),
            ),
            child: Column(
              children: specs.asMap().entries.map((entry) {
                final isLast = entry.key == specs.length - 1;
                final s = entry.value;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['label']!, style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
                        Text(
                          s['val']!,
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                        ),
                      ],
                    ),
                    if (!isLast) const Divider(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.share2, size: 14),
                  label: Text('Share App', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: terracotta,
                    side: BorderSide(color: terracotta.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _shareApp(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.messageSquare, size: 14),
                  label: Text('Feedback', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracotta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    SanctuaryHapticEngine.selection();
                    CuratorFeedbackDialog.show(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Crafted with devotion · All rights reserved © 2026',
              style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
