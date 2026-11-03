import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class TimeSkyHeader extends StatefulWidget {
  final Widget child;

  const TimeSkyHeader({super.key, required this.child});

  @override
  State<TimeSkyHeader> createState() => _TimeSkyHeaderState();
}

class _TimeSkyHeaderState extends State<TimeSkyHeader> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F2),
          ),
          child: widget.child,
        ),
        Positioned(
          top: 14,
          right: 80,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: _rotationController,
              child: Opacity(
                opacity: 0.18,
                child: Icon(
                  isDark ? LucideIcons.moon : LucideIcons.sun,
                  size: 32,
                  color: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
