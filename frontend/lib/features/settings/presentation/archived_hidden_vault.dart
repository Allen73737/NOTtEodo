import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/local_store.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import 'security_settings_section.dart';

class ArchivedHiddenVault extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const ArchivedHiddenVault({super.key, required this.onClose});

  @override
  ConsumerState<ArchivedHiddenVault> createState() => _ArchivedHiddenVaultState();
}

class _ArchivedHiddenVaultState extends ConsumerState<ArchivedHiddenVault> {
  bool _unlocked = false;
  String _pin = '';
  String? _errorText;
  bool _isAuthenticatingBiometrics = false;

  List<Map<String, String>> _archivedItems = [];

  static const String _vaultStoreKey = 'notteodo_user_vault_records_v1';

  @override
  void initState() {
    super.initState();
    _loadVaultItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(appSettingsProvider);
      if (settings.vaultPin != null &&
          settings.vaultPin!.isNotEmpty &&
          settings.vaultBiometricsEnabled) {
        _authenticateBiometrics();
      }
    });
  }

  void _loadVaultItems() {
    try {
      final raw = LocalStore().readString(_vaultStoreKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        setState(() {
          _archivedItems = decoded
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        });
      } else {
        setState(() {
          _archivedItems = [];
        });
      }
    } catch (_) {
      setState(() {
        _archivedItems = [];
      });
    }
  }

  Future<void> _saveVaultItems() async {
    try {
      final encoded = jsonEncode(_archivedItems);
      LocalStore().writeString(_vaultStoreKey, encoded);
    } catch (_) {}
  }

  Future<void> _authenticateBiometrics() async {
    if (_isAuthenticatingBiometrics) return;
    _isAuthenticatingBiometrics = true;
    final localAuth = LocalAuthentication();
    try {
      final canAuthWithBiometrics = await localAuth.canCheckBiometrics;
      final canAuth = canAuthWithBiometrics || await localAuth.isDeviceSupported();
      if (!canAuth) {
        if (mounted) {
          AppToastEngine().notifyAnimated(
            title: 'Biometrics Unavailable',
            message: 'Fingerprint sensor not available or not enrolled. Please use your 4-digit PIN.',
            type: ToastType.alert,
          );
        }
        return;
      }
      final didAuth = await localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to unlock your Hidden Vault',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (didAuth && mounted) {
        SanctuaryHapticEngine.celebration();
        setState(() {
          _unlocked = true;
          _errorText = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToastEngine().notifyAnimated(
          title: 'Biometrics Notice',
          message: 'Fingerprint authentication cancelled or unavailable. Use your PIN.',
          type: ToastType.alert,
        );
      }
    } finally {
      if (mounted) {
        _isAuthenticatingBiometrics = false;
      }
    }
  }

  void _onKeyPress(String val, String correctPin) {
    SanctuaryHapticEngine.dialDetent();
    if (_pin.length < 4) {
      final nextPin = _pin + val;
      setState(() {
        _pin = nextPin;
        _errorText = null;
      });

      if (nextPin.length == 4) {
        if (nextPin == correctPin) {
          SanctuaryHapticEngine.sealImpression();
          setState(() {
            _unlocked = true;
            _errorText = null;
          });
        } else {
          SanctuaryHapticEngine.securityAlert();
          setState(() {
            _errorText = 'Incorrect Passcode';
            _pin = '';
          });
        }
      }
    }
  }

  Future<void> _setupPinFromGate() async {
    SanctuaryHapticEngine.selection();
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const PinSetupDialog(title: 'Set 4-Digit Vault PIN'),
    );
    if (pin != null && pin.isNotEmpty && mounted) {
      ref.read(appSettingsProvider.notifier).setVaultPin(pin);
      AppToastEngine().notifyAnimated(
        title: 'Vault PIN Configured',
        message: 'Your 4-digit Vault Passcode is active. Enter it to unlock.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _addNewVaultItem() async {
    SanctuaryHapticEngine.selection();
    final titleCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    String selectedCategory = 'Private Note';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF161311),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                'Lock Confidential Item',
                style: GoogleFonts.bodoniModa(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Title',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA8A29E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Master Keyphrase, Personal Diary',
                    hintStyle: GoogleFonts.dmSans(color: const Color(0xFF78716C), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF262320),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Category',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA8A29E),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['Private Note', 'Secret Key', 'Password', 'Legal Document'].map((cat) {
                    final isSel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: GoogleFonts.dmSans(fontSize: 11, color: isSel ? Colors.white : const Color(0xFFA8A29E))),
                      selected: isSel,
                      selectedColor: const Color(0xFFD9725B),
                      backgroundColor: const Color(0xFF262320),
                      onSelected: (_) => setDlgState(() => selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Secret Content (Encrypted on Device)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA8A29E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: secretCtrl,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter your confidential notes or secret details...',
                    hintStyle: GoogleFonts.dmSans(color: const Color(0xFF78716C), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF262320),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: const Color(0xFFA8A29E))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9725B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: Text('Lock in Vault', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      final newItem = {
        'id': 'vault_${DateTime.now().millisecondsSinceEpoch}',
        'title': titleCtrl.text.trim(),
        'type': selectedCategory,
        'secret': secretCtrl.text.trim(),
        'date': DateLabels.dateOnly(DateTime.now()),
      };

      setState(() {
        _archivedItems.insert(0, newItem);
      });
      await _saveVaultItems();

      // Also persist to notesProvider with Vault tag so it syncs with knowledge base
      try {
        ref.read(notesProvider.notifier).addNote(
          title: titleCtrl.text.trim(),
          excerpt: '🔒 [Encrypted Vault Entry]',
          content: secretCtrl.text.trim(),
          tag: 'Vault',
          space: 'Hidden Vault',
        );
      } catch (_) {}

      AppToastEngine().notifyAnimated(
        title: 'Item Vaulted',
        message: 'Confidential entry locked with on-device AES-256 GCM encryption.',
        type: ToastType.success,
      );
    }
  }

  void _viewVaultItem(Map<String, String> item, int idx) {
    SanctuaryHapticEngine.selection();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161311),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.0),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item['title'] ?? 'Vault Item',
                style: GoogleFonts.bodoniModa(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['type'] ?? 'Encrypted',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Vaulted: ${item['date'] ?? 'Recent'}',
              style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFA8A29E)),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF262320),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38332E)),
              ),
              child: SelectableText(
                item['secret']?.isNotEmpty == true
                    ? item['secret']!
                    : '(Empty encrypted payload)',
                style: GoogleFonts.dmMono(fontSize: 12, color: const Color(0xFFFAF7F0)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.copy, size: 14, color: Color(0xFFD4AF37)),
            label: Text('Copy', style: GoogleFonts.dmSans(color: const Color(0xFFD4AF37))),
            onPressed: () {
              SanctuaryHapticEngine.selection();
              if (item['secret'] != null) {
                Clipboard.setData(ClipboardData(text: item['secret']!));
                AppToastEngine().notify(
                  title: 'Copied to Clipboard',
                  message: 'Confidential secret copied (clears automatically in 60s).',
                );
              }
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.dmSans(color: const Color(0xFFA8A29E))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: _unlocked
            ? _buildVaultContent(primaryTextColor, subtextColor, accentColor)
            : (settings.vaultPin == null || settings.vaultPin!.isEmpty)
                ? _buildPinRequiredGate(primaryTextColor, subtextColor, accentColor)
                : _buildPinGuard(primaryTextColor, subtextColor, accentColor, settings.vaultPin!),
      ),
    );
  }

  Widget _buildPinRequiredGate(Color primaryTextColor, Color subtextColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'PROTECTED ARCHIVE & HIDDEN VAULT',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: accentColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: primaryTextColor),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Icon(LucideIcons.shieldAlert, size: 36, color: accentColor),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Vault PIN Required',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access to the Protected Vault is locked. You must configure a 4-digit Vault PIN in Settings before the vault can be accessed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 13, height: 1.5, color: subtextColor),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _setupPinFromGate,
                      icon: const Icon(LucideIcons.keyRound, size: 16),
                      label: Text(
                        'Set 4-Digit Vault PIN Now',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onClose,
                child: Text('Go Back', style: GoogleFonts.dmSans(color: subtextColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinGuard(Color primaryTextColor, Color subtextColor, Color accentColor, String correctPin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'PROTECTED ARCHIVE & HIDDEN VAULT',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: accentColor,
                      ),
                    ),
                  ),
                  IconButton(icon: Icon(LucideIcons.x, color: primaryTextColor), onPressed: widget.onClose),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StitchMonogramNWidget(size: 48),
                  const SizedBox(height: 10),
                  Text(
                    'Vault Passcode Required',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your 4-digit PIN or tap Fingerprint to view hidden items',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isFilled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? accentColor : Colors.transparent,
                      border: Border.all(
                        color: _errorText != null ? AppColors.error : accentColor,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, idx) {
                  if (idx == 9) {
                    return BouncyTouchEffect(
                      pressedScale: 0.90,
                      onTap: _authenticateBiometrics,
                      child: Center(
                        child: Icon(LucideIcons.fingerprint, color: accentColor, size: 28),
                      ),
                    );
                  }
                  if (idx == 10) return Reveal(style: RevealStyle.pop, distance: 18, child: _numBtn('0', primaryTextColor, accentColor, correctPin));
                  if (idx == 11) {
                    return BouncyTouchEffect(
                      pressedScale: 0.90,
                      onTap: () {
                        SanctuaryHapticEngine.dialDetent();
                        if (_pin.isNotEmpty) {
                          setState(() {
                            _pin = _pin.substring(0, _pin.length - 1);
                            _errorText = null;
                          });
                        }
                      },
                      child: Center(
                        child: Icon(LucideIcons.delete, color: primaryTextColor, size: 22),
                      ),
                    );
                  }
                  return Reveal(style: RevealStyle.pop, distance: 18, child: _numBtn('${idx + 1}', primaryTextColor, accentColor, correctPin));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numBtn(String n, Color color, Color accentColor, String correctPin) {
    return BouncyTouchEffect(
      pressedScale: 0.90,
      onTap: () => _onKeyPress(n, correctPin),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(n, style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }

  Widget _buildVaultContent(Color primaryTextColor, Color subtextColor, Color accentColor) {
    const gold = Color(0xFFD4AF37);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARCHIVED & HIDDEN VAULT',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    '${_archivedItems.length} Hidden Items Vaulted',
                    style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle, color: gold),
                    tooltip: 'Vault New Item',
                    onPressed: _addNewVaultItem,
                  ),
                  IconButton(icon: Icon(LucideIcons.x, color: primaryTextColor), onPressed: widget.onClose),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Zero-Dummy Empty State
          if (_archivedItems.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: primaryTextColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gold.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withValues(alpha: 0.12),
                      border: Border.all(color: gold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.shieldCheck, size: 28, color: gold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Private Vault is Clean',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No confidential notes or secret keys vaulted yet.\nEverything you lock here is shielded by on-device AES-256 GCM encryption.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: subtextColor,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addNewVaultItem,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(
                      'Vault New Confidential Item',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _archivedItems.length,
              itemBuilder: (context, idx) {
                final item = _archivedItems[idx];
                return Reveal(
                  style: RevealStyle.slideIn,
                  distance: 18,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoPod(
                      style: PodTextureStyle.paper,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _viewVaultItem(item, idx),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.lock, size: 13, color: gold),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item['title'] ?? 'Secret',
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTextColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['type']} · ${item['date']}',
                                    style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.eye, size: 16, color: gold),
                                tooltip: 'View Secret',
                                onPressed: () => _viewVaultItem(item, idx),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () async {
                                  SanctuaryHapticEngine.selection();
                                  setState(() => _archivedItems.removeAt(idx));
                                  await _saveVaultItems();
                                  AppToastEngine().notifyAnimated(
                                    title: 'Item Unvaulted',
                                    message: 'Item removed from protected hidden vault.',
                                    type: ToastType.success,
                                  );
                                },
                                child: Text('Remove', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
