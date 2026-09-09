import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/nlp_date_parser.dart';
import '../state/sanctuary_state.dart';
import 'stitch_logo_widget.dart';

class DedicatedCreationScreen extends ConsumerStatefulWidget {
  final int activeIndex;
  final VoidCallback onClose;
  final Function(String) onItemSaved;

  const DedicatedCreationScreen({
    super.key,
    required this.activeIndex,
    required this.onClose,
    required this.onItemSaved,
  });

  @override
  ConsumerState<DedicatedCreationScreen> createState() => _DedicatedCreationScreenState();
}

class _DedicatedCreationScreenState extends ConsumerState<DedicatedCreationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: 'Tomorrow at 10 AM');

  String _selectedPriority = 'High Priority';
  String _selectedSpace = 'Academic Space';

  final List<String> _moduleNames = [
    'Home Quick Note',
    'Paper Note',
    'Wax-Stamp Task',
    'Schedule Event',
    'Wardrobe Lookbook',
    'Expense Slip',
    'Travel Stub',
    'Voice Journal',
    'Aesthetic Pin',
    'Daily Habit',
    'Shopping Tag',
    'System Setting',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _saveEntry(String moduleTitle) {
    final title = _titleController.text.trim().isEmpty ? 'Untitled $moduleTitle' : _titleController.text.trim();
    final excerpt = _bodyController.text.trim().isEmpty ? 'Created on ${DateTime.now().toString().substring(0, 10)}' : _bodyController.text.trim();

    // Actual Riverpod persistence per module
    switch (widget.activeIndex) {
      case 0:
      case 1:
        ref.read(notesProvider.notifier).addNote(
              title: title,
              space: _selectedSpace,
              tag: _tagController.text.isEmpty ? 'Quick Note' : _tagController.text.trim(),
              excerpt: excerpt,
            );
        break;
      case 2:
        ref.read(tasksProvider.notifier).addTask(
              title: title,
              priority: _selectedPriority,
              space: _selectedSpace,
              timeOfDay: 'Morning',
            );
        break;
      case 4:
        ref.read(wardrobeProvider.notifier).addOutfit(
              title: title,
              items: excerpt,
              weather: 'Mild · 22°C',
              fabric: 'Linen Blend',
              tag: _tagController.text.isEmpty ? 'Curated Look' : _tagController.text.trim(),
            );
        break;
      case 5:
        final amt = double.tryParse(_tagController.text.trim()) ?? 450.0;
        ref.read(expensesProvider.notifier).addExpense(
              title: title,
              amount: amt,
              category: 'Curated Spend',
            );
        break;
      case 6:
        ref.read(travelProvider.notifier).addTrip(
              title: title,
              flight: 'IX-720',
              destination: excerpt,
              date: 'Upcoming Expedition',
            );
        break;
      case 7:
        ref.read(journalProvider.notifier).addMemoir(
              title: title,
              duration: '1:45',
              excerpt: excerpt,
              mood: 'Reflective',
            );
        break;
      case 9:
        ref.read(habitsProvider.notifier).addHabit(
              title: title,
              time: '08:00 AM',
            );
        break;
      case 10:
        final price = int.tryParse(_tagController.text.trim()) ?? 600;
        ref.read(shoppingProvider.notifier).addItem(
              name: title,
              store: 'Curated Store',
              price: price,
            );
        break;
      default:
        ref.read(notesProvider.notifier).addNote(
              title: title,
              space: 'General Space',
              tag: 'Sanctuary Entry',
              excerpt: excerpt,
            );
    }

    widget.onItemSaved(title);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moduleTitle = _moduleNames[widget.activeIndex < _moduleNames.length ? widget.activeIndex : 0];
    final surfaceColor = isDark ? const Color(0xFF000000) : AppColors.background;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Material(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(28),
              elevation: 24,
              child: Column(
                children: [
                  // Full-Screen Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const StitchMonogramNWidget(size: 26),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DEDICATED CANVAS', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: accentColor)),
                                    Text(moduleTitle, style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: primaryTextColor, size: 22),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9)),

                  // Scrollable Form Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Input Field
                          TextField(
                            controller: _titleController,
                            autofocus: true,
                            style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                            decoration: InputDecoration(
                              hintText: 'Enter $moduleTitle Title...',
                              hintStyle: GoogleFonts.bodoniModa(fontSize: 20, color: subtextColor.withValues(alpha: 0.5)),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Module-Specific Options
                          if (widget.activeIndex == 0 || widget.activeIndex == 1) _buildNotesOptions(primaryTextColor, subtextColor),
                          if (widget.activeIndex == 2) _buildTasksOptions(primaryTextColor, subtextColor),
                          if (widget.activeIndex == 3) _buildPlannerOptions(primaryTextColor, subtextColor),
                          if (widget.activeIndex == 4) _buildWardrobeOptions(primaryTextColor, subtextColor),
                          if (widget.activeIndex == 5) _buildExpensesOptions(primaryTextColor, subtextColor),
                          const SizedBox(height: 16),

                          // Large Description/Body Area
                          TextField(
                            controller: _bodyController,
                            maxLines: 6,
                            style: GoogleFonts.dmSans(fontSize: 14, color: primaryTextColor, height: 1.5),
                            decoration: InputDecoration(
                              hintText: 'Type detailed contents, notes, tags, or context...',
                              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: subtextColor.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF080808) : Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                      border: isDark ? const Border(top: BorderSide(color: Color(0xFF1E1E1E))) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: widget.onClose,
                          icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.secondary),
                          label: Text('Discard', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.secondary)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: () => _saveEntry(moduleTitle),
                          icon: const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                          label: Text('Save $moduleTitle', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
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

  Widget _buildNotesOptions(Color primaryTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT KNOWLEDGE SPACE', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: subtextColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['Academic Space', 'Design Space', 'Personal Space', 'Travel Space'].map((s) {
            final isSel = _selectedSpace == s;
            return ChoiceChip(
              label: Text(s, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : primaryTextColor)),
              selected: isSel,
              selectedColor: AppColors.secondary,
              onSelected: (val) => setState(() => _selectedSpace = s),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTasksOptions(Color primaryTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WAX STAMP PRIORITY', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: subtextColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['Urgent & Critical', 'High Priority', 'Medium Priority'].map((p) {
            final isSel = _selectedPriority == p;
            return ChoiceChip(
              label: Text(p, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : primaryTextColor)),
              selected: isSel,
              selectedColor: AppColors.secondary,
              onSelected: (val) => setState(() => _selectedPriority = p),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlannerOptions(Color primaryTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NATURAL LANGUAGE DATE / TIME PARSER', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: subtextColor)),
        const SizedBox(height: 8),
        TextField(
          controller: _dateController,
          style: GoogleFonts.dmSans(fontSize: 13, color: primaryTextColor),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.clock, size: 14, color: AppColors.secondary),
            suffixIcon: IconButton(
              icon: const Icon(LucideIcons.check, size: 14),
              onPressed: () {
                final dt = NlpDateParser.parseNaturalLanguage(_dateController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Parsed: ${NlpDateParser.formatDate(dt)}')),
                );
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildWardrobeOptions(Color primaryTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OUTFIT CATEGORY & BRAND', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: subtextColor)),
        const SizedBox(height: 8),
        TextField(
          controller: _tagController,
          decoration: const InputDecoration(labelText: 'e.g. Shirts · Studio Edit', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildExpensesOptions(Color primaryTextColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXPENSE AMOUNT (₹) & SPLIT MEMBERS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: subtextColor)),
        const SizedBox(height: 8),
        TextField(
          controller: _tagController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹) e.g. 1450', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}
