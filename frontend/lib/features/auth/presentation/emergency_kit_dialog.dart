import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/recovery_key_service.dart';

/// An emergency kit dialog (Signal & 1Password style) that presents the
/// 16-character Master Recovery Key immediately upon signup or first run.
class EmergencyKitDialog extends StatefulWidget {
  final String recoveryKey;
  final String? email;

  const EmergencyKitDialog({
    super.key,
    required this.recoveryKey,
    this.email,
  });

  /// Displays the Emergency Kit dialog, ensuring a recovery key is created and securely saved.
  static Future<bool?> show(
    BuildContext context, {
    String? email,
  }) async {
    final service = MasterRecoveryKeyService();
    String? existingKey = await service.getSavedKeyRaw();
    String keyToUse = existingKey ?? MasterRecoveryKeyService.generateKey();

    // Persist securely
    await service.saveRecoveryKey(keyToUse, userEmail: email);

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyKitDialog(
        recoveryKey: keyToUse,
        email: email,
      ),
    );
  }

  @override
  State<EmergencyKitDialog> createState() => _EmergencyKitDialogState();
}

class _EmergencyKitDialogState extends State<EmergencyKitDialog> {
  bool _copied = false;
  bool _confirmed = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.recoveryKey));
    HapticFeedback.selectionClick();
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Recovery key copied to clipboard',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFF9E9A92) : const Color(0xFF635F59);
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(LucideIcons.keyRound, size: 22, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Emergency Kit',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Master Recovery Key',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Please save this key in a safe place (like a password manager or printed on paper). If you ever forget your password or lose access to your email, this key is the only way to recover your account and encrypted data.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: subtextColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              // Key Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212) : const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE2DDD5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    SelectableText(
                      widget.recoveryKey,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.2,
                        color: accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 14),
                      label: Text(
                        _copied ? 'Copied to Clipboard' : 'Copy Key',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirmation Checkbox
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _confirmed = !_confirmed);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _confirmed,
                        activeColor: accent,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _confirmed = v ?? false);
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'I have safely stored my recovery key.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Continue Button
              FilledButton(
                onPressed: _confirmed
                    ? () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(true);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Continue to App',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
