import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class MoodCloudBubble extends StatefulWidget {
  const MoodCloudBubble({super.key});

  @override
  State<MoodCloudBubble> createState() => _MoodCloudBubbleState();
}

class _MoodCloudBubbleState extends State<MoodCloudBubble> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -4 * _floatController.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud, size: 14, color: AppColors.secondary),
                SizedBox(width: 4),
                Text('Serene Mood', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
