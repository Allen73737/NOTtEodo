import 'dart:math';
import 'package:flutter/material.dart';

/// Physical Deckled Edge Paper Tear on Note Archive/Deletion
/// Renders an authentic procedural fibrous paper tear with jagged
/// deckle edges and an angular curl-away drop shadow.
class DeckledPaperTear extends StatefulWidget {
  final Widget child;
  final bool isTorn;
  final VoidCallback? onTearComplete;
  final Duration duration;

  const DeckledPaperTear({
    super.key,
    required this.child,
    this.isTorn = false,
    this.onTearComplete,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<DeckledPaperTear> createState() => _DeckledPaperTearState();
}

class _DeckledPaperTearState extends State<DeckledPaperTear>
    with SingleTickerProviderStateMixin {
  late AnimationController _tearController;
  late Animation<double> _tearProgress;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _tearController = AnimationController(vsync: this, duration: widget.duration);
    _tearProgress = CurvedAnimation(
      parent: _tearController,
      curve: Curves.easeInCubic,
    );
    _rotationAnim = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(parent: _tearController, curve: Curves.easeInCubic),
    );

    _tearController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTearComplete?.call();
      }
    });

    if (widget.isTorn) {
      _tearController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant DeckledPaperTear oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTorn && widget.isTorn) {
      _tearController.forward();
    }
  }

  @override
  void dispose() {
    _tearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tearController,
      builder: (context, child) {
        if (_tearController.value == 0.0) {
          return widget.child;
        }

        final t = _tearProgress.value;
        final dyOffset = t * 140.0;
        final dxOffset = t * 40.0;

        return Stack(
          children: [
            // Lower torn piece staying or fading
            Opacity(
              opacity: (1.0 - t * 1.5).clamp(0.0, 1.0),
              child: ClipPath(
                clipper: _DeckledEdgeClipper(isTopHalf: false, tearProgress: t),
                child: widget.child,
              ),
            ),

            // Top torn piece peeling and curling away
            Transform.translate(
              offset: Offset(dxOffset, -dyOffset),
              child: Transform.rotate(
                angle: -_rotationAnim.value,
                origin: const Offset(0, 50),
                child: Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25 * (1.0 - t)),
                          blurRadius: 18 * (1.0 + t),
                          offset: Offset(t * 12, t * 24),
                        ),
                      ],
                    ),
                    child: ClipPath(
                      clipper: _DeckledEdgeClipper(isTopHalf: true, tearProgress: t),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeckledEdgeClipper extends CustomClipper<Path> {
  final bool isTopHalf;
  final double tearProgress;

  _DeckledEdgeClipper({required this.isTopHalf, required this.tearProgress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final splitY = size.height * 0.48;

    if (isTopHalf) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, splitY);

      // Jagged deckle tear edge from right to left
      const steps = 24;
      final stepW = size.width / steps;
      final rnd = Random(42);

      for (int i = steps; i >= 0; i--) {
        final x = i * stepW;
        final jitter = (rnd.nextDouble() - 0.5) * 8.0;
        path.lineTo(x, splitY + jitter);
      }
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(0, splitY);
      const steps = 24;
      final stepW = size.width / steps;
      final rnd = Random(42);

      for (int i = 0; i <= steps; i++) {
        final x = i * stepW;
        final jitter = (rnd.nextDouble() - 0.5) * 8.0;
        path.lineTo(x, splitY + jitter);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(covariant _DeckledEdgeClipper oldClipper) {
    return oldClipper.tearProgress != tearProgress ||
        oldClipper.isTopHalf != isTopHalf;
  }
}
