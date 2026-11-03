import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF000000) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            _dockBtn(context, LucideIcons.fileText, 'Note', primaryTextColor),
            const SizedBox(width: 8),
            _dockBtn(context, LucideIcons.mic, 'Journal', primaryTextColor),
            const SizedBox(width: 8),
            _dockBtn(context, LucideIcons.layoutGrid, 'Moodboard', primaryTextColor),
          ],
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
