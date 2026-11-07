import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../utils/date_labels.dart';
import 'app_toast_engine.dart';

/// 60-Second Evening Zen Review & Daily Shutdown Ritual Dialog
/// Summarizes daily wins, captures 1-sentence gratitude/reflection, and seals the day.
class EveningZenReviewDialog extends ConsumerStatefulWidget {
  const EveningZenReviewDialog({super.key});

  static Future<void> show(BuildContext context) async {
    SanctuaryHapticEngine.selection();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => const EveningZenReviewDialog(),
    );
  }

  @override
  ConsumerState<EveningZenReviewDialog> createState() => _EveningZenReviewDialogState();
}

class _EveningZenReviewDialogState extends ConsumerState<EveningZenReviewDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sealCtrl;
  final TextEditingController _reflectionCtrl = TextEditingController();
  bool _isSealed = false;

  @override
  void initState() {
    super.initState();
    _sealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _sealCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _sealTheDay() async {
    SanctuaryHapticEngine.sealImpression();
    setState(() => _isSealed = true);
    await _sealCtrl.forward();

    final text = _reflectionCtrl.text.trim();
    if (text.isNotEmpty) {
      try {
        ref.read(journalProvider.notifier).addMemoir(
          title: 'Evening Reflection · ${DateLabels.dateOnly(DateTime.now())}',
          excerpt: text,
          mood: 'Zen Peace',
        );
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop();
      AppToastEngine().notify(
        title: '🌙 Day Sealed in Sanctuary',
        message: 'Your daily loops are closed. Rest well and wake to a clean slate.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFFAF7F0) : const Color(0xFF1C1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    const terracotta = Color(0xFFD9725B);
    const gold = Color(0xFFD4AF37);
    const sage = Color(0xFF8FA878);

    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final expenses = ref.watch(expensesProvider).expenses;
    final settings = ref.watch(appSettingsProvider);

    final now = DateTime.now();
    final todayKey = DateLabels.dayKey(now);

    final completedTasksToday = tasks.where((t) => t.completed).length;
    final completedHabitsToday = habits.where((h) => h.completedDays.contains(todayKey)).length;
    final expensesToday = expenses
        .where((e) => DateLabels.dayKey(e.spentAt) == todayKey)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF141210) : const Color(0xFFFAF8F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: gold.withValues(alpha: 0.35), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.moon, size: 16, color: gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY SHUTDOWN RITUAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: gold,
                          ),
                        ),
                        Text(
                          'Close Your Day with Peace',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(LucideIcons.x, size: 16, color: subtextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Velocity Indicator Badges
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: LucideIcons.checkSquare,
                      val: '$completedTasksToday',
                      label: 'Tasks Done',
                      color: terracotta,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: LucideIcons.flame,
                      val: '${settings.activeStreak}D',
                      label: 'Streak Safe',
                      color: gold,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: LucideIcons.repeat,
                      val: '$completedHabitsToday',
                      label: 'Habits Done',
                      color: sage,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: LucideIcons.dollarSign,
                      val: '\$${expensesToday.toStringAsFixed(0)}',
                      label: 'Today Spend',
                      color: const Color(0xFFC88552),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1-Question Micro Reflection Prompt
              Text(
                'ONE-SENTENCE REFLECTION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: terracotta,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'What was the single most meaningful moment or victory today?',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reflectionCtrl,
                style: GoogleFonts.dmSans(color: primaryText, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Finished the project proposal, enjoyed quiet morning coffee...',
                  hintStyle: GoogleFonts.dmSans(color: subtextColor.withValues(alpha: 0.7), fontSize: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF201D1A) : const Color(0xFFF0ECE4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Animated Wax Seal Stamp Button
              AnimatedBuilder(
                animation: _sealCtrl,
                builder: (context, child) {
                  final scale = 1.0 - (0.08 * _sealCtrl.value);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1.0),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _isSealed ? null : _sealTheDay,
                  icon: Icon(_isSealed ? LucideIcons.check : LucideIcons.stamp, size: 16),
                  label: Text(
                    _isSealed ? 'SEALED & COMPLETE' : 'SEAL THE DAY & REST',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String val,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.bodoniModa(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
