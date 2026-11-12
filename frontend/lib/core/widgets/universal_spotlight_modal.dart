import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Universal Spotlight Search: Real-time full-text search across Notes, Tasks,
/// Habits, Expenses, and Wardrobe items in one unified modal.
class UniversalSpotlightModal extends ConsumerStatefulWidget {
  final Function(int moduleIndex)? onNavigateToModule;

  const UniversalSpotlightModal({super.key, this.onNavigateToModule});

  static Future<void> show(BuildContext context, {Function(int moduleIndex)? onNavigateToModule}) async {
    SanctuaryHapticEngine.selection();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => UniversalSpotlightModal(onNavigateToModule: onNavigateToModule),
    );
  }

  @override
  ConsumerState<UniversalSpotlightModal> createState() => _UniversalSpotlightModalState();
}

class _UniversalSpotlightModalState extends ConsumerState<UniversalSpotlightModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final cardBg = isDark ? const Color(0xFF161311) : const Color(0xFFFAF8F5);
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD4AF37);
    const sage = Color(0xFF8FA878);

    final query = _searchCtrl.text.trim().toLowerCase();

    final notes = ref.watch(notesProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final expenses = ref.watch(expensesProvider).expenses;
    final wardrobe = ref.watch(wardrobeProvider);

    // Filter results
    final matchedNotes = query.isEmpty
        ? <NoteItem>[]
        : notes.where((n) => n.title.toLowerCase().contains(query) || n.content.toLowerCase().contains(query)).toList();

    final matchedTasks = query.isEmpty
        ? <TaskItem>[]
        : tasks.where((t) => t.title.toLowerCase().contains(query) || t.notes.toLowerCase().contains(query)).toList();

    final matchedHabits = query.isEmpty
        ? <HabitItem>[]
        : habits.where((h) => h.title.toLowerCase().contains(query)).toList();

    final matchedExpenses = query.isEmpty
        ? <ExpenseItem>[]
        : expenses.where((e) => e.title.toLowerCase().contains(query) || e.category.toLowerCase().contains(query)).toList();

    final matchedWardrobe = query.isEmpty
        ? <WardrobeOutfit>[]
        : wardrobe.where((w) => w.title.toLowerCase().contains(query) || w.category.toLowerCase().contains(query) || w.vibe.toLowerCase().contains(query)).toList();

    final totalMatches = matchedNotes.length + matchedTasks.length + matchedHabits.length + matchedExpenses.length + matchedWardrobe.length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gold.withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.20),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, size: 18, color: gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.dmSans(fontSize: 15, color: primaryText, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Search notes, tasks, habits, expenses, wardrobe...',
                            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: Icon(LucideIcons.x, size: 16, color: subtextColor),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'Notes', 'Tasks', 'Habits', 'Expenses', 'Wardrobe'].map((tab) {
                      final isSel = _selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(tab, style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: terracotta,
                          labelStyle: TextStyle(color: isSel ? Colors.white : subtextColor),
                          backgroundColor: isDark ? const Color(0xFF221F1C) : const Color(0xFFEDE8DE),
                          onSelected: (_) => setState(() => _selectedTab = tab),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),

                // Results List
                Flexible(
                  child: query.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.compass, size: 36, color: gold.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'Universal Spotlight',
                                style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: primaryText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type any keyword to instantly search across all 5 sanctuary modules simultaneously.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                              ),
                            ],
                          ),
                        )
                      : totalMatches == 0
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No matching items found for "$query".',
                                style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              children: [
                                // 1. Notes
                                if ((_selectedTab == 'All' || _selectedTab == 'Notes') && matchedNotes.isNotEmpty)
                                  _buildSection('Notes', matchedNotes.length, LucideIcons.fileText, terracotta, [
                                    ...matchedNotes.map((n) => _buildResultTile(
                                          title: n.title,
                                          subtitle: n.excerpt.isNotEmpty ? n.excerpt : n.content,
                                          tag: n.tag,
                                          icon: LucideIcons.fileText,
                                          color: terracotta,
                                          isDark: isDark,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            widget.onNavigateToModule?.call(1);
                                          },
                                        )),
                                  ]),

                                // 2. Tasks
                                if ((_selectedTab == 'All' || _selectedTab == 'Tasks') && matchedTasks.isNotEmpty)
                                  _buildSection('Tasks', matchedTasks.length, LucideIcons.checkSquare, gold, [
                                    ...matchedTasks.map((t) => _buildResultTile(
                                          title: t.title,
                                          subtitle: t.dueAt != null ? 'Due: ${DateLabels.dateOnly(t.dueAt!)}' : 'Today',
                                          tag: t.completed ? 'Completed' : 'Pending',
                                          icon: LucideIcons.checkSquare,
                                          color: gold,
                                          isDark: isDark,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            widget.onNavigateToModule?.call(2);
                                          },
                                        )),
                                  ]),

                                // 3. Habits
                                if ((_selectedTab == 'All' || _selectedTab == 'Habits') && matchedHabits.isNotEmpty)
                                  _buildSection('Habits', matchedHabits.length, LucideIcons.flame, const Color(0xFFE8927C), [
                                    ...matchedHabits.map((h) => _buildResultTile(
                                          title: h.title,
                                          subtitle: '${h.streak} day active streak',
                                          tag: h.time,
                                          icon: LucideIcons.flame,
                                          color: const Color(0xFFE8927C),
                                          isDark: isDark,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            widget.onNavigateToModule?.call(9);
                                          },
                                        )),
                                  ]),

                                // 4. Expenses
                                if ((_selectedTab == 'All' || _selectedTab == 'Expenses') && matchedExpenses.isNotEmpty)
                                  _buildSection('Expenses', matchedExpenses.length, LucideIcons.wallet, sage, [
                                    ...matchedExpenses.map((e) => _buildResultTile(
                                          title: e.title,
                                          subtitle: '\$${e.amount.toStringAsFixed(2)} · ${DateLabels.dateOnly(e.spentAt)}',
                                          tag: e.category,
                                          icon: LucideIcons.wallet,
                                          color: sage,
                                          isDark: isDark,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            widget.onNavigateToModule?.call(5);
                                          },
                                        )),
                                  ]),

                                // 5. Wardrobe
                                if ((_selectedTab == 'All' || _selectedTab == 'Wardrobe') && matchedWardrobe.isNotEmpty)
                                  _buildSection('Wardrobe', matchedWardrobe.length, LucideIcons.shirt, const Color(0xFFC88552), [
                                    ...matchedWardrobe.map((w) => _buildResultTile(
                                          title: w.title,
                                          subtitle: '${w.category} · ${w.weather}',
                                          tag: w.vibe,
                                          icon: LucideIcons.shirt,
                                          color: const Color(0xFFC88552),
                                          isDark: isDark,
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            widget.onNavigateToModule?.call(4);
                                          },
                                        )),
                                  ]),
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

  Widget _buildSection(String title, int count, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                '${title.toUpperCase()} ($count)',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: color),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildResultTile({
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        SanctuaryHapticEngine.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: edBox(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: edBox(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
