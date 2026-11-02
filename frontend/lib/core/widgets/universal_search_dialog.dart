import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../state/sanctuary_state.dart';
import '../motion/motion.dart';
import '../state/app_settings.dart';
import '../utils/date_labels.dart';
import 'entry_editor.dart';

class UniversalSearchDialog extends ConsumerStatefulWidget {
  final Function(int moduleIndex) onNavigateToModule;
  final VoidCallback onClose;

  const UniversalSearchDialog({
    super.key,
    required this.onNavigateToModule,
    required this.onClose,
  });

  @override
  ConsumerState<UniversalSearchDialog> createState() => _UniversalSearchDialogState();
}

class _UniversalSearchDialogState extends ConsumerState<UniversalSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF000000) : AppColors.background;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final currency = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    final q = _query.toLowerCase();
    bool hit(Iterable<String> fields) => q.isNotEmpty && fields.any((f) => f.toLowerCase().contains(q));

    // Each section: label, module index, and the matching rows.
    final sections = <_Section>[
      _Section('NOTES', 1, LucideIcons.fileText, [
        for (final n in ref.watch(notesProvider))
          if (hit([n.title, n.body, n.tag, n.space])) _Hit(n.title, '${n.space} · ${n.tag} · ${n.date}', EntryKind.note, n),
      ]),
      _Section('TASKS', 2, LucideIcons.checkSquare, [
        for (final t in ref.watch(tasksProvider))
          if (hit([t.title, t.notes, t.space, t.priority]))
            _Hit(t.title, t.dueAt == null ? '${t.timeOfDay} · ${t.priority}' : 'Due ${DateLabels.dateTime(t.dueAt!)} · ${t.priority}',
                EntryKind.task, t),
      ]),
      _Section('PLANNER', 3, LucideIcons.calendar, [
        for (final e in ref.watch(eventsProvider))
          if (hit([e.title, e.notes])) _Hit(e.title, DateLabels.dateTime(e.startsAt), EntryKind.event, e),
      ]),
      _Section('TRAVEL', 6, LucideIcons.plane, [
        for (final tr in ref.watch(travelProvider))
          if (hit([tr.title, tr.destination, tr.flight, ...tr.packingList]))
            _Hit(tr.title, [tr.destination, tr.flight, tr.date].where((s) => s.isNotEmpty).join(' · '), EntryKind.trip, tr),
      ]),
      _Section('EXPENSES', 5, LucideIcons.wallet, [
        for (final e in ref.watch(expensesProvider).expenses)
          if (hit([e.title, e.category, e.note]))
            _Hit(e.title, '${formatMoney(e.amount, currency)} · ${e.category} · ${e.date}', EntryKind.expense, e),
      ]),
      _Section('WARDROBE', 4, LucideIcons.shirt, [
        for (final o in ref.watch(wardrobeProvider))
          if (hit([o.title, o.items, o.fabric, o.tag])) _Hit(o.title, '${o.tag} · ${o.items}', EntryKind.outfit, o),
      ]),
      _Section('JOURNAL', 7, LucideIcons.bookOpen, [
        for (final m in ref.watch(journalProvider))
          if (!m.isPrivate && hit([m.title, m.excerpt, m.mood])) _Hit(m.title, '${m.date} · ${m.mood}', EntryKind.memoir, m),
      ]),
      _Section('MOODBOARD', 8, LucideIcons.image, [
        for (final p in ref.watch(moodboardProvider))
          if (hit([p.title, p.note])) _Hit(p.title, p.note, EntryKind.pin, p),
      ]),
      _Section('HABITS', 9, LucideIcons.flame, [
        for (final h in ref.watch(habitsProvider))
          if (hit([h.title])) _Hit(h.title, '${h.time} · ${h.streak} day streak', EntryKind.habit, h),
      ]),
      _Section('SHOPPING', 10, LucideIcons.shoppingBag, [
        for (final s in ref.watch(shoppingProvider))
          if (hit([s.name, s.store])) _Hit(s.name, '${s.store.isEmpty ? 'Any store' : s.store} · ${formatMoney(s.price.toDouble(), currency)}', EntryKind.shopping, s),
      ]),
    ].where((s) => s.hits.isNotEmpty).toList();

    final totalResults = sections.fold<int>(0, (n, s) => n + s.hits.length);

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(28),
              elevation: 24,
              child: Column(
                children: [
                  // Top Search Input Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search, color: accentColor, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: GoogleFonts.dmSans(fontSize: 16, color: primaryTextColor),
                            decoration: InputDecoration(
                              hintText: 'Search everything: notes, tasks, events, trips…',
                              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: subtextColor.withValues(alpha: 0.6)),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _query = val.trim();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close search',
                          icon: Icon(LucideIcons.x, color: primaryTextColor, size: 20),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9)),

                  // Results List
                  Expanded(
                    child: _query.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.command, size: 40, color: subtextColor.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  'Search & Commands',
                                  style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Search notes, tasks, expenses, and more',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                                ),
                              ],
                            ),
                          )
                        : totalResults == 0
                            ? Center(
                                child: Text('No results found matching "$_query"',
                                    style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  for (final section in sections) ...[
                                    _sectionTitle('${section.label} (${section.hits.length})', accentColor),
                                    ...section.hits.map((h) => _resultItem(
                                          title: h.title,
                                          subtitle: h.subtitle,
                                          badge: h.kind.label,
                                          icon: section.icon,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            // Go to the module and open the item itself.
                                            widget.onNavigateToModule(section.moduleIndex);
                                            openEntryEditor(context, h.kind, editing: h.item);
                                            widget.onClose();
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],
                                ].revealed(style: RevealStyle.slideIn, distance: 14),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _sectionTitle(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: accentColor),
      ),
    );
  }

  Widget _resultItem({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color primaryTextColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 18, color: AppColors.secondary),
        title: Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
        subtitle: Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        ),
      ),
    );
  }
}

class _Section {
  final String label;
  final int moduleIndex;
  final IconData icon;
  final List<_Hit> hits;

  const _Section(this.label, this.moduleIndex, this.icon, this.hits);
}

class _Hit {
  final String title;
  final String subtitle;
  final EntryKind kind;
  final Object item;

  const _Hit(this.title, this.subtitle, this.kind, this.item);
}
