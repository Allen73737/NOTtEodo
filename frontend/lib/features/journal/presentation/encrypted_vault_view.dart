import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';

class EncryptedVaultView extends StatefulWidget {
  final VoidCallback onClose;

  const EncryptedVaultView({super.key, required this.onClose});

  @override
  State<EncryptedVaultView> createState() => _EncryptedVaultViewState();
}

class _EncryptedVaultViewState extends State<EncryptedVaultView> {
  String _enteredPin = '';
  bool _isUnlocked = false;

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
      });
      if (_enteredPin == '1234' || _enteredPin.length == 4) {
        setState(() {
          _isUnlocked = true;
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isUnlocked ? _buildUnlockedVault(primaryTextColor, subtextColor) : _buildPinKeypad(primaryTextColor, subtextColor),
        ),
      ),
    );
  }

  Widget _buildPinKeypad(Color primaryTextColor, Color subtextColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BIOMETRIC ENCRYPTED VAULT', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.secondary)),
            IconButton(icon: Icon(LucideIcons.x, color: primaryTextColor), onPressed: widget.onClose),
          ],
        ),
        const SizedBox(height: 32),
        const Icon(LucideIcons.lock, size: 48, color: AppColors.secondary),
        const SizedBox(height: 16),
        Text('Enter Vault Passcode', style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor)),
        Text('Default Passcode: 1234 or Touch ID', style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
        const SizedBox(height: 32),

        // PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isFilled = i < _enteredPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.secondary : Colors.transparent,
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
            );
          }),
        ),
        const SizedBox(height: 48),

        // Keypad Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 24,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, idx) {
            if (idx == 9) {
              return TextButton.icon(
                onPressed: () => setState(() => _isUnlocked = true),
                icon: const Icon(LucideIcons.fingerprint, color: AppColors.secondary, size: 24),
                label: const Text(''),
              );
            }
            if (idx == 10) return _keypadBtn('0', primaryTextColor);
            if (idx == 11) {
              return IconButton(
                icon: Icon(LucideIcons.delete, color: primaryTextColor),
                onPressed: _onBackspace,
              );
            }
            return _keypadBtn('${idx + 1}', primaryTextColor);
          },
        ),
      ],
    );
  }

  Widget _keypadBtn(String val, Color primaryTextColor) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(30),
      child: Center(
        child: Text(val, style: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
      ),
    );
  }

  Widget _buildUnlockedVault(Color primaryTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENCRYPTED AES-256 VAULT', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.secondary)),
                Text('Private Reflections & Notes', style: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
              ],
            ),
            IconButton(icon: const Icon(LucideIcons.lock, color: AppColors.secondary), onPressed: widget.onClose),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView(
            children: [
              _vaultItem('🔐 Secret Journal Entry #4', 'Self-Destructing in 7 days · Created Aug 24', primaryTextColor, subtextColor),
              const SizedBox(height: 12),
              _vaultItem('🔑 Encrypted Seed & Keyphrase Backup', 'AES-256 Protected Vault Storage', primaryTextColor, subtextColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vaultItem(String title, String desc, Color primaryTextColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
        ],
      ),
    );
  }
}
