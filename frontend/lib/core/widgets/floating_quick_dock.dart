import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import 'fluid_ui_effects.dart';

class FloatingQuickDock extends StatelessWidget {
  final Function(String) onQuickAction;

  const FloatingQuickDock({super.key, required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF4F1EA) : AppColors.primary;

    return Positioned(
      bottom: 100,
      left: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface.withValues(alpha: 0.9) : AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.white.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                _dockBtn(context, LucideIcons.fileText, 'Note', primaryTextColor),
                const SizedBox(width: 8),
                _dockBtn(context, LucideIcons.mic, 'Memoir', primaryTextColor),
                const SizedBox(width: 8),
                _dockBtn(context, LucideIcons.layoutGrid, 'Pin', primaryTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dockBtn(BuildContext context, IconData icon, String label, Color primaryTextColor) {
    return BouncyTouchEffect(
      pressedScale: 0.90,
      onTap: () => onQuickAction(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor)),
          ],
        ),
      ),
    );
  }
}
