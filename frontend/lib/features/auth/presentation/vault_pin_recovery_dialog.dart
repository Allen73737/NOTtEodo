import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/recovery_key_service.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';

/// Interactive modal for recovering from a forgotten App Lock PIN:
/// 1. Cloud Account Sign-In (Verifies cloud credentials, wipes local PIN, restores data via pull)
/// 2. Master Recovery Key Verification (Offline 16-char high-entropy recovery key)
/// 3. Device Reset (Safe erase fallback)
class VaultPinRecoveryDialog extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback onReset;

  const VaultPinRecoveryDialog({
    super.key,
    required this.onUnlocked,
    required this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUnlocked,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: VaultPinRecoveryDialog(
          onUnlocked: onUnlocked,
          onReset: onReset,
        ),
      ),
    );
  }

  @override
  ConsumerState<VaultPinRecoveryDialog> createState() => _VaultPinRecoveryDialogState();
}

class _VaultPinRecoveryDialogState extends ConsumerState<VaultPinRecoveryDialog> {
  int _selectedMethod = 0; // 0: Cloud Account, 1: Master Key, 2: Device Reset

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _busy = false;
  String? _message;
  bool _isSuccess = false;

  final _recoveryService = MasterRecoveryKeyService();

  @override
  void initState() {
    super.initState();
    final user = SanctuarySupabaseService().currentUser;
    if (user?.email != null) {
      _emailCtrl.text = user!.email!;
    } else {
      final savedEmail = _recoveryService.associatedEmail;
      if (savedEmail != null) _emailCtrl.text = savedEmail;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String text, {bool success = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _isSuccess = success;
    });
  }

  // --- Method 1: Cloud Account Sign-in Recovery ---
  Future<void> _recoverWithCloudAccount() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _setStatus('Please enter your cloud account email.');
      return;
    }
    if (password.isEmpty) {
      _setStatus('Please enter your cloud account password.');
      return;
    }

    setState(() => _busy = true);
    _setStatus('');

    try {
      final supabase = SanctuarySupabaseService();
      if (!supabase.isInitialized) {
        throw StateError('Cloud service is not initialized.');
      }

      // Verify credentials with Supabase
      final res = await supabase.signIn(email: email, password: password);
      if (res?.user == null) {
        throw StateError('Could not verify cloud credentials.');
      }

      _setStatus('Cloud credentials verified! Restoring your sanctuary…', success: true);
      HapticFeedback.heavyImpact();

      // Clear forgotten device PIN while keeping cloud intact
      await LocalStore().eraseAll();
      ref.read(appSettingsProvider.notifier).reloadFromStore();

      // Pull fresh data from cloud
      await CloudSyncService().pull();

      if (mounted) {
        Navigator.pop(context);
        widget.onUnlocked();
      }
    } catch (e) {
      _setStatus(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- Method 2: Master Recovery Key ---
  Future<void> _recoverWithMasterKey() async {
    final keyInput = _keyCtrl.text.trim();
    if (keyInput.isEmpty) {
      _setStatus('Please enter your 16-character Master Recovery Key.');
      return;
    }

    setState(() => _busy = true);
    _setStatus('');

    try {
      final verification = await _recoveryService.verifyRecoveryKey(keyInput);
      if (!verification.isValid) {
        _setStatus(verification.errorMessage ?? 'Invalid Master Recovery Key');
        return;
      }

      _setStatus('Master Recovery Key verified! Resetting device PIN…', success: true);
      HapticFeedback.heavyImpact();

      // Reset PIN
      await LocalStore().eraseAll();
      ref.read(appSettingsProvider.notifier).reloadFromStore();

      if (SanctuarySupabaseService().isConnectedToCloud) {
        await CloudSyncService().pull();
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onUnlocked();
      }
    } catch (e) {
      _setStatus(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- Method 3: Erase Device ---
  Future<void> _eraseDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase All Local Data?'),
        content: const Text(
          'This will permanently delete all un-synced notes, tasks, and data stored on this device. '
          'Synced cloud data will remain safe in your cloud account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Erase Device'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (SanctuarySupabaseService().currentUser != null) {
      await SanctuarySupabaseService().signOut();
    }
    CloudSyncService().resetForAccountChange();
    await LocalStore().eraseAll();
    ref.read(appSettingsProvider.notifier).reloadFromStore();

    if (mounted) {
      Navigator.pop(context);
      widget.onReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFE2B6BB) : AppColors.secondary;
    final borderColor = isDark ? const Color(0xFF222222) : const Color(0xFFEFE8E4);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 1.2),
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
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.shieldCheck, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forgot PIN? · Vault Recovery',
                      style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: text),
                    ),
                    Text(
                      'Authenticate to remove the PIN and restore your synced sanctuary',
                      style: GoogleFonts.dmSans(fontSize: 11, color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented choices
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : const Color(0xFFF7F2EF),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _choiceTab(0, 'Cloud Sign-In', LucideIcons.cloud),
                _choiceTab(1, 'Master Key', LucideIcons.keyRound),
                _choiceTab(2, 'Erase Reset', LucideIcons.trash2),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status Banner
          if (_message != null && _message!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? const Color(0xFF2E8B57).withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess
                      ? const Color(0xFF2E8B57).withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                    size: 16,
                    color: _isSuccess ? const Color(0xFF2E8B57) : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: _isSuccess ? const Color(0xFF2E8B57) : AppColors.error,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Form views
          if (_selectedMethod == 0) _buildCloudAccountView(text, sub, accent, isDark),
          if (_selectedMethod == 1) _buildMasterKeyView(text, sub, accent, isDark),
          if (_selectedMethod == 2) _buildEraseResetView(text, sub, accent, isDark),
        ],
      ),
    );
  }

  Widget _choiceTab(int index, String label, IconData icon) {
    final active = _selectedMethod == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFE2B6BB) : AppColors.secondary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedMethod = index;
            _message = null;
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
                  fontSize: 11.5,
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

  // --- Cloud View ---
  Widget _buildCloudAccountView(Color text, Color sub, Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify your cloud account credentials. Once verified, the device PIN is safely cleared and your synced data is immediately restored.',
          style: GoogleFonts.dmSans(fontSize: 12, color: sub),
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _emailCtrl,
          label: 'Cloud Email',
          icon: LucideIcons.mail,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _inputField(
          controller: _passCtrl,
          label: 'Cloud Password',
          icon: LucideIcons.lock,
          isDark: isDark,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(_obscurePass ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _busy ? null : _recoverWithCloudAccount,
          icon: const Icon(LucideIcons.shieldCheck, size: 16, color: Colors.white),
          label: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Verify & Restore via Cloud', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // --- Master Key View ---
  Widget _buildMasterKeyView(Color text, Color sub, Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 16-character Master Recovery Key configured for this device to bypass the PIN and unlock the vault.',
          style: GoogleFonts.dmSans(fontSize: 12, color: sub),
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _keyCtrl,
          label: 'Master Recovery Key (e.g. NOTT-XXXX-XXXX-XXXX)',
          icon: LucideIcons.keyRound,
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
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _busy ? null : _recoverWithMasterKey,
          icon: const Icon(LucideIcons.unlock, size: 16, color: Colors.white),
          label: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Verify Master Key & Unlock', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // --- Erase Reset View ---
  Widget _buildEraseResetView(Color text, Color sub, Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'If you did not enable cloud sync and do not have a Master Recovery Key, resetting this device is the only option. Unsaved local data cannot be recovered by anyone.',
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: text, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _eraseDevice,
          icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
          label: Text('Erase Device & Reset App', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
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
        prefixIcon: Icon(icon, size: 16, color: isDark ? const Color(0xFFE2B6BB) : AppColors.secondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFFE2B6BB) : AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}
