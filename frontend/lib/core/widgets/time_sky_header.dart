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

  LinearGradient _getSkyGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }

    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return const LinearGradient(
        colors: [Color(0xFFFFF7EA), Color(0xFFFEF9EE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (hour >= 11 && hour < 17) {
      return const LinearGradient(
        colors: [Color(0xFFFEF9EE), Color(0xFFFFFBF2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (hour >= 17 && hour < 21) {
      return const LinearGradient(
        colors: [Color(0xFFFDECE7), Color(0xFFFEF9EE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFF3EFE6), Color(0xFFFEF9EE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: _getSkyGradient(isDark),
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
