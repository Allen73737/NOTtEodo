import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Translucent Parchment Watermark
/// Hand-pressed vellum paper card displaying an embossed heraldic Sanctuary crest
/// deep within paper fibers, visible under oblique light/tilt.
class ParchmentWatermarkView extends StatefulWidget {
  final Widget child;
  final String watermarkText;

  const ParchmentWatermarkView({
    super.key,
    required this.child,
    this.watermarkText = 'SANCTUARY VERITAS',
  });

  @override
  State<ParchmentWatermarkView> createState() => _ParchmentWatermarkViewState();
}

class _ParchmentWatermarkViewState extends State<ParchmentWatermarkView> {
  Offset _pointerOffset = const Offset(0.5, 0.5);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final local = event.localPosition;
          setState(() {
            _pointerOffset = Offset(
              (local.dx / box.size.width).clamp(0.0, 1.0),
              (local.dy / box.size.height).clamp(0.0, 1.0),
            );
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? const Color(0xFF181614) : const Color(0xFFF7F4EB),
          border: Border.all(
            color: isDark ? const Color(0xFF38322A) : const Color(0xFFDDD5C1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Embedded watermark crest
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.14 + (_pointerOffset.dx * 0.12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF9A8446),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.watermarkText,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.0,
                          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF9A8446),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
