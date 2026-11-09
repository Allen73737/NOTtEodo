import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../services/groq_ai_service.dart';
import 'smart_classifier.dart';
import 'smart_grouping.dart';
import 'spending_insights.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

Color _accent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE8927C) : AppColors.secondary;

/// A small "✦ Suggested" chip. Tapping applies the suggestion.
class AiSuggestionChip extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onApply;

  /// Shown instead of the value, e.g. "Use Food & Dining".
  final String? label;

  /// True once the suggestion is what is selected; the chip then just confirms it.
  final bool applied;

  const AiSuggestionChip({super.key, required this.suggestion, required this.onApply, this.label, this.applied = false});

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Tooltip(
      message: suggestion.reason,
      child: Semantics(
        button: !applied,
        label: applied ? 'Suggested ${suggestion.value}, applied' : 'Apply suggestion ${suggestion.value}',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: applied ? null : onApply,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: edBox(
              color: accent.withValues(alpha: applied ? 0.08 : 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(applied ? LucideIcons.check : LucideIcons.sparkles, size: 12, color: accent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    applied ? 'AI picked ${suggestion.value}' : (label ?? 'Suggested: ${suggestion.value}'),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent),
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

/// Shows [items] in AI-made groups. Groups are computed on the device instantly; if
/// cloud AI is available, the group names are then refined by the model.
class SmartGroupsView<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) textOf;
  final Widget Function(T item) itemBuilder;

  /// e.g. "notes", "tasks" (used in the cloud naming prompt and empty text).
  final String kind;

  const SmartGroupsView({
    super.key,
    required this.items,
    required this.textOf,
    required this.itemBuilder,
    this.kind = 'items',
  });

  @override
  State<SmartGroupsView<T>> createState() => _SmartGroupsViewState<T>();
}

class _SmartGroupsViewState<T> extends State<SmartGroupsView<T>> {
  List<SmartGroup> _groups = const [];
  String _signature = '';
  bool _namedByCloud = false;
  final Set<int> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _regroup();
  }

  @override
  void didUpdateWidget(covariant SmartGroupsView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _regroup();
  }

  void _regroup() {
    final texts = [for (final i in widget.items) widget.textOf(i)];
    final sig = texts.join('\u0001');
    if (sig == _signature) return;
    _signature = sig;
    _groups = SmartGrouper.group(texts);
    _namedByCloud = false;
    _refineNames(sig, texts);
  }

  Future<void> _refineNames(String sig, List<String> texts) async {
    final named = _groups.where((g) => !g.isOther).toList();
    if (named.length < 2 || !GroqAiService().isConfigured) return;
    final names = await GroqAiService().nameGroups(
      [for (final g in named) [for (final i in g.members) texts[i]]],
      kind: widget.kind,
    );
    if (!mounted || names == null || sig != _signature) return;
    var k = 0;
    setState(() {
      _groups = [for (final g in _groups) g.isOther ? g : g.copyWith(label: names[k++])];
      _namedByCloud = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = _accent(context);
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No ${widget.kind} to group yet.', style: GoogleFonts.dmSans(color: sub)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, size: 13, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_groups.length} smart groups · '
                  '${_namedByCloud ? 'grouped on this device, named by AI' : 'grouped by meaning on this device'}',
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: sub),
                ),
              ),
            ],
          ),
        ),
        for (var g = 0; g < _groups.length; g++) ...[
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _collapsed.contains(g) ? _collapsed.remove(g) : _collapsed.add(g)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _collapsed.contains(g) ? -0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(LucideIcons.chevronDown, size: 16, color: sub),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _groups[g].label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: text),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: edBox(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_groups[g].members.length}',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _collapsed.contains(g)
                ? const SizedBox(width: double.infinity)
                : Column(children: [for (final i in _groups[g].members) widget.itemBuilder(widget.items[i])]),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

/// A compact stack of insight cards (good / info / warning).
class InsightsPanel extends StatelessWidget {
  final List<Insight> insights;
  final String title;

  const InsightsPanel({super.key, required this.insights, this.title = 'AI INSIGHTS'});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = _accent(context);
    Color tone(InsightTone t) => switch (t) {
          InsightTone.good => const Color(0xFF2E8B57),
          InsightTone.warning => const Color(0xFFD35400),
          InsightTone.info => accent,
        };
    IconData icon(InsightTone t) => switch (t) {
          InsightTone.good => LucideIcons.trendingDown,
          InsightTone.warning => LucideIcons.alertTriangle,
          InsightTone.info => LucideIcons.lightbulb,
        };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: edBox(
        color: isDark ? const Color(0xFF111110) : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF26221C) : const Color(0xFFE4DDCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 15, color: accent),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accent)),
            ],
          ),
          const SizedBox(height: 12),
          for (final i in insights.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: edBox(color: tone(i.tone).withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon(i.tone), size: 13, color: tone(i.tone)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
                        const SizedBox(height: 2),
                        Text(i.detail, style: GoogleFonts.dmSans(fontSize: 11.5, color: sub, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
