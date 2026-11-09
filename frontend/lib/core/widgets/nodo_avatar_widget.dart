import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Emotions expressed by the Nodo AI companion.
enum NodoEmotion {
  neutral,
  thinking,
  sarcastic,
  celebrating,
}

/// An animated avatar widget combining the Notteodo "N" insignia
/// with expressive AI micro-animations (blinking, eye shifts, thinking pulses, smirks).
class NodoAvatarWidget extends StatefulWidget {
  final double size;
  final NodoEmotion emotion;
  final bool isInteractive;
  final VoidCallback? onTap;

  const NodoAvatarWidget({
    super.key,
    this.size = 40,
    this.emotion = NodoEmotion.neutral,
    this.isInteractive = false,
    this.onTap,
  });

  @override
  State<NodoAvatarWidget> createState() => _NodoAvatarWidgetState();
}

class _NodoAvatarWidgetState extends State<NodoAvatarWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _pulse;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );

    _float = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final bodyColor = isDark ? const Color(0xFF141414) : const Color(0xFFF7F5F0);
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDDD8CE);

    final avatar = AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: Transform.scale(
            scale: widget.emotion == NodoEmotion.thinking ? _pulse.value : 1.0,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: edBox(
          color: bodyColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.emotion == NodoEmotion.thinking ? accent : borderColor,
            width: widget.emotion == NodoEmotion.thinking ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.emotion == NodoEmotion.celebrating ? accent : Colors.black)
                  .withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: widget.size * 0.25,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _NodoFacePainter(
              emotion: widget.emotion,
              isDark: isDark,
              accentColor: accent,
              progress: _animCtrl.value,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap != null || widget.isInteractive) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatar,
      );
    }
    return avatar;
  }
}

class _NodoFacePainter extends CustomPainter {
  final NodoEmotion emotion;
  final bool isDark;
  final Color accentColor;
  final double progress;

  _NodoFacePainter({
    required this.emotion,
    required this.isDark,
    required this.accentColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eyeColor = isDark ? Colors.white : const Color(0xFF111111);

    // Subtle background N insignia watermark in the center
    final nPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = size.width * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final nPath = Path();
    final nW = size.width * 0.4;
    final nH = size.height * 0.4;
    final nL = center.dx - nW / 2;
    final nT = center.dy - nH / 2;

    nPath.moveTo(nL, nT + nH);
    nPath.lineTo(nL, nT);
    nPath.lineTo(nL + nW, nT + nH);
    nPath.lineTo(nL + nW, nT);
    canvas.drawPath(nPath, nPaint);

    // Eyes positioning
    final eyeSpacing = size.width * 0.26;
    final eyeY = center.dy - size.height * 0.06;
    final leftEyeCenter = Offset(center.dx - eyeSpacing / 2, eyeY);
    final rightEyeCenter = Offset(center.dx + eyeSpacing / 2, eyeY);

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Draw expressive eyes based on emotion
    switch (emotion) {
      case NodoEmotion.neutral:
        // Clean, intelligent glowing circular eyes with occasional micro-blink
        final isBlinking = progress > 0.92;
        if (isBlinking) {
          canvas.drawLine(
            Offset(leftEyeCenter.dx - 3, leftEyeCenter.dy),
            Offset(leftEyeCenter.dx + 3, leftEyeCenter.dy),
            eyePaint..strokeWidth = 2,
          );
          canvas.drawLine(
            Offset(rightEyeCenter.dx - 3, rightEyeCenter.dy),
            Offset(rightEyeCenter.dx + 3, rightEyeCenter.dy),
            eyePaint..strokeWidth = 2,
          );
        } else {
          canvas.drawCircle(leftEyeCenter, size.width * 0.065, eyePaint);
          canvas.drawCircle(rightEyeCenter, size.width * 0.065, eyePaint);
          // Tiny pupils
          canvas.drawCircle(
            Offset(leftEyeCenter.dx + 1, leftEyeCenter.dy - 1),
            size.width * 0.02,
            accentPaint,
          );
          canvas.drawCircle(
            Offset(rightEyeCenter.dx + 1, rightEyeCenter.dy - 1),
            size.width * 0.02,
            accentPaint,
          );
        }
        break;

      case NodoEmotion.thinking:
        // Swirling / focusing eyes with neural pulse
        final radius = size.width * 0.07;
        const sweepAngle = math.pi * 1.5;
        final startAngle = progress * math.pi * 2;
        final arcPaint = Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: leftEyeCenter, radius: radius),
          startAngle,
          sweepAngle,
          false,
          arcPaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: rightEyeCenter, radius: radius),
          -startAngle,
          sweepAngle,
          false,
          arcPaint,
        );
        break;

      case NodoEmotion.sarcastic:
        // Raised left eyebrow, half-closed right eye, sly sideways glance
        // Left eye: wide and raised
        canvas.drawCircle(Offset(leftEyeCenter.dx, leftEyeCenter.dy - 2), size.width * 0.07, eyePaint);
        // Left eyebrow angled up
        final browPaint = Paint()
          ..color = eyeColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(leftEyeCenter.dx - 5, leftEyeCenter.dy - size.height * 0.16),
          Offset(leftEyeCenter.dx + 6, leftEyeCenter.dy - size.height * 0.12),
          browPaint,
        );

        // Right eye: skeptical half-squint
        final squintPath = Path();
        squintPath.moveTo(rightEyeCenter.dx - 5, rightEyeCenter.dy);
        squintPath.quadraticBezierTo(
          rightEyeCenter.dx,
          rightEyeCenter.dy - 4,
          rightEyeCenter.dx + 5,
          rightEyeCenter.dy,
        );
        canvas.drawPath(squintPath, browPaint..strokeWidth = 2.4);

        // Smirking slight mouth curve
        final smirkPath = Path();
        final mouthY = center.dy + size.height * 0.18;
        smirkPath.moveTo(center.dx - 4, mouthY);
        smirkPath.quadraticBezierTo(
          center.dx + 3,
          mouthY + 1,
          center.dx + 7,
          mouthY - 3,
        );
        canvas.drawPath(smirkPath, browPaint..strokeWidth = 1.8..style = PaintingStyle.stroke);
        break;

      case NodoEmotion.celebrating:
        // Joyful arched crescent eyes with sparkles
        final joyPaint = Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;

        final leftArch = Path();
        leftArch.moveTo(leftEyeCenter.dx - 4, leftEyeCenter.dy + 2);
        leftArch.quadraticBezierTo(
          leftEyeCenter.dx,
          leftEyeCenter.dy - 5,
          leftEyeCenter.dx + 4,
          leftEyeCenter.dy + 2,
        );
        canvas.drawPath(leftArch, joyPaint);

        final rightArch = Path();
        rightArch.moveTo(rightEyeCenter.dx - 4, rightEyeCenter.dy + 2);
        rightArch.quadraticBezierTo(
          rightEyeCenter.dx,
          rightEyeCenter.dy - 5,
          rightEyeCenter.dx + 4,
          rightEyeCenter.dy + 2,
        );
        canvas.drawPath(rightArch, joyPaint);

        // Little happy smile
        final smilePath = Path();
        final mouthY = center.dy + size.height * 0.16;
        smilePath.moveTo(center.dx - 5, mouthY);
        smilePath.quadraticBezierTo(
          center.dx,
          mouthY + 4,
          center.dx + 5,
          mouthY,
        );
        canvas.drawPath(smilePath, joyPaint..strokeWidth = 1.8);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NodoFacePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.emotion != emotion ||
        oldDelegate.isDark != isDark;
  }
}
