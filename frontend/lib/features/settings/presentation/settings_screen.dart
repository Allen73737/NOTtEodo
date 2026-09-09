import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/bento_pod.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineSync = true;
  bool _ragAiEnabled = true;
  bool _localEncryption = true;
  bool _biometricLock = true;

  void _triggerDataExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(LucideIcons.downloadCloud, color: AppColors.secondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTtEodo_DataVault_2026.$format', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('100% data exported as ${format.toUpperCase()} vault archive.', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRIVACY & CONTROL CENTER', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Settings & Privacy',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Privacy & Biometric Security
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text('SERENE PRIVACY & BIOMETRICS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 16),

                _settingSwitch('Biometric Touch ID / Face ID Lock', 'Require biometric unlock for private vault', _biometricLock, (v) => setState(() => _biometricLock = v), primaryTextColor, subtextColor),
                const Divider(height: 20),
                _settingSwitch('AES-256 Local Encryption', 'Encrypt sensitive notes and journal entries', _localEncryption, (v) => setState(() => _localEncryption = v), primaryTextColor, subtextColor),
                const Divider(height: 20),
                _settingSwitch('Offline Local Persistence', 'Store notes & data locally on device', _offlineSync, (v) => setState(() => _offlineSync = v), primaryTextColor, subtextColor),
                const Divider(height: 20),
                _settingSwitch('Scoped RAG Vector AI', 'Restricted isolated AI boundaries for collections', _ragAiEnabled, (v) => setState(() => _ragAiEnabled = v), primaryTextColor, subtextColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Multi-Format Data Vault Export Card
          BentoPod(
            style: PodTextureStyle.paper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MULTI-FORMAT VAULT EXPORTER', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
                const SizedBox(height: 8),
                Text('Export your complete NOTtEodo sanctuary anytime as JSON, Markdown, or PDF archive.', style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _exportButton('JSON Vault', 'json', LucideIcons.fileCode, primaryTextColor),
                    _exportButton('Markdown Archive', 'md', LucideIcons.fileText, primaryTextColor),
                    _exportButton('PDF Booklet', 'pdf', LucideIcons.file, primaryTextColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportButton(String label, String ext, IconData icon, Color textColor) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: () => _triggerDataExport(ext),
      icon: Icon(icon, size: 14, color: AppColors.secondary),
      label: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: textColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _settingSwitch(String title, String desc, bool val, ValueChanged<bool> onChanged, Color primaryTextColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor)),
              Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
            ],
          ),
        ),
        Switch(
          value: val,
          activeTrackColor: AppColors.secondary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
