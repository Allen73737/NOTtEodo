import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/data_portability_service.dart';
import '../../../core/widgets/app_toast_engine.dart';
import 'settings_subpages.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Terms & Conditions Subpage
/// Outlines the local-first charter, zero-subscription pledge, data sovereignty,
/// encryption responsibilities, and open-source licensing in human-readable clarity.
class TermsConditionsSubpage extends StatelessWidget {
  const TermsConditionsSubpage({super.key});

  void _copyTermsSummary(BuildContext context) {
    SanctuaryHapticEngine.selection();
    const summary = '''NOTtEODO — TERMS & CONDITIONS SUMMARY
1. 100% Local-First: Your notes, tasks, expenses, and recordings reside strictly on your device.
2. Zero Subscriptions: Completely free, open-source (MIT), with no paywalls or advertising trackers.
3. Zero-Knowledge Security: Private Vault uses AES-256 GCM on-device encryption. You own your keys.
4. Unconditional Portability: Export your entire life dataset anytime in JSON, CSV, or ICS.
5. Optional Cloud Sync: End-to-end secured via TLS 1.3 with instant 1-tap account deletion.''';

    Clipboard.setData(const ClipboardData(text: summary));
    AppToastEngine().notify(
      title: 'Terms Copied',
      message: 'Plain-language agreement summary copied to clipboard.',
      type: ToastType.success,
    );
  }

  void _exportFullData(BuildContext context) {
    SanctuaryHapticEngine.selection();
    try {
      final json = DataPortabilityService.buildBackupJson();
      Clipboard.setData(ClipboardData(text: json));
      AppToastEngine().notify(
        title: 'Data Snapshot Exported',
        message: 'Complete local archive copied to clipboard as JSON.',
        type: ToastType.success,
      );
    } catch (_) {
      AppToastEngine().notify(
        title: 'Export Failed',
        message: 'Unable to package archive snapshot.',
        type: ToastType.alert,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final cardBg = isDark ? const Color(0xFF0F0E0D) : const Color(0xFFFAF8F5);
    final borderColor = isDark ? const Color(0xFF26221E) : const Color(0xFFE5DDD0);
    final accentTerracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return SettingsSubpageScaffold(
      categoryLabel: 'LEGAL & SOVEREIGNTY',
      title: 'Terms & Conditions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: edBox(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: edBox(
                        color: accentTerracotta.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentTerracotta.withValues(alpha: 0.35)),
                      ),
                      child: Icon(LucideIcons.scale, color: accentTerracotta, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THE SOVEREIGN USER CHARTER',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: accentTerracotta,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your Life, Your Data, Your Sanctuary',
                            style: GoogleFonts.bodoniModa(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'NOTtEodo is built on a foundation of mutual trust and digital sovereignty. We reject manipulative subscriptions, hidden paywalls, telemetry surveillance, and data harvesting. This agreement outlines our binding commitments to you.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: subtextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill('✦ 100% Local-First', accentTerracotta, isDark),
                    _buildPill('🔒 Zero Ads or Trackers', accentTerracotta, isDark),
                    _buildPill('📜 MIT Open Source', accentTerracotta, isDark),
                    _buildPill('⚡ Zero Paywalls', accentTerracotta, isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Data Ownership & Sovereignty
          _buildCharterSection(
            number: '01',
            icon: LucideIcons.database,
            title: 'Absolute Data Ownership & Local Sovereignty',
            paragraphs: [
              'Everything you create inside NOTtEodo — including notes, to-do items, habit histories, personal expenses, wardrobe photographs, and voice memos — belongs exclusively to you.',
              'NOTtEodo operates as an offline-first workspace. Your content is stored locally on your device\'s SQLite database and secure key-value stores. We do not inspect, catalog, profile, or sell your personal information to third-party data brokers or advertisers.',
            ],
            isDark: isDark,
            primaryColor: primaryTextColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            accentColor: accentTerracotta,
          ),
          const SizedBox(height: 14),

          // Section 2: Zero Subscription & MIT License
          _buildCharterSection(
            number: '02',
            icon: LucideIcons.unlock,
            title: 'Zero Subscriptions & Open Source Transparency',
            paragraphs: [
              'NOTtEodo is 100% free and open-source software licensed under the standard MIT License.',
              'There are no monthly fees, locked features, "Pro" paywalls, or artificial limits on how many notes, tasks, or photos you can store. You are free to inspect our source code, audit our cryptographic implementations, or compile the application yourself.',
            ],
            isDark: isDark,
            primaryColor: primaryTextColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            accentColor: accentTerracotta,
          ),
          const SizedBox(height: 14),

          // Section 3: Vault Security & Cryptographic Responsibility
          _buildCharterSection(
            number: '03',
            icon: LucideIcons.shieldCheck,
            title: 'Zero-Knowledge Encryption & Master PIN Responsibility',
            paragraphs: [
              'The Private Vault is guarded by authenticated AES-256 GCM encryption. Your master PIN and biometric credentials never leave your hardware enclave.',
              'Because NOTtEodo is built with true zero-knowledge privacy, no master backdoor exists. If you lose your vault PIN and do not have an enrolled biometric or an encrypted backup export, no remote administrator can recover your private vault keys. We urge curators to maintain personal backups.',
            ],
            isDark: isDark,
            primaryColor: primaryTextColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            accentColor: accentTerracotta,
          ),
          const SizedBox(height: 14),

          // Section 4: Optional Cloud Sync
          _buildCharterSection(
            number: '04',
            icon: LucideIcons.cloud,
            title: 'Optional Cloud Synchronization & Instant Deletion',
            paragraphs: [
              'Cloud synchronization is entirely optional. If you choose to connect an account via Supabase, synchronization happens over encrypted TLS 1.3 channels to secure database clusters.',
              'You maintain the absolute right to purge your remote account. Navigating to Settings > Account > Delete Account immediately drops all remote records and associated authentication credentials from the servers.',
            ],
            isDark: isDark,
            primaryColor: primaryTextColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            accentColor: accentTerracotta,
          ),
          const SizedBox(height: 14),

          // Section 5: Unconditional Data Portability
          _buildCharterSection(
            number: '05',
            icon: LucideIcons.fileSpreadsheet,
            title: 'Unconditional Data Portability & Non-Lock-In',
            paragraphs: [
              'You are never trapped in NOTtEodo. You can export your data at any time in standardized formats: full JSON snapshots, RFC 5545 iCalendar files (.ics) for tasks, and comma-separated values (CSV) for financial ledgers.',
              'We guarantee that our export tools will remain open, unencrypted at rest upon your request, and compatible with open personal knowledge management (PKM) ecosystems.',
            ],
            isDark: isDark,
            primaryColor: primaryTextColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            accentColor: accentTerracotta,
          ),
          const SizedBox(height: 14),

          // Section 6: Limitations & Disclaimer
          _buildCharterSection(
            number: '06',
            icon: LucideIcons.info,
            title: 'Standard Disclaimers & Warranties',
            paragraphs: [
              'NOTtEodo is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement.',
              'While we continuously write automated tests and perform strict memory safety checks to safeguard your records, you are encouraged to periodically create encrypted local backups to safeguard against hardware loss, OS failures, or accidental device destruction.',
            ],
            isDark: isDark,
            primaryColor: primaryTextColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            accentColor: accentTerracotta,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyTermsSummary(context),
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: Text(
                    'Copy Summary',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTextColor,
                    side: BorderSide(color: borderColor, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportFullData(context),
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: Text(
                    'Export Archive',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentTerracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Version & Effective Date
          Center(
            child: Text(
              'NOTtEodo Sanctuary Charter • Revision 2.4.0 • Updated November 2026',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                color: subtextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharterSection({
    required String number,
    required IconData icon,
    required String title,
    required List<String> paragraphs,
    required bool isDark,
    required Color primaryColor,
    required Color subtextColor,
    required Color cardBg,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: edBox(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in paragraphs) ...[
            Text(
              p,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: subtextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: edBox(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

