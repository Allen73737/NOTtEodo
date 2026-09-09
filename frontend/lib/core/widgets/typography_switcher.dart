import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import 'fluid_ui_effects.dart';

enum AppTypographyStyle { bodoniSerif, spaceGroteskSans }

class TypographySwitcher extends StatefulWidget {
  final ValueChanged<AppTypographyStyle> onChanged;

  const TypographySwitcher({super.key, required this.onChanged});

  @override
  State<TypographySwitcher> createState() => _TypographySwitcherState();
}

class _TypographySwitcherState extends State<TypographySwitcher> {
  AppTypographyStyle _activeStyle = AppTypographyStyle.bodoniSerif;

  void _toggleStyle() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeStyle = _activeStyle == AppTypographyStyle.bodoniSerif
          ? AppTypographyStyle.spaceGroteskSans
          : AppTypographyStyle.bodoniSerif;
    });
    widget.onChanged(_activeStyle);
  }

  @override
  Widget build(BuildContext context) {
    return BouncyTouchEffect(
      pressedScale: 0.92,
      onTap: _toggleStyle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _activeStyle == AppTypographyStyle.bodoniSerif
                  ? Icons.font_download
                  : Icons.text_fields,
              size: 14,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              _activeStyle == AppTypographyStyle.bodoniSerif ? 'Serif' : 'Sans',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
