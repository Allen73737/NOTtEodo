import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class ZipperUnzipReveal extends StatefulWidget {
  final Widget child;

  const ZipperUnzipReveal({super.key, required this.child});

  @override
  State<ZipperUnzipReveal> createState() => _ZipperUnzipRevealState();
}

class _ZipperUnzipRevealState extends State<ZipperUnzipReveal> {
  double _unzipProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _unzipProgress = (_unzipProgress + details.delta.dy / 200).clamp(0.0, 1.0);
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_unzipProgress < 0.95)
            Positioned.fill(
              child: Container(
                color: AppColors.primary.withValues(alpha: 1.0 - _unzipProgress),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.lock, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Drag down to unzip reveal',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
