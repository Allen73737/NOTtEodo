import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LeatherStitchBookmarkDrawer extends StatefulWidget {
  final Widget child;
  final String label;
  final Widget drawerContent;

  const LeatherStitchBookmarkDrawer({
    super.key,
    required this.child,
    this.label = 'TAGS',
    required this.drawerContent,
  });

  @override
  State<LeatherStitchBookmarkDrawer> createState() => _LeatherStitchBookmarkDrawerState();
}

class _LeatherStitchBookmarkDrawerState extends State<LeatherStitchBookmarkDrawer> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: -12,
          top: 24,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isOpen = !_isOpen);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC88552),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (_isOpen)
          Positioned(
            top: 60,
            right: 0,
            width: 220,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF1A1A1A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.drawerContent,
              ),
            ),
          ),
      ],
    );
  }
}
