import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';
import '../services/ai_pressure_test_service.dart';
import 'app_toast_engine.dart';

/// Opens the Pressure Test / Strategic Sparring Partner dialog.
Future<void> showPressureTestDialog(
  BuildContext context, {
  required String title,
  required String content,
  ValueChanged<String>? onAppendToNote,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Plan Review',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => PressureTestDialog(
      title: title,
      content: content,
      onAppendToNote: onAppendToNote,
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class PressureTestDialog extends StatefulWidget {
  final String title;
  final String content;
  final ValueChanged<String>? onAppendToNote;

  const PressureTestDialog({
    super.key,
    required this.title,
    required this.content,
    this.onAppendToNote,
  });

  @override
  State<PressureTestDialog> createState() => _PressureTestDialogState();
}

class _PressureTestDialogState extends State<PressureTestDialog> {
  bool _isLoading = true;
  PressureTestResult? _result;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() => _isLoading = true);
    final res = await AiPressureTestService().pressureTest(widget.title, widget.content);
    if (!mounted) return;
    setState(() {
      _result = res;
      _isLoading = false;
    });
  }

  void _copyDossier() {
    if (_result == null) return;
    final r = _result!;
    final buf = StringBuffer();
    buf.writeln('IDEA & PLAN REVIEW: ${r.ideaTitle}');
    buf.writeln('VERDICT: ${r.verdict}\n');
    buf.writeln('BLIND SPOTS:');
    for (final b in r.blindSpots) {
      buf.writeln('• $b');
    }
    buf.writeln('\nCAPITAL & BURN RISKS:\n${r.capitalRisks}');
    buf.writeln('\nRUTHLESS COUNTER-PERSPECTIVE:\n${r.counterPerspective}');
    buf.writeln('\nHARDENING RECOMMENDATION:\n${r.hardeningRecommendation}');

    Clipboard.setData(ClipboardData(text: buf.toString()));
    HapticFeedback.lightImpact();
    AppToastEngine().showToast(
      context,
      title: 'Copied to Clipboard',
      message: 'Plan review copied to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101216) : Colors.white;
    final cardBg = isDark ? const Color(0xFF161920) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
    final textPrimary = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF16282C);
    final textSub = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    const orange = Color(0xFFF59E0B);
    const red = Color(0xFFEF4444);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.shieldAlert, size: 18, color: orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEVIL\'S ADVOCATE · SPARRING PARTNER',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: orange,
                              ),
                            ),
                            Text(
                              widget.title.isNotEmpty ? widget.title : 'Strategic Hypothesis',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: textSub),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: border),

                // Body
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2, color: orange),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Ruthlessly pressure-testing assumptions & blind spots...',
                                style: GoogleFonts.dmSans(fontSize: 13, color: textSub),
                              ),
                            ],
                          ),
                        )
                      : _result == null
                          ? Center(
                              child: Text(
                                'Could not review plan.',
                                style: GoogleFonts.dmSans(fontSize: 13, color: textSub),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Verdict Banner
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: orange.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.zap, size: 16, color: orange),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _result!.verdict,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Critical Blind Spots
                                  if (_result!.blindSpots.isNotEmpty) ...[
                                    Text(
                                      'CRITICAL BLIND SPOTS',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.3,
                                        color: red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._result!.blindSpots.map((b) => Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: border),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(top: 2),
                                                child: Icon(LucideIcons.alertTriangle, size: 13, color: red),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  b,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12.5,
                                                    height: 1.4,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 14),
                                  ],

                                  // Capital & Runway Risks
                                  Text(
                                    'CAPITAL & TIME RISKS',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.3,
                                      color: textSub,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(LucideIcons.trendingDown, size: 14, color: orange),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _result!.capitalRisks,
                                            style: GoogleFonts.dmSans(fontSize: 12.5, height: 1.4, color: textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Counter-Perspective
                                  Text(
                                    'THE SKEPTIC\'S COUNTER-PERSPECTIVE',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.3,
                                      color: textSub,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(LucideIcons.quote, size: 14, color: accent),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _result!.counterPerspective,
                                            style: GoogleFonts.dmSans(fontSize: 12.5, height: 1.4, fontStyle: FontStyle.italic, color: textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Hardening Recommendation
                                  Text(
                                    'RECOMMENDED HARDENING ACTIONS',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.3,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(LucideIcons.shieldCheck, size: 14, color: accent),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _result!.hardeningRecommendation,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),

                // Footer
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: GoogleFonts.dmSans(fontSize: 13, color: textSub),
                        ),
                      ),
                      const Spacer(),
                      if (_result != null) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: border),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _copyDossier,
                          icon: const Icon(LucideIcons.copy, size: 13),
                          label: Text(
                            'Copy Sparring Report',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.onAppendToNote != null) ...[
                          const SizedBox(width: 10),
                          Pressable(
                            pressedScale: 0.95,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                final textToAppend = '\n\n⚡ **Plan Review Verdict**: ${_result!.verdict}\n\n💡 **Suggestions**: ${_result!.hardeningRecommendation}';
                                widget.onAppendToNote!(textToAppend);
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(LucideIcons.filePlus2, size: 14),
                              label: Text(
                                'Append to Note',
                                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
