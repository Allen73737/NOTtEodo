import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class MoonPhaseDialTracker extends StatelessWidget {
  const MoonPhaseDialTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brightness_3, size: 14, color: AppColors.secondary),
          SizedBox(width: 4),
          Text('Waxing Crescent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        ],
      ),
    );
  }
}
