import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/motion/motion.dart';
import '../../../core/state/bin_state.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/masonry.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Everything deleted across the app, held for 30 days on a Pinterest-style board.
/// Restore puts an item back exactly where it was; delete-forever and empty are confirmed.
class BinScreen extends ConsumerStatefulWidget {
  /// Opens the module a restored item belongs to.
  final ValueChanged<int> onOpenModule;

  const BinScreen({super.key, required this.onOpenModule});

  @override
  ConsumerState<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends ConsumerState<BinScreen> {
  BinKind? _filter;

  static IconData _iconFor(BinKind kind) => switch (kind) {
        BinKind.note => LucideIcons.fileText,
        BinKind.task => LucideIcons.checkSquare,
        BinKind.expense => LucideIcons.wallet,
        BinKind.shopping => LucideIcons.shoppingBag,
        BinKind.outfit => LucideIcons.shirt,
        BinKind.habit => LucideIcons.flame,
        BinKind.trip => LucideIcons.plane,
        BinKind.memoir => LucideIcons.bookOpen,
        BinKind.event => LucideIcons.calendar,
        BinKind.pin => LucideIcons.image,
      };

  /// Each kind wears its module's tone from the app palette.
  static Color _toneFor(BinKind kind, bool isDark) {
    final base = switch (kind) {
      BinKind.note => AppColors.themePlanner,
      BinKind.task => AppColors.themeTasks,
      BinKind.expense => AppColors.themeExpenses,
      BinKind.shopping => AppColors.themeSplitter,
      BinKind.outfit => AppColors.themeJournal,
      BinKind.habit => AppColors.themeTasks,
      BinKind.trip => AppColors.themeTravel,
      BinKind.memoir => AppColors.themeJournal,
      BinKind.event => AppColors.themePlanner,
      BinKind.pin => AppColors.themeSplitter,
    };
    return isDark ? Color.lerp(base, Colors.white, 0.28)! : base;
  }

  static String _ago(DateTime then, DateTime now) {
    final d = now.difference(then);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  void _restore(BinEntry entry) {
    ref.read(binProvider.notifier).restore(entry.id);
    AppToastEngine().notify(
      title: 'Restored',
      message: '"${entry.title}" is back in ${entry.kind.plural}.',
      actionLabel: 'View',
      onAction: () => widget.onOpenModule(entry.kind.moduleIndex),
    );
  }

  Future<void> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showSanctuaryDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.bodoniModa(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.dmSans(fontSize: 13, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.onSurfaceVariant)),
          ),
          Pressable(
            pressedScale: 0.95,
            hoverLift: 0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtext = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final all = ref.watch(binProvider);
    final entries = _filter == null ? all : all.where((e) => e.kind == _filter).toList();
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final columns = Masonry.columnsFor(constraints.maxWidth - 48, minTileWidth: 170, maxColumns: 4);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 36 : 20, 16, wide ? 36 : 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SYSTEM', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: accent)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Bin', style: GoogleFonts.bodoniModa(fontSize: 34, fontWeight: FontWeight.bold, color: ink, height: 1)),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RollingText(
                          '${all.length} ${all.length == 1 ? 'item' : 'items'}',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: subtext),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deleted things wait here for 30 days, then clear themselves.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: subtext),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bulk actions
              if (all.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PillButton(
                      icon: LucideIcons.rotateCcw,
                      label: 'Restore all',
                      color: ink,
                      onTap: () => ref.read(binProvider.notifier).restoreAll(),
                    ),
                    _PillButton(
                      icon: LucideIcons.trash2,
                      label: 'Empty bin',
                      color: AppColors.error,
                      onTap: () => _confirm(
                        title: 'Empty the Bin?',
                        message: 'All ${all.length} items will be deleted for good. This can\'t be undone.',
                        confirmLabel: 'Empty bin',
                        onConfirm: () => ref.read(binProvider.notifier).empty(),
                      ),
                    ),
                  ],
                ),
              if (all.isNotEmpty) const SizedBox(height: 16),

              // Type filters
              if (all.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: all.length,
                        selected: _filter == null,
                        tone: ink,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final kind in BinKind.values)
                        if (all.any((e) => e.kind == kind))
                          _FilterChip(
                            label: kind.plural,
                            count: all.where((e) => e.kind == kind).length,
                            selected: _filter == kind,
                            tone: _toneFor(kind, isDark),
                            onTap: () => setState(() => _filter = _filter == kind ? null : kind),
                          ),
                    ],
                  ),
                ),
              if (all.isNotEmpty) const SizedBox(height: 18),

              // Board
              AnimatedSwitcher(
                duration: Motion.standard,
                switchInCurve: Motion.silk,
                child: entries.isEmpty
                    ? EmptyState(
                        key: ValueKey(_filter),
                        icon: LucideIcons.trash2,
                        title: all.isEmpty ? 'Nothing in the Bin' : 'Nothing of this kind',
                        message: all.isEmpty
                            ? 'Deleted notes, tasks, expenses, shopping items and outfits land here, ready to restore.'
                            : 'Try another filter to see the rest of the Bin.',
                      )
                    : MotionColumn(
                        key: const ValueKey('board'),
                        columns: columns,
                        spacing: 12,
                        columnSpacing: 12,
                        children: [
                          for (final entry in entries)
                            _BinCard(
                              key: ValueKey(entry.id),
                              entry: entry,
                              icon: _iconFor(entry.kind),
                              tone: _toneFor(entry.kind, isDark),
                              ago: _ago(entry.deletedAt, now),
                              daysLeft: entry.daysLeft(now),
                              onRestore: () => _restore(entry),
                              onPurge: () => _confirm(
                                title: 'Delete forever?',
                                message: '"${entry.title}" will be gone for good.',
                                confirmLabel: 'Delete',
                                onConfirm: () => ref.read(binProvider.notifier).purge(entry.id),
                              ),
                            ),
                        ],
                      ),
              ),
            ].revealed(),
          ),
        );
      },
    );
  }
}

class _BinCard extends StatefulWidget {
  final BinEntry entry;
  final IconData icon;
  final Color tone;
  final String ago;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  const _BinCard({
    super.key,
    required this.entry,
    required this.icon,
    required this.tone,
    required this.ago,
    required this.daysLeft,
    required this.onRestore,
    required this.onPurge,
  });

  @override
  State<_BinCard> createState() => _BinCardState();
}

class _BinCardState extends State<_BinCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtext = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final surface = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFE8E3D8);
    final entry = widget.entry;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Motion.silk,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: edBox(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? widget.tone.withValues(alpha: 0.5) : border),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF2C241D)).withValues(alpha: _hovered ? 0.14 : 0.05),
              blurRadius: _hovered ? 22 : 10,
              offset: Offset(0, _hovered ? 10 : 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tinted top band with the kind badge.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              color: widget.tone.withValues(alpha: isDark ? 0.16 : 0.10),
              child: Row(
                children: [
                  Icon(widget.icon, size: 14, color: widget.tone),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.kind.label.toUpperCase(),
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: widget.tone),
                    ),
                  ),
                  Text(widget.ago, style: GoogleFonts.dmSans(fontSize: 11, color: subtext)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: ink, height: 1.2),
                  ),
                  if (entry.detail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.detail,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 12, height: 1.45, color: subtext),
                    ),
                  ],
                  if (entry.meta.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: edBox(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Text(entry.meta, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: subtext)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Retention: how much of the 30 days remains.
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: widget.daysLeft / 30,
                            minHeight: 2,
                            backgroundColor: border,
                            valueColor: AlwaysStoppedAnimation(widget.tone.withValues(alpha: 0.7)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${widget.daysLeft}d left', style: GoogleFonts.dmSans(fontSize: 11, color: subtext)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Pressable(
                      pressedScale: 0.95,
                      hoverLift: 0,
                      child: TextButton.icon(
                        onPressed: widget.onRestore,
                        icon: Icon(LucideIcons.rotateCcw, size: 14, color: ink),
                        label: Text('Restore', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
                      ),
                    ),
                  ),
                  Pressable(
                    pressedScale: 0.9,
                    hoverLift: 0,
                    child: IconButton(
                      tooltip: 'Delete forever',
                      onPressed: widget.onPurge,
                      icon: Icon(LucideIcons.trash2, size: 16, color: AppColors.error.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.93,
        hoverLift: 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Motion.silk,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: edBox(
            color: selected ? tone.withValues(alpha: isDark ? 0.22 : 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? tone.withValues(alpha: 0.6) : subtext.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? tone : subtext),
              ),
              const SizedBox(width: 6),
              RollingText('$count', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: subtext)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      hoverLift: 1.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: edBox(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
