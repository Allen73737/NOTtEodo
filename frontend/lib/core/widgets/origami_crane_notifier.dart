import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class OrigamiCraneNotifier extends StatefulWidget {
  final String message;

  const OrigamiCraneNotifier({super.key, required this.message});

  @override
  State<OrigamiCraneNotifier> createState() => _OrigamiCraneNotifierState();
}

class _OrigamiCraneNotifierState extends State<OrigamiCraneNotifier> with SingleTickerProviderStateMixin {
  late AnimationController _craneController;

  @override
  void initState() {
    super.initState();
    _craneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _craneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _craneController,
      builder: (context, _) {
        final flap = math.sin(_craneController.value * math.pi * 4) * 0.15;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: flap,
                child: const Icon(Icons.send_rounded, size: 16, color: AppColors.secondary),
              ),
              const SizedBox(width: 8),
              Text(
                widget.message,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ],
          ),
        );
      },
    );
  }
}
