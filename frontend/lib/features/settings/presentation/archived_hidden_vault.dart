import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/state/app_settings.dart';
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

  final List<Map<String, String>> _archivedItems = [
    {
      'title': 'Private Seed Phrase Backup',
      'type': 'Zero-Knowledge Key',
      'date': 'Oct 24, 2026',
    },
    {
      'title': 'Offshore Asset & Swiss Bank Memo',
      'type': 'Encrypted Note',
      'date': 'Nov 02, 2026',
    },
    {
      'title': 'Private Family Estate Trust',
      'type': 'Legal Document',
      'date': 'Nov 04, 2026',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(appSettingsProvider);
      if (settings.vaultPin != null &&
          settings.vaultPin!.isNotEmpty &&
          settings.vaultBiometricsEnabled) {
        _authenticateBiometrics();
      }
    });
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
                        fontSize: 10,
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
                        fontSize: 10,
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
                      fontSize: 10,
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
              IconButton(icon: Icon(LucideIcons.x, color: primaryTextColor), onPressed: widget.onClose),
            ],
          ),
          const SizedBox(height: 20),

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title']!, style: GoogleFonts.bodoniModa(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor)),
                              const SizedBox(height: 2),
                              Text('${item['type']} · ${item['date']}', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                            ],
                          ),
                        ),
                        Pressable(
                          pressedScale: 0.95,
                          hoverLift: 0,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor)),
                            onPressed: () {
                              SanctuaryHapticEngine.selection();
                              setState(() => _archivedItems.removeAt(idx));
                              AppToastEngine().notifyAnimated(
                                title: 'Item Restored',
                                message: '✨ Item un-archived and restored to active sanctuary!',
                                type: ToastType.success,
                              );
                            },
                            child: Text('Unhide', style: GoogleFonts.dmSans(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
