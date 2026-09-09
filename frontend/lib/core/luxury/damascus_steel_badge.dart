import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Damascus Steel Shimmer Badge
/// Renders procedural folded-metal woodgrain Damascus patterns with
/// high-contrast carbon layering and moving specular light waves for offline vaults.
class DamascusSteelBadge extends StatefulWidget {
  final String text;
  final IconData icon;

  const DamascusSteelBadge({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline,
  });

  @override
  State<DamascusSteelBadge> createState() => _DamascusSteelBadgeState();
}

class _DamascusSteelBadgeState extends State<DamascusSteelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8A939E), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CustomPaint(
              painter: _DamascusWavePainter(wavePhase: _waveController.value * 2 * pi),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 13, color: const Color(0xFFE8EEF5)),
                  const SizedBox(width: 6),
                  Text(
                    widget.text,
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: const Color(0xFFF2F6FA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DamascusWavePainter extends CustomPainter {
  final double wavePhase;

  _DamascusWavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Carbon Core
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1F2328),
    );

    // 2. Folded Damascus Steel Veins
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF5E6572).withValues(alpha: 0.65);

    for (double y = -4; y < size.height + 6; y += 5) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 6) {
        final sinY = sin((x / 14) + wavePhase + (y / 8)) * 2.5;
        path.lineTo(x, y + sinY);
      }
      canvas.drawPath(path, veinPaint);
    }

    // 3. Specular Silver Sweep
    final specularShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.35),
        Colors.transparent,
      ],
      stops: [
        (sin(wavePhase) * 0.4 + 0.1).clamp(0.0, 0.4),
        (sin(wavePhase) * 0.4 + 0.5).clamp(0.4, 0.7),
        (sin(wavePhase) * 0.4 + 0.9).clamp(0.7, 1.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = specularShader);
  }

  @override
  bool shouldRepaint(covariant _DamascusWavePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase;
}
