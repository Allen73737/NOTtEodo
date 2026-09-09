import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class PostcardMailStamper extends StatelessWidget {
  final Widget child;

  const PostcardMailStamper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.6), width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.markunread_mailbox, size: 16, color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}
