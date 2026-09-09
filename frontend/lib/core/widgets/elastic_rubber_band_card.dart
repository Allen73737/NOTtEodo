import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ElasticRubberBandCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismissed;

  const ElasticRubberBandCard({
    super.key,
    required this.child,
    this.onDismissed,
  });

  @override
  State<ElasticRubberBandCard> createState() => _ElasticRubberBandCardState();
}

class _ElasticRubberBandCardState extends State<ElasticRubberBandCard>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Elastic rubber band resistance multiplier (0.45)
      _offset += details.delta * 0.45;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_offset.distance > 180 && widget.onDismissed != null) {
      HapticFeedback.heavyImpact();
      widget.onDismissed!();
    } else {
      HapticFeedback.lightImpact();
      _springAnimation = Tween<Offset>(
        begin: _offset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
      );
      _springController.forward(from: 0.0).then((_) {
        setState(() {
          _offset = Offset.zero;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _springController,
        builder: (context, child) {
          final currentOffset = _springController.isAnimating ? _springAnimation.value : _offset;
          final stretchScaleX = 1.0 + (currentOffset.dx.abs() / 600.0);
          final stretchScaleY = 1.0 + (currentOffset.dy.abs() / 600.0);

          return Transform(
            transform: Matrix4.translationValues(currentOffset.dx, currentOffset.dy, 0.0)
              ..multiply(Matrix4.diagonal3Values(stretchScaleX, stretchScaleY, 1.0)),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
