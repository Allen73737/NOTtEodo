import 'package:flutter/material.dart';

class ParchmentPageCurlViewer extends StatefulWidget {
  final Widget child;

  const ParchmentPageCurlViewer({super.key, required this.child});

  @override
  State<ParchmentPageCurlViewer> createState() => _ParchmentPageCurlViewerState();
}

class _ParchmentPageCurlViewerState extends State<ParchmentPageCurlViewer> with SingleTickerProviderStateMixin {
  late AnimationController _curlController;
  late Animation<double> _curlAnimation;

  @override
  void initState() {
    super.initState();
    _curlController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _curlAnimation = CurvedAnimation(
      parent: _curlController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _curlController.dispose();
    super.dispose();
  }

  void _triggerCurl() {
    _curlController.forward(from: 0.0).then((_) {
      _curlController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerCurl,
      child: AnimatedBuilder(
        animation: _curlAnimation,
        builder: (context, _) {
          final val = _curlAnimation.value;

          return Stack(
            children: [
              widget.child,
              if (val > 0.01)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 60 * val,
                    height: 60 * val,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EAE1),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2 * val),
                          blurRadius: 10,
                          offset: const Offset(-4, 4),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
