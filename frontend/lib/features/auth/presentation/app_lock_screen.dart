import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/security_controller.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/app_settings.dart';

/// Shown at launch and after auto-lock when an app PIN is set.
///
/// The PIN is never compared with a stored hash. It derives the key that decrypts
/// this device's data, so a wrong PIN simply fails to decrypt.
class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  /// Called after the device was erased (forgotten PIN, or too many misses with auto-erase on).
  final VoidCallback onReset;

  const AppLockScreen({super.key, required this.onUnlocked, required this.onReset});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> with WidgetsBindingObserver {
  static const int maxLength = 6;

  final FocusNode _focus = FocusNode();
  String _entry = '';
  bool _checking = false;
  Timer? _tick;
  String? _message;

  LocalStore get _store => LocalStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCooldownTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      // When auto-lock fired in the background, wait until the user is back.
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) _autoBiometric();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoBiometric();
  }

  void _autoBiometric() {
    if (mounted && _store.biometricEnabled && !_cooling && !_checking) _biometric();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _focus.dispose();
    super.dispose();
  }

  bool get _cooling => _store.lockedUntil != null;

  int get _secondsLeft {
    final until = _store.lockedUntil;
    return until == null ? 0 : until.difference(DateTime.now()).inSeconds + 1;
  }

  void _startCooldownTicker() {
    _tick?.cancel();
    if (!_cooling) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_cooling) _tick?.cancel();
    });
  }

  void _press(String digit) {
    if (_checking || _cooling || _entry.length >= maxLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entry += digit;
      _message = null;
    });
    if (_entry.length == (_store.pinLength ?? maxLength)) _submit();
  }

  void _backspace() {
    if (_checking || _entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    if (_checking || _cooling || _entry.length < 4) return;
    final pin = _entry;
    setState(() => _checking = true);
    final result = await _store.unlockWithPin(pin);
    if (!mounted) return;
    switch (result) {
      case PinResult.unlocked:
        widget.onUnlocked();
        return;
      case PinResult.wiped:
        CloudSyncService().resetForAccountChange();
        if (SanctuarySupabaseService().currentUser != null) await SanctuarySupabaseService().signOut();
        ref.read(appSettingsProvider.notifier).reloadFromStore();
        widget.onReset();
        return;
      case PinResult.wrong:
      case PinResult.coolingDown:
        HapticFeedback.heavyImpact();
        setState(() {
          _checking = false;
          _entry = '';
          _message = _failureMessage();
        });
        _startCooldownTicker();
    }
  }

  String _failureMessage() {
    final misses = _store.failedAttempts;
    if (_store.wipeAfterFailures) {
      final left = LocalStore.wipeThreshold - misses;
      return 'Incorrect PIN. $left ${left == 1 ? 'try' : 'tries'} left before this device is erased.';
    }
    if (misses < LocalStore.freeAttempts) {
      final left = LocalStore.freeAttempts - misses;
      return 'Incorrect PIN. $left ${left == 1 ? 'try' : 'tries'} before a pause.';
    }
    return 'Too many attempts.';
  }

  Future<void> _biometric() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await _store.unlockWithBiometrics();
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _checking = false;
        _message = _store.biometricEnabled ? null : 'Biometrics changed on this device. Enter your PIN.';
      });
      _focus.requestFocus();
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final ch = event.character;
    if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
      _press(ch);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _forgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot your PIN?'),
        content: const Text(
          'Your data is encrypted with your PIN, so nobody (including us) can recover it. You can erase this '
          'device and start over. If you use a cloud account, sign in again afterwards to get your synced data back.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase this device', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Sign out first so the emptied device never syncs over the cloud copy.
    if (SanctuarySupabaseService().currentUser != null) {
      await SanctuarySupabaseService().signOut();
    }
    CloudSyncService().resetForAccountChange();
    await LocalStore().eraseAll();
    ref.read(appSettingsProvider.notifier).reloadFromStore();
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final security = ref.watch(securityProvider);
    final pinLength = _store.pinLength ?? maxLength;
    final bioLabel = security.biometricLabel ?? 'biometrics';

    final status = _checking
        ? 'Unlocking…'
        : _cooling
            ? 'Too many attempts. Try again in ${_secondsLeft}s'
            : (_message ?? '');

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.lock, size: 34, color: accent),
                      const SizedBox(height: 14),
                      Text('Enter your PIN',
                          style: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.bold, color: text)),
                      const SizedBox(height: 4),
                      Text('Your data is encrypted on this device',
                          style: GoogleFonts.dmSans(fontSize: 12, color: sub)),
                      const SizedBox(height: 18),
                      Semantics(
                        label: '${_entry.length} of $pinLength digits entered',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pinLength, (i) {
                            final filled = i < _entry.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled ? accent : Colors.transparent,
                                border: Border.all(color: filled ? accent : sub.withValues(alpha: 0.5), width: 1.5),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: _checking
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                )
                              : Text(
                                  status,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.error),
                                ),
                        ),
                      ),
                      for (final row in const [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                      ])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [for (final d in row) _key(d, text, isDark)],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          security.biometricEnabled
                              ? _iconKey(LucideIcons.scanFace, 'Unlock with $bioLabel', _biometric, accent)
                              : _iconKey(LucideIcons.delete, 'Delete', _backspace, text),
                          _key('0', text, isDark),
                          _store.pinLength == null
                              ? _iconKey(LucideIcons.check, 'Unlock', _submit, accent)
                              : _iconKey(LucideIcons.delete, 'Delete', _backspace, text),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: _checking ? null : _forgotPin,
                        child: Text('Forgot PIN?', style: GoogleFonts.dmSans(fontSize: 13, color: sub)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _key(String digit, Color text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _press(digit),
          child: SizedBox(
            width: 68,
            height: 68,
            child: Center(
                child: Text(digit, style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w600, color: text))),
          ),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, String label, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        tooltip: label,
        iconSize: 26,
        constraints: const BoxConstraints.tightFor(width: 68, height: 68),
        onPressed: onTap,
        icon: Icon(icon, color: color),
      ),
    );
  }
}
