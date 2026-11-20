import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'rewards_ledger.dart';

/// A picture of a big moment (a high-tier badge, a long streak, a new level) to share.
/// It shows only the badge, its title and line and the app's name: nothing from the
/// person's notes, tasks or account.
abstract final class MilestoneShare {
  static bool worthSharing(BadgeDef b) => b.tier >= 2 || b.id.startsWith('level_') || b.id == 'repair';

  static Future<void> share(BadgeDef b, {Rect? origin}) async {
    final png = await render(b);
    if (png == null) return;
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: 'notteodo-${b.id}.png')],
      fileNameOverrides: ['notteodo-${b.id}.png'],
      text: '${b.title} on NOTtEodo.',
      sharePositionOrigin: origin,
    ));
  }

  static const _size = Size(1080, 1350);
  static const _paper = Color(0xFF120E0E);
  static const _accent = Color(0xFFD0485A);
  static const _deep = Color(0xFF8E2433);
  static const _linen = Color(0xFFF6F3ED);
  static const _muted = Color(0xFFA6A096);

  /// Draws the card as a PNG.
  static Future<Uint8List?> render(BadgeDef b) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & _size);
    final w = _size.width, h = _size.height;
    canvas.drawRect(Offset.zero & _size, Paint()..color = _paper);

    // Medal: a ring, a finer inner ring and the badge's icon, with tick marks for its tier.
    final c = Offset(w / 2, h * 0.36);
    canvas.drawCircle(c, 230, Paint()..color = _deep.withValues(alpha: 0.18));
    canvas.drawCircle(c, 200, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = _accent);
    canvas.drawCircle(c, 172, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _accent.withValues(alpha: 0.5));
    const ticks = 36;
    for (var i = 0; i < ticks; i++) {
      final a = i * 2 * math.pi / ticks;
      final from = c + Offset(math.cos(a), math.sin(a)) * 222;
      final to = c + Offset(math.cos(a), math.sin(a)) * (i % 3 == 0 ? 244 : 234);
      canvas.drawLine(from, to, Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = _accent.withValues(alpha: 0.35));
    }
    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(b.icon.codePoint),
        style: TextStyle(fontSize: 190, fontFamily: b.icon.fontFamily, package: b.icon.fontPackage, color: _linen),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    icon.paint(canvas, c - Offset(icon.width / 2, icon.height / 2));

    double y = h * 0.36 + 300;
    void line(String text, TextStyle style, {double gap = 24}) {
      final p = TextPainter(text: TextSpan(text: text, style: style), textAlign: TextAlign.center, textDirection: TextDirection.ltr)
        ..layout(maxWidth: w - 160);
      p.paint(canvas, Offset((w - p.width) / 2, y));
      y += p.height + gap;
    }

    final kicker = b.id.startsWith('level_')
        ? 'LEVEL UP'
        : b.id == 'repair'
            ? 'STREAK RESTORED'
            : 'BADGE EARNED';
    line(kicker, GoogleFonts.dmSans(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 6, color: _accent));
    line(b.title, GoogleFonts.dmSans(fontSize: 82, fontWeight: FontWeight.w800, height: 1.05, color: _linen), gap: 28);
    line(b.line, GoogleFonts.dmSans(fontSize: 38, height: 1.35, color: _muted));

    final foot = TextPainter(
      text: TextSpan(
        text: 'NOTtEodo',
        style: GoogleFonts.dmSans(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 1, color: _linen),
        children: [TextSpan(text: '   Notes · Tasks · Life', style: GoogleFonts.dmSans(fontSize: 30, fontWeight: FontWeight.w500, color: _muted))],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawLine(Offset(80, h - 150), Offset(w - 80, h - 150), Paint()
      ..strokeWidth = 2
      ..color = _muted.withValues(alpha: 0.3));
    foot.paint(canvas, Offset((w - foot.width) / 2, h - 110));

    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}
