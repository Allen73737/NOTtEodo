import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/fluid_ui_effects.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  void _clipToWardrobe(ExpenseItem item) {
    ref.read(wardrobeProvider.notifier).addOutfit(
          title: item.title,
          category: 'Clipped from Expenses',
          vibe: 'Daily Casual',
          tags: ['Expense Log', item.category],
          previewIcon: 'shirt',
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF000000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E1E1E)),
        ),
        content: Row(
          children: [
            const Icon(LucideIcons.shirt, color: Color(0xFFE8927C), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '"${item.title}" clipped to Wardrobe lookbook catalog!',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewExpenseModal(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Clothing';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dialogBg = isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh;
            final textColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
            final borderColor = isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant;

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Log New Expense', style: GoogleFonts.bodoniModa(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : AppColors.onSurface, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Expense Title',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amtCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurfaceVariant),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Clothing', 'Food & Dining', 'Travel & Stay', 'Study & Books', 'Entertainment', 'Personal Care']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFE8927C) : AppColors.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                          if (titleCtrl.text.trim().isNotEmpty && amt > 0) {
                            ref.read(expensesProvider.notifier).addExpense(
                                  title: titleCtrl.text.trim(),
                                  amount: amt,
                                  category: category,
                                  isClippedToWardrobe: category == 'Clothing',
                                );
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Add Entry to Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

    final expensesState = ref.watch(expensesProvider);
    final totalAmount = expensesState.items.fold<double>(0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PERSONAL LEDGER & SETTLEMENT', style: AppTypography.labelSm),
                    const SizedBox(height: 4),
                    Text(
                      'Expenses & Splitter',
                      style: GoogleFonts.bodoniModa(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _showNewExpenseModal(context, isDark),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('+ Add Entry', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Perforated Receipt Slip Pod
          BentoPod(
            style: PodTextureStyle.receipt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECEIPT SLIP #8492',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryTextColor),
                    ),
                    Text('AUG 24, 2026', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
                  ],
                ),
                const Divider(height: 20, color: AppColors.outlineVariant),

                if (expensesState.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No logged expenses on this slip yet.', style: GoogleFonts.dmSans(fontStyle: FontStyle.italic, color: subtextColor)),
                  )
                else
                  ...expensesState.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _receiptLine(item, isDark, primaryTextColor, subtextColor, accentColor),
                      )),

                const Divider(height: 20, color: AppColors.outlineVariant),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('||| | |||| | ||| |||| | | |||', style: GoogleFonts.libreBarcode39Text(fontSize: 24, color: primaryTextColor.withValues(alpha: 0.5))),
                    Text('TOTAL: ₹${totalAmount.toStringAsFixed(0)}', style: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Group Expense Settlement Card
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GROUP EXPENSE SETTLEMENT', style: AppTypography.labelSm),
                Text('Goa Trip 2026', style: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 4),
                Text('Members: Allen, Rahul, Arun, Joel', style: AppTypography.bodyMd.copyWith(fontSize: 12, color: subtextColor)),
                const SizedBox(height: 14),

                Text('SIMPLIFIED SETTLEMENT TOKENS', style: AppTypography.labelSm.copyWith(color: accentColor)),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expensesState.settlements.length,
                  separatorBuilder: (context, idx) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final s = expensesState.settlements[idx];
                    final bool isSettled = s.isSettled;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSettled
                            ? accentColor.withValues(alpha: 0.1)
                            : (isDark ? const Color(0xFF000000) : AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSettled
                              ? accentColor.withValues(alpha: 0.3)
                              : (isDark ? const Color(0xFF1E1E1E) : Colors.black.withValues(alpha: 0.05)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${s.from} ➔ ${s.to}',
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Text(s.amount.startsWith('₹') ? s.amount : '₹${s.amount}', style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor)),
                              const SizedBox(width: 10),
                              BouncyTouchEffect(
                                pressedScale: 0.90,
                                onTap: () {
                                  ref.read(expensesProvider.notifier).toggleSettlement(s.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSettled ? accentColor : (isDark ? const Color(0xFF2E2E2E) : AppColors.primary),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSettled ? '✓ SETTLED' : 'Settle Up',
                                    style: GoogleFonts.dmSans(fontSize: 10, color: isSettled && isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptLine(
    ExpenseItem item,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor), overflow: TextOverflow.ellipsis),
              Text('${item.category} · ${item.date}', style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${item.amount.toStringAsFixed(0)}', style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor)),
            if (item.category.toLowerCase().contains('cloth') || item.category.toLowerCase().contains('wardrobe'))
              GestureDetector(
                onTap: () => _clipToWardrobe(item),
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    border: Border.all(color: accentColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shirt, size: 10, color: accentColor),
                      const SizedBox(width: 4),
                      Text('+ Clip to Wardrobe', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
