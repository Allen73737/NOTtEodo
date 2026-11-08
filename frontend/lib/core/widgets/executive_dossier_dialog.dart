import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';
import '../services/ai_dossier_service.dart';
import '../state/sanctuary_state.dart';
import 'app_toast_engine.dart';

/// Opens the Weekly Executive Sanctuary Dossier Dialog.
Future<void> showExecutiveDossierDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Weekly Summary',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => const ExecutiveDossierDialog(),
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

class ExecutiveDossierDialog extends ConsumerStatefulWidget {
  const ExecutiveDossierDialog({super.key});

  @override
  ConsumerState<ExecutiveDossierDialog> createState() => _ExecutiveDossierDialogState();
}

class _ExecutiveDossierDialogState extends ConsumerState<ExecutiveDossierDialog> {
  bool _isLoading = true;
  ExecutiveDossier? _dossier;

  @override
  void initState() {
    super.initState();
    _loadDossier();
  }

  Future<void> _loadDossier({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final tasks = ref.read(tasksProvider);
    final expensesState = ref.read(expensesProvider);
    final notes = ref.read(notesProvider);
    final habits = ref.read(habitsProvider);

    final res = await AiDossierService().generateWeeklyDossier(
      tasks: tasks,
      expenses: expensesState.expenses,
      notes: notes,
      habits: habits,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;
    setState(() {
      _dossier = res;
      _isLoading = false;
    });
  }

  void _copyDossier() {
    if (_dossier == null) return;
    final d = _dossier!;
    final buf = StringBuffer();
    buf.writeln('WEEKLY SUMMARY: ${d.weekTitle}');
    buf.writeln('VELOCITY SCORE: ${d.velocityScore}\n');
    buf.writeln('EXECUTIVE SUMMARY:\n${d.executiveSummary}\n');
    buf.writeln('KEY HIGHLIGHTS:');
    for (final h in d.highlights) {
      buf.writeln('• $h');
    }
    buf.writeln('\nCAPITAL RUNWAY:\n${d.capitalReport}');
    buf.writeln('\nSTRATEGIC NEXT STEPS:');
    for (final s in d.strategicNextSteps) {
      buf.writeln('→ $s');
    }

    Clipboard.setData(ClipboardData(text: buf.toString()));
    HapticFeedback.lightImpact();
    AppToastEngine().showToast(
      context,
      title: 'Copied to Clipboard',
      message: 'Weekly summary copied to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101216) : Colors.white;
    final cardBg = isDark ? const Color(0xFF161920) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
    final textPrimary = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917);
    final textSub = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    const emerald = Color(0xFF10B981);

    final d = _dossier;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
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
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.fileSpreadsheet, size: 18, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WEEKLY SUMMARY & PROGRESS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: accent,
                              ),
                            ),
                            Text(
                              d?.weekTitle ?? '7-Day Cross-Module Intelligence',
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
                        tooltip: 'Refresh Intelligence',
                        icon: _isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
                              )
                            : Icon(LucideIcons.refreshCw, size: 16, color: textSub),
                        onPressed: _isLoading ? null : () => _loadDossier(forceRefresh: true),
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
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Synthesizing 7-day velocity, capital runway, and strategic milestones...',
                                style: GoogleFonts.dmSans(fontSize: 13, color: textSub),
                              ),
                            ],
                          ),
                        )
                      : d == null
                          ? Center(
                              child: Text(
                                'Could not generate weekly summary.',
                                style: GoogleFonts.dmSans(fontSize: 13, color: textSub),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Velocity Score Banner
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: emerald.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: emerald.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.gauge, size: 18, color: emerald),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'EXECUTION VELOCITY SCORE',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                                color: emerald,
                                              ),
                                            ),
                                            Text(
                                              d.velocityScore,
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Executive Summary
                                  Text(
                                    'EXECUTIVE SUMMARY',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.3,
                                      color: textSub,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: Text(
                                      d.executiveSummary,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Highlights
                                  if (d.highlights.isNotEmpty) ...[
                                    Text(
                                      'KEY MILESTONES & COMPLETIONS',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.3,
                                        color: textSub,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...d.highlights.map((h) => Container(
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
                                                child: Icon(LucideIcons.checkCircle2, size: 13, color: emerald),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  h,
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
                                    const SizedBox(height: 16),
                                  ],

                                  // Capital & Runway
                                  Text(
                                    'CAPITAL DISBURSEMENT & RUNWAY',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11.5,
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
                                          child: Icon(LucideIcons.wallet, size: 14, color: emerald),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            d.capitalReport,
                                            style: GoogleFonts.dmSans(fontSize: 12.5, height: 1.4, color: textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Strategic Next Steps
                                  if (d.strategicNextSteps.isNotEmpty) ...[
                                    Text(
                                      'STRATEGIC NEXT STEPS',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.3,
                                        color: accent,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...d.strategicNextSteps.map((s) => Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                                child: Icon(LucideIcons.arrowRight, size: 13, color: accent),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  s,
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
                                        )),
                                  ],
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
                      if (d != null)
                        Pressable(
                          pressedScale: 0.95,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _copyDossier,
                            icon: const Icon(LucideIcons.copy, size: 14),
                            label: Text(
                              'Copy Weekly Summary',
                              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
