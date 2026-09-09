import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../state/sanctuary_state.dart';

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

    final notes = ref.watch(notesProvider);
    final tasks = ref.watch(tasksProvider);
    final expensesState = ref.watch(expensesProvider);
    final outfits = ref.watch(wardrobeProvider);
    final trips = ref.watch(travelProvider);
    final memoirs = ref.watch(journalProvider);

    final filteredNotes = _query.isEmpty
        ? []
        : notes.where((n) => n.title.toLowerCase().contains(_query.toLowerCase()) || n.excerpt.toLowerCase().contains(_query.toLowerCase())).toList();

    final filteredTasks = _query.isEmpty
        ? []
        : tasks.where((t) => t.title.toLowerCase().contains(_query.toLowerCase())).toList();

    final filteredExpenses = _query.isEmpty
        ? []
        : expensesState.expenses.where((e) => e.title.toLowerCase().contains(_query.toLowerCase()) || e.category.toLowerCase().contains(_query.toLowerCase())).toList();

    final filteredOutfits = _query.isEmpty
        ? []
        : outfits.where((o) => o.title.toLowerCase().contains(_query.toLowerCase()) || o.items.toLowerCase().contains(_query.toLowerCase())).toList();

    final filteredTrips = _query.isEmpty
        ? []
        : trips.where((t) => t.title.toLowerCase().contains(_query.toLowerCase()) || t.destination.toLowerCase().contains(_query.toLowerCase())).toList();

    final filteredMemoirs = _query.isEmpty
        ? []
        : memoirs.where((m) => m.title.toLowerCase().contains(_query.toLowerCase()) || m.excerpt.toLowerCase().contains(_query.toLowerCase())).toList();

    final totalResults = filteredNotes.length +
        filteredTasks.length +
        filteredExpenses.length +
        filteredOutfits.length +
        filteredTrips.length +
        filteredMemoirs.length;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                              hintText: 'Search notes, tasks, expenses, trips, memoirs...',
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
                                  'Universal Command Palette',
                                  style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Type keywords to instantly search across all sanctuary modules',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                                ),
                              ],
                            ),
                          )
                        : totalResults == 0
                            ? Center(
                                child: Text('No sanctuary items found matching "$_query"',
                                    style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor)),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  if (filteredNotes.isNotEmpty) ...[
                                    _sectionTitle('NOTES & SPACES (${filteredNotes.length})', accentColor),
                                    ...filteredNotes.map((n) => _resultItem(
                                          title: n.title,
                                          subtitle: '${n.space} · ${n.tag}',
                                          badge: 'Note',
                                          icon: LucideIcons.fileText,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            widget.onClose();
                                            widget.onNavigateToModule(1);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],
                                  if (filteredTasks.isNotEmpty) ...[
                                    _sectionTitle('TASKS & FLOW (${filteredTasks.length})', accentColor),
                                    ...filteredTasks.map((t) => _resultItem(
                                          title: t.title,
                                          subtitle: '${t.timeOfDay} · ${t.priority}',
                                          badge: 'Task',
                                          icon: LucideIcons.checkSquare,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            widget.onClose();
                                            widget.onNavigateToModule(2);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],
                                  if (filteredTrips.isNotEmpty) ...[
                                    _sectionTitle('TRAVEL & PASSPORT (${filteredTrips.length})', accentColor),
                                    ...filteredTrips.map((tr) => _resultItem(
                                          title: tr.title,
                                          subtitle: '${tr.flight} · ${tr.destination} · ${tr.date}',
                                          badge: 'Travel',
                                          icon: LucideIcons.plane,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            widget.onClose();
                                            widget.onNavigateToModule(6);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],
                                  if (filteredExpenses.isNotEmpty) ...[
                                    _sectionTitle('EXPENSES & LEDGER (${filteredExpenses.length})', accentColor),
                                    ...filteredExpenses.map((e) => _resultItem(
                                          title: e.title,
                                          subtitle: '₹${e.amount.toStringAsFixed(0)} · ${e.category}',
                                          badge: 'Expense',
                                          icon: LucideIcons.dollarSign,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            widget.onClose();
                                            widget.onNavigateToModule(5);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],
                                  if (filteredOutfits.isNotEmpty) ...[
                                    _sectionTitle('WARDROBE LOOKBOOK (${filteredOutfits.length})', accentColor),
                                    ...filteredOutfits.map((o) => _resultItem(
                                          title: o.title,
                                          subtitle: '${o.tag} · ${o.items}',
                                          badge: 'Wardrobe',
                                          icon: LucideIcons.shirt,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            widget.onClose();
                                            widget.onNavigateToModule(4);
                                          },
                                        )),
                                    const SizedBox(height: 12),
                                  ],
                                  if (filteredMemoirs.isNotEmpty) ...[
                                    _sectionTitle('VOICE MEMOIRS (${filteredMemoirs.length})', accentColor),
                                    ...filteredMemoirs.map((m) => _resultItem(
                                          title: m.title,
                                          subtitle: '${m.duration} · ${m.mood}',
                                          badge: 'Memoir',
                                          icon: LucideIcons.mic,
                                          primaryTextColor: primaryTextColor,
                                          subtextColor: subtextColor,
                                          onTap: () {
                                            widget.onClose();
                                            widget.onNavigateToModule(7);
                                          },
                                        )),
                                  ],
                                ],
                              ),
                  ),
                ],
              ),
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
