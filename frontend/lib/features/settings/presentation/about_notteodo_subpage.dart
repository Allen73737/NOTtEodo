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

/// Dedicated About NOTtEodo Subpage
/// Details app architecture, design philosophy, version changelog, and team credits.
class AboutNotteodoSubpage extends StatelessWidget {
  const AboutNotteodoSubpage({super.key});

  void _shareApp(BuildContext context) {
    SanctuaryHapticEngine.selection();
    Clipboard.setData(const ClipboardData(
      text: 'NOTtEodo — The private, distraction-free productivity workspace with Swiss watchmaker precision and offline-first intelligence.',
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
    const terracotta = Color(0xFFD9725B);

    final specs = [
      {'label': 'Client Framework', 'val': 'Flutter 3.x Engine'},
      {'label': 'Database Engine', 'val': 'On-Device SQLite (Local-First)'},
      {'label': 'Cryptography', 'val': 'AES-256 GCM Hardware Bound'},
      {'label': 'Design System', 'val': 'Tuscan Warmth & Obsidian (No Cyan)'},
      {'label': 'Audio Engine', 'val': 'High-Fidelity Ambient Soundscapes'},
      {'label': 'Telemetry Policy', 'val': '100% Zero-Tracking & Private'},
    ];

    final highlights = [
      {
        'title': 'Watchmaker Focus Dial',
        'desc': 'Heated steel Breguet hands gliding over an ivory chapter ring for the 25-minute Pomodoro focus session.',
        'icon': LucideIcons.watch,
      },
      {
        'title': 'Curated Daily Wisdom Card',
        'desc': 'Daily focus themes, accessible inspiring maxims, and actionable daily questions with 1-tap journal capture.',
        'icon': LucideIcons.quote,
      },
      {
        'title': 'Streak Flame Evolution',
        'desc': '5-tier visual progression from Kindling Spark to the immortal Golden Phoenix with milestone unlocks.',
        'icon': LucideIcons.flame,
      },
      {
        'title': 'Nodo AI Companion',
        'desc': 'Thoughtful on-device partner offering gentle philosophical guidance or playful "Roast My Focus" checks.',
        'icon': LucideIcons.bot,
      },
      {
        'title': 'Private Vault & Biometrics',
        'desc': 'Hardware-enclave protection for your most confidential thoughts, passwords, and sensitive notes.',
        'icon': LucideIcons.shieldCheck,
      },
    ];

    return SettingsSubpageScaffold(
      categoryLabel: 'Craftsmanship & Architecture',
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
                    decoration: BoxDecoration(
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
                    'Precision productivity crafted with watchmaker care.\nZero noise, zero ads, and 100% private.',
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
            'OUR PHILOSOPHY',
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
            decoration: BoxDecoration(
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
                  'Built to protect your attention, not steal it.',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Modern software has become noisy, commercialized, and invasive. NOTtEodo was designed as a quiet, analog-inspired sanctuary—bringing the timeless tactile precision of horology, warm organic aesthetics, and unyielding privacy back to your everyday focus.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Highlights of v2.5.0
          Text(
            'KEY CRAFTSMANSHIP HIGHLIGHTS',
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
              decoration: BoxDecoration(
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
                    decoration: BoxDecoration(
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
            decoration: BoxDecoration(
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
