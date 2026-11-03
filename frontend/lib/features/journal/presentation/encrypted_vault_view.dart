import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/security/security_controller.dart';
import '../../../core/services/local_store.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';

/// Private journal entries, shown after the app PIN (or biometrics) is confirmed again.
///
/// Like everything else, the entries are AES-256-GCM encrypted on disk; this screen adds a
/// second check so an unlocked, unattended device does not expose them.
class EncryptedVaultView extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const EncryptedVaultView({super.key, required this.onClose});

  @override
  ConsumerState<EncryptedVaultView> createState() => _EncryptedVaultViewState();
}

class _EncryptedVaultViewState extends ConsumerState<EncryptedVaultView> {
  String _enteredPin = '';
  bool _isUnlocked = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && LocalStore().biometricEnabled) _biometric();
    });
  }

  Future<void> _biometric() async {
    final secret = await LocalStore().deviceKeys?.readBiometricSecret(reason: 'Open your private journal');
    if (!mounted) return;
    if (secret != null) setState(() => _isUnlocked = true);
  }

  void _onKeyPress(String val) {
    if (_checking || _enteredPin.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin += val;
      _error = null;
    });
    if (_enteredPin.length == LocalStore().pinLength) _submit();
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  Future<void> _submit() async {
    if (_checking) return;
    setState(() => _checking = true);
    final result = await LocalStore().verifyPin(_enteredPin);
    if (!mounted) return;
    if (result == PinResult.unlocked) {
      setState(() => _isUnlocked = true);
    } else {
      HapticFeedback.heavyImpact();
      final until = LocalStore().lockedUntil;
      setState(() {
        _checking = false;
        _enteredPin = '';
        _error = until != null
            ? 'Too many attempts. Try again in ${until.difference(DateTime.now()).inSeconds + 1}s'
            : 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final security = ref.watch(securityProvider);
    final hasPin = security.hasPin;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to journal',
                    icon: Icon(LucideIcons.arrowLeft, color: primaryTextColor),
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: 4),
                  Text('Private Vault',
                      style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: !hasPin
                    ? _buildNoPin(subtextColor)
                    : _isUnlocked
                        ? _buildUnlockedVault(primaryTextColor, subtextColor, isDark)
                        : _buildPinKeypad(primaryTextColor, subtextColor, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPin(Color subtextColor) {
    return const EmptyState(
      icon: LucideIcons.lock,
      title: 'Set a PIN to use the vault',
      message: 'Go to Settings → Security and turn on "App lock PIN". Private journal entries then open here with that PIN.',
    );
  }

  Widget _buildPinKeypad(Color primaryTextColor, Color subtextColor, bool isDark) {
    final accent = isDark ? AppColors.goldLight : AppColors.secondary;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your app PIN', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
            const SizedBox(height: 14),
            if (_checking)
              SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
            else
              Text(_error ?? '•' * _enteredPin.length,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: _error == null ? 26 : 13, letterSpacing: _error == null ? 6 : 0, color: _error == null ? accent : AppColors.error)),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) _keypadBtn(d, primaryTextColor, isDark),
                ref.watch(securityProvider).biometricEnabled
                    ? IconButton(tooltip: 'Use ${ref.watch(securityProvider).biometricLabel ?? 'biometrics'}', icon: Icon(LucideIcons.scanFace, color: accent), onPressed: _biometric)
                    : IconButton(tooltip: 'Delete', icon: Icon(LucideIcons.delete, color: primaryTextColor), onPressed: _onBackspace),
                _keypadBtn('0', primaryTextColor, isDark),
                IconButton(
                  tooltip: 'Unlock',
                  icon: Icon(LucideIcons.check, color: accent),
                  onPressed: _enteredPin.length >= 4 ? _submit : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _keypadBtn(String val, Color primaryTextColor, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _onKeyPress(val),
        child: Center(child: Text(val, style: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor))),
      ),
    );
  }

  Widget _buildUnlockedVault(Color primaryTextColor, Color subtextColor, bool isDark) {
    final entries = ref.watch(journalProvider).where((m) => m.isPrivate).toList();
    if (entries.isEmpty) {
      return EmptyState(
        icon: LucideIcons.bookLock,
        title: 'No private entries',
        message: 'When writing a journal entry, turn on "Keep in the private vault".',
        action: TextButton(onPressed: () => openEntryEditor(context, EntryKind.memoir), child: const Text('Write one')),
      );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = entries[i];
        return Material(
          color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Icon(LucideIcons.lock, color: isDark ? AppColors.goldLight : AppColors.secondary),
            title: Text(m.title, style: GoogleFonts.bodoniModa(fontWeight: FontWeight.bold, color: primaryTextColor)),
            subtitle: Text('${DateLabels.long(m.createdAt)} · ${m.excerpt}',
                maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
            onTap: () => openEntryEditor(context, EntryKind.memoir, editing: m),
          ),
        );
      },
    );
  }
}
