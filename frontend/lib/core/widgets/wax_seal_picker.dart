import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

enum WaxSealType { monogramN, botanicalFern, celestialMoon, geometricDiamond }

class WaxSealWidget extends StatelessWidget {
  final WaxSealType type;
  final double size;

  const WaxSealWidget({
    super.key,
    this.type = WaxSealType.monogramN,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: edBox(
        shape: BoxShape.circle,
        color: AppColors.secondary,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: _buildSealIcon(),
      ),
    );
  }

  Widget _buildSealIcon() {
    switch (type) {
      case WaxSealType.monogramN:
        return Text('N', style: GoogleFonts.bodoniModa(fontSize: size * 0.5, fontWeight: FontWeight.bold, color: Colors.white));
      case WaxSealType.botanicalFern:
        return Icon(LucideIcons.leaf, size: size * 0.5, color: Colors.white);
      case WaxSealType.celestialMoon:
        return Icon(LucideIcons.moon, size: size * 0.45, color: Colors.white);
      case WaxSealType.geometricDiamond:
        return Icon(LucideIcons.gem, size: size * 0.45, color: Colors.white);
    }
  }
}

class WaxSealPickerModal extends StatelessWidget {
  final WaxSealType activeType;
  final ValueChanged<WaxSealType> onSelect;

  const WaxSealPickerModal({
    super.key,
    required this.activeType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: edBox(
        color: isDark ? const Color(0xFF000000) : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark ? const Border(top: BorderSide(color: Color(0xFF1E1E1E))) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SELECT WAX SEAL STAMP EMBLEM', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.secondary)),
          const SizedBox(height: 6),
          Text('Tactile Stamp Emblem Collection', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sealOpt(context, WaxSealType.monogramN, 'Monogram N'),
              _sealOpt(context, WaxSealType.botanicalFern, 'Botanical Fern'),
              _sealOpt(context, WaxSealType.celestialMoon, 'Celestial Moon'),
              _sealOpt(context, WaxSealType.geometricDiamond, 'Diamond'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sealOpt(BuildContext context, WaxSealType seal, String name) {
    final isSelected = activeType == seal;
    return GestureDetector(
      onTap: () {
        onSelect(seal);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: edBox(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppColors.secondary : Colors.transparent, width: 2),
            ),
            child: WaxSealWidget(type: seal, size: 40),
          ),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
