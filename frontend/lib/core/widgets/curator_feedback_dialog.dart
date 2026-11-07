import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/feedback_service.dart';
import '../services/sanctuary_supabase_service.dart';
import '../state/app_settings.dart';
import 'app_toast_engine.dart';
import 'fluid_ui_effects.dart';

class CuratorFeedbackDialog extends ConsumerStatefulWidget {
  const CuratorFeedbackDialog({super.key});

  static Future<void> show(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CuratorFeedbackDialog(),
    );
  }

  @override
  ConsumerState<CuratorFeedbackDialog> createState() => _CuratorFeedbackDialogState();
}

class _CuratorFeedbackDialogState extends ConsumerState<CuratorFeedbackDialog> {
  String _selectedType = 'feature_suggestion';
  String _selectedCategory = 'General';
  String _selectedImpact = 'nice_to_have';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _emailCtrl;

  final List<Map<String, dynamic>> _types = [
    {
      'id': 'feature_suggestion',
      'label': 'Suggestion',
      'icon': LucideIcons.sparkles,
      'color': const Color(0xFFD9725B), // Terracotta
    },
    {
      'id': 'general_feedback',
      'label': 'Feedback',
      'icon': LucideIcons.messageSquare,
      'color': const Color(0xFF8FA878), // Olive Sage
    },
    {
      'id': 'bug_report',
      'label': 'Bug Glitch',
      'icon': LucideIcons.bug,
      'color': const Color(0xFFC84B31), // Crimson
    },
    {
      'id': 'ui_enhancement',
      'label': 'UI Request',
      'icon': LucideIcons.palette,
      'color': const Color(0xFFD4AF37), // Gold
    },
  ];

  final List<String> _categories = [
    'General',
    'AI Assistant',
    'Tasks & Planner',
    'Notes & Vault',
    'Design & UI',
    'Focus & Audio',
    'Habits',
    'Performance',
  ];

  final List<Map<String, String>> _impacts = [
    {'id': 'nice_to_have', 'label': '🌿 Nice to Have'},
    {'id': 'important', 'label': '⚡ High Priority'},
    {'id': 'critical', 'label': '🔥 Game Changer'},
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();

    final user = SanctuarySupabaseService().currentUser;
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty) {
      AppToastEngine().showToast(
        context,
        title: 'Title Required',
        message: 'Please provide a short summary of your idea or feedback.',
      );
      return;
    }

    if (desc.isEmpty) {
      AppToastEngine().showToast(
        context,
        title: 'Description Needed',
        message: 'Please provide some detail on what you would love to see.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final settings = ref.read(appSettingsProvider);
      final user = SanctuarySupabaseService().currentUser;
      final userName = _isAnonymous
          ? 'Anonymous Curator'
          : (settings.displayName.isNotEmpty
              ? settings.displayName
              : (user?.email?.split('@').first ?? 'Sanctuary Curator'));
      final email = _isAnonymous ? null : _emailCtrl.text.trim();

      await ref.read(feedbackListProvider.notifier).submitFeedback(
            type: _selectedType,
            title: title,
            description: desc,
            impact: _selectedImpact,
            category: _selectedCategory,
            userIdentifier: userName,
            userEmail: email,
          );

      if (mounted) {
        Navigator.pop(context);
        AppToastEngine().showToast(
          context,
          title: '✦ Suggestion Delivered',
          message: 'Thank you! Your feedback has been sent directly to the Admin command center.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppToastEngine().showToast(
          context,
          title: 'Submission Notice',
          message: 'Could not send feedback: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFB0A89F) : const Color(0xFF6B655D);
    final sheetBg = isDark ? const Color(0xFF12100E) : const Color(0xFFFFFDF8);
    final cardBg = isDark ? const Color(0xFF191613) : const Color(0xFFF3ECE0);
    final borderColor = isDark ? const Color(0xFF2C241E) : const Color(0xFFE5DDD0);
    const terracotta = Color(0xFFD9725B);
    const warmSage = Color(0xFF8FA878);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.25),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: subtextColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: terracotta.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(LucideIcons.messageSquarePlus, size: 18, color: terracotta),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback & Suggestions',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Direct channel to NOTtEodo Architects & Admins',
                          style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1A16) : const Color(0xFFEDE6DA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.x, size: 16, color: subtextColor),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Form Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // 1. Type Selector
                Text(
                  'SUBMISSION TYPE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: terracotta,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) {
                    final isSelected = _selectedType == t['id'];
                    final color = t['color'] as Color;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = t['id'] as String);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.2) : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : borderColor,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t['icon'] as IconData, size: 13, color: isSelected ? color : subtextColor),
                            const SizedBox(width: 6),
                            Text(
                              t['label'] as String,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? color : primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // 2. Title Input
                Text(
                  'SUMMARY / HEADLINE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: terracotta,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  style: GoogleFonts.dmSans(fontSize: 14, color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: _selectedType == 'feature_suggestion'
                        ? 'e.g. WearOS tile for one-tap note capture'
                        : (_selectedType == 'bug_report'
                            ? 'e.g. Audio loop glitch on lock screen'
                            : 'e.g. Daily briefing synthesis is incredible'),
                    hintStyle: GoogleFonts.dmSans(fontSize: 12.5, color: subtextColor.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: terracotta, width: 1.5)),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Category Selector
                Text(
                  'AREA / CATEGORY',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: terracotta,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final isSelected = _selectedCategory == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = c);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? warmSage.withValues(alpha: 0.22) : cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? warmSage : borderColor,
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Text(
                              c,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? warmSage : subtextColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Detailed Description
                Text(
                  'DETAILS & WORKFLOW',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: terracotta,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  minLines: 3,
                  style: GoogleFonts.dmSans(fontSize: 13, height: 1.4, color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Share how you envision this working, the problem it solves, or your feedback...',
                    hintStyle: GoogleFonts.dmSans(fontSize: 12, color: subtextColor.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: terracotta, width: 1.5)),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Impact Selector
                Text(
                  'IMPACT ON YOUR WORKSPACE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: terracotta,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: _impacts.map((imp) {
                    final isSelected = _selectedImpact == imp['id'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedImpact = imp['id']!);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? terracotta.withValues(alpha: 0.18) : cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? terracotta : borderColor,
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Text(
                            imp['label']!,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? terracotta : primaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // 6. Identity Options
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isAnonymous ? LucideIcons.userX : LucideIcons.userCheck,
                            size: 16,
                            color: _isAnonymous ? subtextColor : warmSage,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAnonymous ? 'Submit Anonymously' : 'Include Curator Identity',
                            style: GoogleFonts.dmSans(fontSize: 12, color: primaryTextColor),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isAnonymous,
                        activeColor: terracotta,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _isAnonymous = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                BouncyTouchEffect(
                  pressedScale: 0.96,
                  onTap: _isSubmitting ? null : _handleSubmit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD9725B), Color(0xFFC45A43)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: terracotta.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.sendHorizontal, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Dispatch to Admin Command Center',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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

