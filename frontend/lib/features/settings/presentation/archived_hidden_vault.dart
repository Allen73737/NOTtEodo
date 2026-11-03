import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/motion/motion.dart';

class ArchivedHiddenVault extends StatefulWidget {
  final VoidCallback onClose;

  const ArchivedHiddenVault({super.key, required this.onClose});

  @override
  State<ArchivedHiddenVault> createState() => _ArchivedHiddenVaultState();
}

class _ArchivedHiddenVaultState extends State<ArchivedHiddenVault> {
  bool _unlocked = false;
  String _pin = '';

  final List<Map<String, String>> _archivedItems = [];

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() => _pin += val);
      if (_pin == '1234' || _pin.length == 4) {
        setState(() => _unlocked = true);
      }
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
        child: _unlocked
            ? _buildVaultContent(primaryTextColor, subtextColor)
            : _buildPinGuard(primaryTextColor, subtextColor),
      ),
    );
  }

  Widget _buildPinGuard(Color primaryTextColor, Color subtextColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('PROTECTED ARCHIVE & HIDDEN VAULT', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.secondary)),
              ),
              IconButton(icon: Icon(LucideIcons.x, color: primaryTextColor), onPressed: widget.onClose),
            ],
          ),
          const SizedBox(height: 24),
          const Icon(LucideIcons.archive, size: 44, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text('Vault Passcode Required', style: GoogleFonts.bodoniModa(fontSize: 26, fontWeight: FontWeight.bold, color: primaryTextColor)),
          Text('Enter 4-digit PIN (default: 1234) or Touch ID to view hidden items', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor)),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.secondary : Colors.transparent,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 20,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, idx) {
              if (idx == 9) {
                return BouncyTouchEffect(
                  pressedScale: 0.90,
                  onTap: () => setState(() => _unlocked = true),
                  child: const Center(
                    child: Icon(LucideIcons.fingerprint, color: AppColors.secondary, size: 28),
                  ),
                );
              }
              if (idx == 10) return Reveal(style: RevealStyle.pop, distance: 18, child: _numBtn('0', primaryTextColor));
              if (idx == 11) {
                return BouncyTouchEffect(
                  pressedScale: 0.90,
                  onTap: () {
                    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  },
                  child: Center(
                    child: Icon(LucideIcons.delete, color: primaryTextColor, size: 22),
                  ),
                );
              }
              return Reveal(style: RevealStyle.pop, distance: 18, child: _numBtn('${idx + 1}', primaryTextColor));
            },
          ),
        ],
      ),
    );
  }

  Widget _numBtn(String n, Color color) {
    return BouncyTouchEffect(
      pressedScale: 0.90,
      onTap: () => _onKeyPress(n),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(n, style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }

  Widget _buildVaultContent(Color primaryTextColor, Color subtextColor) {
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
                  Text('ARCHIVED & HIDDEN VAULT', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.secondary)),
                  Text('3 Hidden Items Encrypted', style: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
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
              return Reveal(style: RevealStyle.slideIn, distance: 18, child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoPod(
                  style: PodTextureStyle.paper,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']!, style: GoogleFonts.bodoniModa(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor)),
                          Text('${item['type']} Â· ${item['date']}', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                        ],
                      ),
                      Pressable(pressedScale: 0.95, hoverLift: 0, child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.secondary)),
                        onPressed: () {
                          setState(() => _archivedItems.removeAt(idx));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('âœ¨ Item un-archived and restored to active sanctuary!')),
                          );
                        },
                        child: Text('Unhide', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      )),
                    ],
                  ),
                ),
              ));
            },
          ),
        ],
      ),
    );
  }
}
