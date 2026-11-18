import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/recovery_key_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';

/// Modal dialog providing 3-tier password recovery & sanctuary data rescue:
/// 1. Standard Cloud Email Reset
/// 2. Cryptographic Master Recovery Key (for fake/inaccessible emails or offline recovery)
/// 3. In-App Data Rescue & Local Sanctuary Mode (zero cloud lockouts)
class AccountRecoveryDialog extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onContinueOffline;
  final void Function(String email, String newPassword)? onCredentialsReset;

  const AccountRecoveryDialog({
    super.key,
    required this.initialEmail,
    required this.onContinueOffline,
    this.onCredentialsReset,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialEmail,
    required VoidCallback onContinueOffline,
    void Function(String email, String newPassword)? onCredentialsReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AccountRecoveryDialog(
          initialEmail: initialEmail,
          onContinueOffline: onContinueOffline,
          onCredentialsReset: onCredentialsReset,
        ),
      ),
    );
  }

  @override
  State<AccountRecoveryDialog> createState() => _AccountRecoveryDialogState();
}

class _AccountRecoveryDialogState extends State<AccountRecoveryDialog> {
  int _selectedTab = 0; // 0: Email Reset, 1: Master Key, 2: Sanctuary Rescue
  late final TextEditingController _emailCtrl;
  final _keyCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _busy = false;
  String? _statusMessage;
  bool _isSuccess = false;

  final _recoveryService = MasterRecoveryKeyService();

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    // If a recovery key is present on device, default to Master Key tab when email is placeholder
    if (widget.initialEmail.contains('fake') ||
        widget.initialEmail.contains('example') ||
        widget.initialEmail.contains('test')) {
      _selectedTab = 1;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _keyCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  void _setMessage(String message, {bool success = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _isSuccess = success;
    });
  }

  // --- 1. Email Reset ---
  Future<void> _sendEmailReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _setMessage('Please enter a valid email address.');
      return;
    }
    setState(() => _busy = true);
    _setMessage('');
    try {
      await SanctuarySupabaseService().sendPasswordReset(email);
      _setMessage('If an account exists for $email, a secure reset link has been dispatched.', success: true);
    } catch (e) {
      _setMessage(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- 2. Master Recovery Key Verification ---
  Future<void> _verifyAndResetWithKey() async {
    final keyInput = _keyCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (keyInput.isEmpty) {
      _setMessage('Please enter your 16-character Master Recovery Key.');
      return;
    }

    if (newPass.length < 8) {
      _setMessage('New password must be at least 8 characters long.');
      return;
    }

    setState(() => _busy = true);
    _setMessage('');

    try {
      final verification = await _recoveryService.verifyRecoveryKey(keyInput, email: email.isNotEmpty ? email : null);
      if (!verification.isValid) {
        _setMessage(verification.errorMessage ?? 'Invalid Master Recovery Key');
        return;
      }

      // If user has an active session, update password in cloud
      final supabase = SanctuarySupabaseService();
      if (supabase.isConnectedToCloud) {
        await supabase.updateUserPassword(newPass);
      }

      _setMessage('Master Recovery Key verified! Password has been successfully updated.', success: true);
      HapticFeedback.heavyImpact();

      widget.onCredentialsReset?.call(email, newPass);
    } catch (e) {
      _setMessage(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- 3. Export Local Vault ---
  void _exportLocalVault() {
    HapticFeedback.selectionClick();
    try {
      final jsonDump = _recoveryService.rescueLocalVaultToJson();
      Clipboard.setData(ClipboardData(text: jsonDump));
      _setMessage('Sanctuary vault backup copied to clipboard! You can paste and save it safely.', success: true);
    } catch (e) {
      _setMessage('Failed to export vault: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: sub.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181414) : const Color(0xFFF2ECE6)),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.keyRound, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account & Vault Recovery',
                      style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                    ),
                    Text(
                      'Multiple pathways to recover your account or access your local data',
                      style: GoogleFonts.dmSans(fontSize: 12, color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F2EF),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _tabButton(0, 'Email Reset', LucideIcons.mail),
                _tabButton(1, 'Master Key', LucideIcons.shieldCheck),
                _tabButton(2, 'Sanctuary Rescue', LucideIcons.hardDriveDownload),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status Banner
          if (_statusMessage != null && _statusMessage!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? const Color(0xFF8E2433).withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                    size: 16,
                    color: _isSuccess ? const Color(0xFF8E2433) : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: _isSuccess ? const Color(0xFF8E2433) : AppColors.error,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Tab Content
          if (_selectedTab == 0) _buildEmailTab(text, sub, accent, isDark),
          if (_selectedTab == 1) _buildMasterKeyTab(text, sub, accent, isDark),
          if (_selectedTab == 2) _buildSanctuaryRescueTab(text, sub, accent, isDark),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final active = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFD0485A) : AppColors.secondary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedTab = index;
            _statusMessage = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? (isDark ? const Color(0xFF242424) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: active ? accent : sub),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? (isDark ? AppColors.darkTextPrimary : AppColors.primary) : sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Email Tab ---
  Widget _buildEmailTab(Color text, Color sub, Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Receive a reset link via email to re-authenticate with the cloud.',
          style: GoogleFonts.dmSans(fontSize: 12, color: sub),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailCtrl,
          label: 'Account Email',
          icon: LucideIcons.mail,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : _sendEmailReset,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Send Password Reset Link', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Used a fake or typo email? Switch to "Master Key" or "Sanctuary Rescue" above.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12, color: sub.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }

  // --- 2. Master Key Tab ---
  Widget _buildMasterKeyTab(Color text, Color sub, Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Used a dummy email or lost inbox access? Enter your 16-character Master Recovery Key to reset your password.',
          style: GoogleFonts.dmSans(fontSize: 12, color: sub),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _keyCtrl,
          label: 'Master Recovery Key (e.g. NOTT-XXXX-XXXX-XXXX)',
          icon: LucideIcons.shieldAlert,
          isDark: isDark,
          textCapitalization: TextCapitalization.characters,
          suffixIcon: IconButton(
            icon: const Icon(LucideIcons.clipboard, size: 16),
            tooltip: 'Paste from clipboard',
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) {
                _keyCtrl.text = data!.text!.trim().toUpperCase();
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _newPassCtrl,
          label: 'New Password (min 8 characters)',
          icon: LucideIcons.lock,
          isDark: isDark,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(_obscurePass ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : _verifyAndResetWithKey,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Verify Key & Set New Password', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  // --- 3. Sanctuary Rescue Tab ---
  Widget _buildSanctuaryRescueTab(Color text, Color sub, Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181414) : const Color(0xFFF2ECE6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NOTtEodo stores all your notes, tasks, habits, and expenses locally on this device first. You are never trapped or locked out of your data.',
                  style: GoogleFonts.dmSans(fontSize: 12.5, color: text, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Continue Offline button
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onContinueOffline();
          },
          icon: const Icon(LucideIcons.folderOpen, size: 16, color: Colors.white),
          label: Text('Enter Local Sanctuary (Continue Offline)', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
        const SizedBox(height: 8),
        // Export Local Vault button
        OutlinedButton.icon(
          onPressed: _exportLocalVault,
          icon: Icon(LucideIcons.hardDriveDownload, size: 16, color: accent),
          label: Text('Export Local Vault Backup (JSON)', style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: accent)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2DDD7);
    final fill = isDark ? const Color(0xFF141414) : const Color(0xFFFBF8F5);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? AppColors.darkTextPrimary : AppColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 16, color: isDark ? const Color(0xFFD0485A) : AppColors.secondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFFD0485A) : AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}
