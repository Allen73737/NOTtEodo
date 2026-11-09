import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';
import '../services/ai_workflow_evolution_service.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Opens the Workflow Evolution Dialog to scan notes and extract actionable tasks & expenses.
Future<void> showWorkflowEvolutionDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Workflow Evolution',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => WorkflowEvolutionDialog(title: title, content: content),
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

class WorkflowEvolutionDialog extends ConsumerStatefulWidget {
  final String title;
  final String content;

  const WorkflowEvolutionDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  ConsumerState<WorkflowEvolutionDialog> createState() => _WorkflowEvolutionDialogState();
}

class _WorkflowEvolutionDialogState extends ConsumerState<WorkflowEvolutionDialog> {
  bool _isLoading = true;
  ExtractedWorkflowBundle? _bundle;
  bool _isInstantiated = false;

  @override
  void initState() {
    super.initState();
    _extract();
  }

  Future<void> _extract() async {
    setState(() => _isLoading = true);
    final bundle = await AiWorkflowEvolutionService().extractWorkflowsFromNote(widget.content);
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _isLoading = false;
    });
  }

  void _instantiate() {
    if (_bundle == null || _bundle!.isEmpty || _isInstantiated) return;
    HapticFeedback.heavyImpact();
    final count = AiWorkflowEvolutionService().instantiateAll(
      context,
      ref,
      _bundle!,
      widget.title.isNotEmpty ? widget.title : 'Untitled Note',
    );
    if (count > 0) {
      setState(() => _isInstantiated = true);
    }
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
    const green = Color(0xFF22C55E);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: edBox(
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
                        decoration: edBox(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.sparkles, size: 18, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTE-TO-WORKFLOW EVOLUTION',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: accent,
                              ),
                            ),
                            Text(
                              widget.title.isNotEmpty ? widget.title : 'Untitled Thought',
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

                // Content
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
                                'Synthesizing actionable tasks and expenses...',
                                style: GoogleFonts.dmSans(fontSize: 13, color: textSub),
                              ),
                            ],
                          ),
                        )
                      : (_bundle == null || _bundle!.isEmpty)
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.sparkles, size: 36, color: textSub),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No actionable commitments detected',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'This note appears to be reflective or conceptual. Try adding specific to-dos or disbursement amounts.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(fontSize: 12, color: textSub),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Summary Banner
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: edBox(
                                      color: accent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.brain, size: 16, color: accent),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _bundle!.summary,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Tasks Section
                                  if (_bundle!.tasks.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(LucideIcons.checkSquare, size: 14, color: accent),
                                        const SizedBox(width: 8),
                                        Text(
                                          'EXTRACTED TASKS (${_bundle!.tasks.length})',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: textSub,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ..._bundle!.tasks.map((t) => Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: edBox(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: border),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(LucideIcons.circle, size: 12, color: accent),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  t.title,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (t.dueAt != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  margin: const EdgeInsets.only(left: 6),
                                                  decoration: edBox(
                                                    color: accent.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${t.dueAt!.day}/${t.dueAt!.month}',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: accent,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )),
                                    const SizedBox(height: 16),
                                  ],

                                  // Expenses Section
                                  if (_bundle!.expenses.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.receipt, size: 14, color: green),
                                        const SizedBox(width: 8),
                                        Text(
                                          'FINANCIAL COMMITMENTS (${_bundle!.expenses.length})',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: textSub,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ..._bundle!.expenses.map((e) => Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: edBox(
                                            color: cardBg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: border),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.dollarSign, size: 13, color: green),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  e.title,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: edBox(
                                                  color: green.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  e.amount.toStringAsFixed(e.amount.truncateToDouble() == e.amount ? 0 : 2),
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: green,
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

                // Footer Buttons
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
                      if (_bundle != null && !_bundle!.isEmpty)
                        Pressable(
                          pressedScale: 0.95,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isInstantiated ? green : accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isInstantiated ? null : _instantiate,
                            icon: Icon(_isInstantiated ? LucideIcons.checkCheck : LucideIcons.arrowUpRight, size: 14),
                            label: Text(
                              _isInstantiated ? 'Instantiated into System' : 'Instantiate All (${_bundle!.totalItems})',
                              style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.bold),
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
