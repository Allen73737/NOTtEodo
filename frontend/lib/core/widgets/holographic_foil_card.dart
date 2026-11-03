import 'package:flutter/material.dart';

class HolographicFoilCard extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const HolographicFoilCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  State<HolographicFoilCard> createState() => _HolographicFoilCardState();
}

class _HolographicFoilCardState extends State<HolographicFoilCard> with SingleTickerProviderStateMixin {
  late AnimationController _foilController;

  @override
  void initState() {
    super.initState();
    _foilController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _foilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _foilController,
      builder: (context, _) {
        final align = _foilController.value * 2.0 - 1.0;

        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
