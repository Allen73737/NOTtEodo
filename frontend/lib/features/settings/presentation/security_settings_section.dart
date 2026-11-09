import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Factor;

import '../../../app/theme/app_colors.dart';
import '../../../core/security/password_policy.dart';
import '../../../core/security/security_controller.dart';
import '../../../core/security/sync_keyring.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../auth/presentation/mfa_dialogs.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    content: Text(message, style: GoogleFonts.dmSans(color: Colors.white)),
  ));
}

Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool>? onChanged, Color text, Color sub) {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: sub, height: 1.35)),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.secondary),
    ],
  );
}

Widget _header(String label, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
        ],
      ),
    );

/// Settings → Security: on-device encryption, app lock, biometrics, auto-lock, privacy.
class SecuritySettingsPod extends ConsumerStatefulWidget {
  const SecuritySettingsPod({super.key});

  @override
  ConsumerState<SecuritySettingsPod> createState() => _SecuritySettingsPodState();
}

class _SecuritySettingsPodState extends ConsumerState<SecuritySettingsPod> {
  bool _busy = false;

  bool get _isMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _run(Future<void> Function() task, String done) async {
    setState(() => _busy = true);
    try {
      await task();
      if (mounted) _toast(context, done);
    } catch (e) {
      if (mounted) _toast(context, e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPin({required bool change}) async {
    if (change && !await _confirmCurrentPin()) return;
    if (!mounted) return;
    final pin = await showDialog<String>(context: context, builder: (_) => const PinSetupDialog());
    if (pin == null) return;
    await _run(() => ref.read(securityProvider.notifier).setPin(pin),
        change ? 'PIN changed' : 'App lock is on. Your data is now encrypted with your PIN.');
  }

  Future<void> _removePin() async {
    if (!await _confirmCurrentPin()) return;
    await _run(() => ref.read(securityProvider.notifier).removePin(), 'App lock turned off');
  }

  /// Asks for the current PIN; misses count towards the lockout.
  Future<bool> _confirmCurrentPin() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const _CurrentPinDialog());
    return ok == true;
  }

  Future<void> _toggleBiometrics(bool on) async {
    if (on) {
      await _run(() => ref.read(securityProvider.notifier).enableBiometrics(), 'Biometric unlock is on');
    } else {
      await _run(() => ref.read(securityProvider.notifier).disableBiometrics(), 'Biometric unlock is off');
    }
  }

  Future<void> _toggleWipe(bool on) async {
    if (on) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Erase after 10 failed attempts?'),
          content: const Text('If someone enters a wrong PIN 10 times in a row, everything on this device is erased. '
              'Make sure your data is synced or backed up.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn on')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(securityProvider.notifier).setWipeAfterFailures(on);
  }

  Future<void> _configureVaultPin(BuildContext context) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const PinSetupDialog(title: 'Set 4-Digit Vault PIN'),
    );
    if (pin != null && pin.isNotEmpty) {
      ref.read(appSettingsProvider.notifier).setVaultPin(pin);
      if (context.mounted) {
        _toast(context, 'Vault PIN configured successfully');
      }
    }
  }

  void _removeVaultPin(BuildContext context) {
    ref.read(appSettingsProvider.notifier).setVaultPin(null);
    _toast(context, 'Vault PIN removed');
  }

  static String _lockLabel(int minutes) => switch (minutes) {
        0 => 'Immediately',
        1 => '1 min',
        60 => '1 hour',
        _ => '$minutes min',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final security = ref.watch(securityProvider);
    final settings = ref.watch(appSettingsProvider);
    final storeOpen = LocalStore().isReady;

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header('SECURITY', LucideIcons.shieldCheck),
          // Encryption status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: edBox(
              color: (security.hardwareBacked ? const Color(0xFF2E8B57) : const Color(0xFFC9A227)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(security.hardwareBacked ? LucideIcons.lock : LucideIcons.shieldAlert,
                    size: 18, color: security.hardwareBacked ? const Color(0xFF2E8B57) : const Color(0xFFC9A227)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !storeOpen
                        ? 'Storage is unavailable; nothing is being saved on this device.'
                        : security.hasPin
                            ? 'Encrypted with AES-256-GCM. The key is protected by your PIN and by ${security.keyProtection}.'
                            : 'Encrypted with AES-256-GCM. The key is protected by ${security.keyProtection}. '
                                'Add a PIN so the data cannot be opened without you.',
                    style: GoogleFonts.dmSans(fontSize: 11.5, color: text, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _switchTile(
            'App lock PIN',
            security.hasPin ? 'Needed to open the app and the private journal' : 'Lock the app and encrypt its key with a PIN',
            security.hasPin,
            _busy || !storeOpen ? null : (v) => v ? _setPin(change: false) : _removePin(),
            text,
            sub,
          ),
          if (security.hasPin) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _busy ? null : () => _setPin(change: true), child: const Text('Change PIN')),
            ),
            if (security.biometricAvailable) ...[
              const Divider(height: 20),
              _switchTile(
                'Unlock with ${security.biometricLabel}',
                'The key is released by the secure hardware only after a biometric match',
                security.biometricEnabled,
                _busy ? null : _toggleBiometrics,
                text,
                sub,
              ),
            ],
            const Divider(height: 24),
            Text('Auto-lock', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
            Text('Lock again after the app has been in the background or idle for',
                style: GoogleFonts.dmSans(fontSize: 11, color: sub)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in AppSettings.autoLockChoices)
                  ChoiceChip(
                    label: Text(_lockLabel(m)),
                    selected: settings.autoLockMinutes == m,
                    onSelected: (_) => ref.read(appSettingsProvider.notifier).setAutoLockMinutes(m),
                  ),
              ],
            ),
            const Divider(height: 24),
            _switchTile(
              'Erase after 10 failed attempts',
              'Protects against someone guessing your PIN',
              security.wipeAfterFailures,
              _toggleWipe,
              text,
              sub,
            ),
          ],
          if (_isMobile) ...[
            const Divider(height: 24),
            _switchTile(
              'Hide in app switcher',
              'Blur the screen when you leave the app',
              settings.privacyShield,
              (v) => ref.read(appSettingsProvider.notifier).setPrivacyShield(v),
              text,
              sub,
            ),
          ],
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const Divider(height: 24),
            _switchTile(
              'Block screenshots',
              'Also blocks screen recording and screen sharing of the app',
              settings.blockScreenshots,
              (v) => ref.read(appSettingsProvider.notifier).setBlockScreenshots(v),
              text,
              sub,
            ),
          ],
          const Divider(height: 24),
          _header('PROTECTED ARCHIVE & HIDDEN VAULT', LucideIcons.vault),
          _switchTile(
            'Vault Passcode Protection',
            settings.vaultPin != null && settings.vaultPin!.isNotEmpty
                ? 'PIN active: 4-digit passcode required to access hidden vault'
                : 'Not Set · Vault is locked until a 4-digit PIN is configured',
            settings.vaultPin != null && settings.vaultPin!.isNotEmpty,
            (v) => v ? _configureVaultPin(context) : _removeVaultPin(context),
            text,
            sub,
          ),
          if (settings.vaultPin != null && settings.vaultPin!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _configureVaultPin(context),
                icon: const Icon(LucideIcons.keyRound, size: 14),
                label: const Text('Change Vault 4-Digit PIN'),
              ),
            ),
            _switchTile(
              'Biometric Authentication (Fingerprint)',
              'Allow unlocking the hidden vault using device fingerprint sensor',
              settings.vaultBiometricsEnabled,
              (v) => ref.read(appSettingsProvider.notifier).setVaultBiometricsEnabled(v),
              text,
              sub,
            ),
          ],
        ],
      ),
    );
  }
}

/// End-to-end encryption and two-step verification, shown under Account & sync when signed in.
class CloudSecurityTiles extends StatefulWidget {
  const CloudSecurityTiles({super.key});

  @override
  State<CloudSecurityTiles> createState() => _CloudSecurityTilesState();
}

class _CloudSecurityTilesState extends State<CloudSecurityTiles> {
  List<Factor>? _factors;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadFactors();
    if (SyncKeyring().state.value == E2eeState.unknown) SyncKeyring().refresh();
  }

  Future<void> _loadFactors() async {
    try {
      final f = await SanctuarySupabaseService().totpFactors();
      if (mounted) setState(() => _factors = f);
    } catch (_) {
      if (mounted) setState(() => _factors = const []);
    }
  }

  Future<void> _run(Future<void> Function() task, String done) async {
    setState(() => _busy = true);
    try {
      await task();
      if (mounted) _toast(context, done);
    } catch (e) {
      if (mounted) _toast(context, e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enableE2ee({bool reset = false}) async {
    if (reset) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start over with a new passphrase?'),
          content: const Text('The cloud copy encrypted with your old passphrase can no longer be read. It is replaced '
              'by the data on this device. Other devices will ask for the new passphrase.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Replace cloud copy')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final pass = await showDialog<String>(
      context: context,
      builder: (_) => const PassphraseDialog(
        title: 'Encryption passphrase',
        message: 'Your notes are encrypted on this device before upload, so not even the server can read them. '
            'You will type this passphrase once on each new device. It cannot be recovered if you forget it.',
      ),
    );
    if (pass == null) return;
    await _run(() async {
      await SyncKeyring().enable(pass);
      await CloudSyncService().pushEverything();
    }, 'End-to-end encryption is on');
  }

  Future<void> _unlockE2ee() async {
    final pass = await showDialog<String>(
      context: context,
      builder: (_) => const PassphraseDialog(
        title: 'Enter encryption passphrase',
        message: "This account's cloud data is end-to-end encrypted. Enter the passphrase you chose.",
        confirm: false,
      ),
    );
    if (pass == null) return;
    setState(() => _busy = true);
    final ok = await SyncKeyring().unlock(pass);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast(context, 'Unlocked. Syncing…');
      CloudSyncService().syncNow();
    } else {
      _toast(context, 'That passphrase is not right.');
    }
  }

  Future<void> _changePassphrase() async {
    final pass = await showDialog<String>(
      context: context,
      builder: (_) => const PassphraseDialog(
        title: 'New encryption passphrase',
        message: 'Your data stays encrypted with the same key; only the passphrase that unlocks it changes.',
      ),
    );
    if (pass == null) return;
    await _run(() => SyncKeyring().changePassphrase(pass), 'Passphrase changed');
  }

  Future<void> _disableE2ee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn off end-to-end encryption?'),
        content: const Text('Your cloud copy will be stored readable by the server again (still private to your '
            'account and encrypted in transit).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn off')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await SyncKeyring().disable();
      await CloudSyncService().pushEverything();
    }, 'End-to-end encryption is off');
  }

  Future<void> _addMfa() async {
    final ok = await showMfaEnrollment(context);
    if (!mounted) return;
    if (ok) _toast(context, 'Two-step verification is on');
    _loadFactors();
  }

  Future<void> _removeMfa(Factor f) async {
    if (await SanctuarySupabaseService().needsMfaStepUp()) {
      if (!mounted || !await showMfaChallenge(context)) return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn off two-step verification?'),
        content: const Text('Signing in will only need your password again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn off')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => SanctuarySupabaseService().removeTotp(f.id), 'Two-step verification is off');
    _loadFactors();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    Widget row(IconData icon, String title, String subtitle, List<Widget> actions) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
                        Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: sub, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Wrap(spacing: 4, children: actions),
                ),
            ],
          ),
        );

    return ValueListenableBuilder<E2eeState>(
      valueListenable: SyncKeyring().state,
      builder: (context, e2ee, _) {
        final factor = (_factors?.isNotEmpty ?? false) ? _factors!.first : null;
        final btn = _busy ? null : true;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            switch (e2ee) {
              E2eeState.ready => row(LucideIcons.keyRound, 'End-to-end encryption: on',
                  'Cloud copies are encrypted on this device; the server only stores ciphertext.', [
                  TextButton(onPressed: btn == null ? null : _changePassphrase, child: const Text('Change passphrase')),
                  TextButton(onPressed: btn == null ? null : _disableE2ee, child: const Text('Turn off')),
                ]),
              E2eeState.needsPassphrase => row(LucideIcons.keyRound, 'End-to-end encryption: locked',
                  'Enter your passphrase once on this device to sync.', [
                  FilledButton(onPressed: btn == null ? null : _unlockE2ee, child: const Text('Enter passphrase')),
                  TextButton(onPressed: btn == null ? null : () => _enableE2ee(reset: true), child: const Text('Forgot it?')),
                ]),
              E2eeState.off => row(LucideIcons.keyRound, 'End-to-end encryption: off',
                  'Encrypt cloud copies with a passphrase only you know (zero-knowledge).', [
                  FilledButton(onPressed: btn == null ? null : () => _enableE2ee(), child: const Text('Turn on')),
                ]),
              E2eeState.unknown => row(LucideIcons.keyRound, 'End-to-end encryption', 'Checking…', const []),
            },
            if (_factors != null)
              factor == null
                  ? row(LucideIcons.smartphone, 'Two-step verification: off',
                      'Ask for a code from an authenticator app when signing in.', [
                      FilledButton(onPressed: btn == null ? null : _addMfa, child: const Text('Set up')),
                    ])
                  : row(LucideIcons.smartphone, 'Two-step verification: on',
                      'A code from your authenticator app is needed to sign in.', [
                      TextButton(onPressed: btn == null ? null : () => _removeMfa(factor), child: const Text('Turn off')),
                    ]),
          ],
        );
      },
    );
  }
}

/// Enter a 4–6 digit PIN twice.
class PinSetupDialog extends StatefulWidget {
  final String title;
  const PinSetupDialog({super.key, this.title = 'Set app PIN'});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _error;

  static const _weak = {'0000', '1111', '1234', '4321', '2580', '0852', '000000', '111111', '123456', '654321', '121212', '123123'};

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _a.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'Use 4 to 6 digits (6 is safer)');
    } else if (_weak.contains(pin) || RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      setState(() => _error = 'That PIN is too easy to guess');
    } else if (pin != _b.text.trim()) {
      setState(() => _error = 'The two PINs do not match');
    } else {
      Navigator.pop(context, pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder(), counterText: '');
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _a,
            autofocus: true,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco('New PIN (4–6 digits)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _b,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco('Repeat PIN'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Set PIN')),
      ],
    );
  }
}

class _CurrentPinDialog extends StatefulWidget {
  const _CurrentPinDialog();

  @override
  State<_CurrentPinDialog> createState() => _CurrentPinDialogState();
}

class _CurrentPinDialogState extends State<_CurrentPinDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await LocalStore().verifyPin(_ctrl.text.trim());
    if (!mounted) return;
    if (result == PinResult.unlocked) {
      Navigator.pop(context, true);
      return;
    }
    final until = LocalStore().lockedUntil;
    setState(() {
      _busy = false;
      _ctrl.clear();
      _error = until != null
          ? 'Too many attempts. Try again in ${until.difference(DateTime.now()).inSeconds + 1}s'
          : 'Incorrect PIN';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your current PIN'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        enabled: !_busy,
        obscureText: true,
        maxLength: 6,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(border: const OutlineInputBorder(), counterText: '', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Continue'),
        ),
      ],
    );
  }
}

/// Asks for a passphrase (optionally twice, with a strength meter). Pops with the passphrase.
class PassphraseDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool confirm;
  final String submitLabel;

  /// Shown as an extra action that pops with an empty string (e.g. "Export without password").
  final String? skipLabel;

  const PassphraseDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirm = true,
    this.submitLabel = 'Continue',
    this.skipLabel,
  });

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _a.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _submit() {
    final pass = _a.text;
    if (widget.confirm) {
      final check = PasswordPolicy.evaluate(pass);
      if (!check.acceptable) {
        setState(() => _error = check.problem);
        return;
      }
      if (pass != _b.text) {
        setState(() => _error = 'The two passphrases do not match');
        return;
      }
    } else if (pass.isEmpty) {
      return;
    }
    Navigator.pop(context, pass);
  }

  @override
  Widget build(BuildContext context) {
    final check = widget.confirm && _a.text.isNotEmpty ? PasswordPolicy.evaluate(_a.text) : null;
    const colors = [Color(0xFFC0392B), Color(0xFFD35400), Color(0xFFC9A227), Color(0xFF5E9E6E), Color(0xFF2E8B57)];
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message, style: GoogleFonts.dmSans(fontSize: 12.5, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: _a,
              autofocus: true,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Passphrase',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show' : 'Hide',
                  icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => widget.confirm ? null : _submit(),
            ),
            if (check != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (check.score + 1) / 5,
                color: colors[check.score],
                backgroundColor: colors[check.score].withValues(alpha: 0.15),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 4),
              Text(check.problem ?? check.label, style: TextStyle(fontSize: 11, color: colors[check.score])),
            ],
            if (widget.confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _b,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Repeat passphrase', border: OutlineInputBorder()),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (widget.skipLabel != null)
          TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(widget.skipLabel!)),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
