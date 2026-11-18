import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/state/sanctuary_state.dart';

class BudgetEnvelopesWidget extends ConsumerWidget {
  final String currencySymbol;

  const BudgetEnvelopesWidget({super.key, this.currencySymbol = '₹'});

  IconData _getEnvelopeIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dining') || lower.contains('food') || lower.contains('coffee')) {
      return LucideIcons.utensils;
    } else if (lower.contains('grocer') || lower.contains('home')) {
      return LucideIcons.shoppingBag;
    } else if (lower.contains('shop') || lower.contains('wardrobe') || lower.contains('style')) {
      return LucideIcons.shirt;
    } else if (lower.contains('travel') || lower.contains('flight') || lower.contains('hotel')) {
      return LucideIcons.plane;
    } else if (lower.contains('sub') || lower.contains('bill') || lower.contains('tech')) {
      return LucideIcons.repeat;
    }
    return LucideIcons.wallet;
  }

  void _showAddEnvelopeDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF141211) : Colors.white;
        final border = isDark ? const Color(0xFF282421) : const Color(0xFFE8DFD7);
        final textColor = isDark ? const Color(0xFFF5EFEB) : const Color(0xFF1A1817);
        final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);
        const terracotta = Color(0xFF8E2433);

        return AlertDialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: border),
          ),
          title: Text(
            'New Category Budget',
            style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Dining & Coffee, Groceries',
                  labelStyle: TextStyle(color: subtextColor, fontSize: 13),
                  hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.5), fontSize: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: terracotta)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Monthly Limit ($currencySymbol)',
                  hintText: 'e.g. 250',
                  labelStyle: TextStyle(color: subtextColor, fontSize: 13),
                  hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.5), fontSize: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: terracotta)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: subtextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (name.isNotEmpty && amount > 0) {
                  ref.read(budgetEnvelopesProvider.notifier).addEnvelope(name: name, allocated: amount);
                  SanctuaryHapticEngine.sealImpression();
                  AppToastEngine().notify(
                    title: 'Category Budget Created',
                    message: '$name set with limit of $currencySymbol${amount.toInt()}',
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Limit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F2);
    final border = isDark ? const Color(0xFF262320) : const Color(0xFFE8DFD7);
    final textColor = isDark ? const Color(0xFFF5EFEB) : const Color(0xFF1A1817);
    final subtextColor = isDark ? const Color(0xFF9E958E) : const Color(0xFF7A7067);
    const terracotta = Color(0xFF8E2433);

    final envelopes = ref.watch(budgetEnvelopesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Category budget limits',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                  color: terracotta,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showAddEnvelopeDialog(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.plus, size: 13, color: terracotta),
                    const SizedBox(width: 4),
                    Text(
                      'Add Limit',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: terracotta,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (envelopes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.pieChart, size: 20, color: subtextColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No category spending limits set yet. Tap "Add Limit" to manage envelopes.',
                    style: TextStyle(fontSize: 12.5, color: subtextColor),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (final env in envelopes) ...[
                _EnvelopeCard(
                  envelope: env,
                  currencySymbol: currencySymbol,
                  icon: _getEnvelopeIcon(env.name),
                  cardBg: cardBg,
                  border: border,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  accentColor: terracotta,
                  onDelete: () {
                    SanctuaryHapticEngine.selection();
                    ref.read(budgetEnvelopesProvider.notifier).deleteEnvelope(env.id);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _EnvelopeCard extends StatelessWidget {
  final BudgetEnvelopeItem envelope;
  final String currencySymbol;
  final IconData icon;
  final Color cardBg;
  final Color border;
  final Color textColor;
  final Color subtextColor;
  final Color accentColor;
  final VoidCallback onDelete;

  const _EnvelopeCard({
    required this.envelope,
    required this.currencySymbol,
    required this.icon,
    required this.cardBg,
    required this.border,
    required this.textColor,
    required this.subtextColor,
    required this.accentColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = envelope.allocated > 0 ? (envelope.spent / envelope.allocated).clamp(0.0, 1.0) : 0.0;
    final isOver = envelope.spent > envelope.allocated;
    final barColor = isOver ? const Color(0xFFE53935) : (ratio > 0.85 ? const Color(0xFFB5505E) : accentColor);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: barColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      envelope.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isOver
                          ? 'Over budget by $currencySymbol${(envelope.spent - envelope.allocated).toStringAsFixed(0)}'
                          : '$currencySymbol${envelope.remaining.toStringAsFixed(0)} remaining of $currencySymbol${envelope.allocated.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isOver ? const Color(0xFFE53935) : subtextColor,
                        fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currencySymbol${envelope.spent.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(fontFeatures: const [FontFeature.tabularFigures()], 
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(LucideIcons.x, size: 14, color: subtextColor.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: subtextColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
