import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmbossedGoldFoilStamper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onStamped;

  const EmbossedGoldFoilStamper({
    super.key,
    required this.child,
    this.onStamped,
  });

  @override
  State<EmbossedGoldFoilStamper> createState() => _EmbossedGoldFoilStamperState();
}

class _EmbossedGoldFoilStamperState extends State<EmbossedGoldFoilStamper>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  bool _isStamped = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    HapticFeedback.heavyImpact();
    _pressController.forward(from: 0.0).then((_) {
      setState(() => _isStamped = !_isStamped);
      if (widget.onStamped != null) widget.onStamped!();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _handleLongPress,
      child: Stack(
        children: [
          widget.child,
          if (_isStamped)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAB368),
                  boxShadow: [
                    BoxShadow(color: Color(0x66FFD700), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                child: const Icon(Icons.star, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
