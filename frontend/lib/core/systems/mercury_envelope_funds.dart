import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Smart Micro-Budget Envelope Sinking Funds
/// Displays sinking fund budget envelopes using sloshing liquid mercury wave physics
/// with fill levels that deplete as expenses are logged.
class BudgetEnvelope {
  final String id;
  final String name;
  final double allocatedAmount;
  final double spentAmount;

  BudgetEnvelope({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.spentAmount,
  });

  double get fillRatio =>
      allocatedAmount > 0 ? ((allocatedAmount - spentAmount) / allocatedAmount).clamp(0.0, 1.0) : 0.0;
}

class MercuryEnvelopeFundsWidget extends StatefulWidget {
  final BudgetEnvelope envelope;

  const MercuryEnvelopeFundsWidget({super.key, required this.envelope});

  @override
  State<MercuryEnvelopeFundsWidget> createState() => _MercuryEnvelopeFundsWidgetState();
}

class _MercuryEnvelopeFundsWidgetState extends State<MercuryEnvelopeFundsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = widget.envelope.fillRatio;

    return Container(
      width: 140,
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C30) : const Color(0xFFE4DDD2),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.envelope.name.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _MercuryWavePainter(
                      fillRatio: fill,
                      wavePhase: _waveController.value * 2 * pi,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${(widget.envelope.allocatedAmount - widget.envelope.spentAmount).toStringAsFixed(0)} REMAINING',
            style: GoogleFonts.courierPrime(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEAB368),
            ),
          ),
        ],
      ),
    );
  }
}

class _MercuryWavePainter extends CustomPainter {
  final double fillRatio;
  final double wavePhase;

  _MercuryWavePainter({required this.fillRatio, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Flask
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // 2. Mercury Liquid Wave Fill
    final waterY = size.height * (1.0 - fillRatio);
    final wavePath = Path()..moveTo(0, size.height);
    wavePath.lineTo(0, waterY);

    for (double x = 0; x <= size.width; x += 4) {
      final y = waterY + sin((x / 18) + wavePhase) * 3.5;
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final mercuryShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE2E6EE),
        Color(0xFFA8B0BE),
        Color(0xFF5A626A),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(wavePath, Paint()..shader = mercuryShader);
  }

  @override
  bool shouldRepaint(covariant _MercuryWavePainter oldDelegate) =>
      oldDelegate.fillRatio != fillRatio || oldDelegate.wavePhase != wavePhase;
}
