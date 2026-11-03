import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class BrassPadlockUnlocking extends StatefulWidget {
  final Widget child;
  final VoidCallback onUnlocked;

  const BrassPadlockUnlocking({
    super.key,
    required this.child,
    required this.onUnlocked,
  });

  @override
  State<BrassPadlockUnlocking> createState() => _BrassPadlockUnlockingState();
}

class _BrassPadlockUnlockingState extends State<BrassPadlockUnlocking> {
  bool _isUnlocked = false;

  void _unlock() {
    HapticFeedback.heavyImpact();
    setState(() => _isUnlocked = true);
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) return widget.child;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 48,
            icon: const Icon(LucideIcons.lock, color: AppColors.secondary),
            onPressed: _unlock,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap brass lock to open vault',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
