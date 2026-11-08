import 'package:flutter/material.dart';

class VellumPaperOverlayViewer extends StatefulWidget {
  final Widget baseContent;
  final Widget overlayContent;

  const VellumPaperOverlayViewer({
    super.key,
    required this.baseContent,
    required this.overlayContent,
  });

  @override
  State<VellumPaperOverlayViewer> createState() => _VellumPaperOverlayViewerState();
}

class _VellumPaperOverlayViewerState extends State<VellumPaperOverlayViewer> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.baseContent,
        if (_showOverlay)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFEF9EE).withValues(alpha: 0.92),
              child: widget.overlayContent,
            ),
          ),
        Positioned(
          bottom: 12,
          right: 12,
          child: FloatingActionButton.small(
            backgroundColor: const Color(0xFF1C1917),
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
            child: Icon(
              _showOverlay ? Icons.layers_clear : Icons.layers,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
