import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';

enum VaultCurrency {
  inr('INR', '₹', 1.0),
  usd('USD', r'$', 0.0116),
  eur('EUR', '€', 0.0107),
  gbp('GBP', '£', 0.0091),
  chf('CHF', 'CHF', 0.0103);

  final String code;
  final String symbol;
  final double inrRate;

  const VaultCurrency(this.code, this.symbol, this.inrRate);

  String format(double inrAmount) {
    final converted = inrAmount * inrRate;
    if (this == VaultCurrency.inr) {
      return '$symbol${converted.toStringAsFixed(0)}';
    } else {
      return '$symbol${converted.toStringAsFixed(2)}';
    }
  }
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _monthlyBudget = 25000.0;
  VaultCurrency _currency = VaultCurrency.inr;
  int _selectedSort = 0; // 0: Most Recent, 1: Highest Amount, 2: Lowest Amount

  static const List<String> _categories = [
    'All',
    'Clothing',
    'Food & Dining',
    'Travel & Stay',
    'Study & Books',
    'General',
  ];

  static const List<String> _sortLabels = [
    'Most Recent',
    'Highest Amount',
    'Lowest Amount',
  ];

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'clothing':
      case 'wardrobe':
        return LucideIcons.shirt;
      case 'food & dining':
      case 'food':
      case 'dining':
        return LucideIcons.utensils;
      case 'travel & stay':
      case 'travel':
        return LucideIcons.plane;
      case 'study & books':
      case 'study':
      case 'books':
        return LucideIcons.bookOpen;
      default:
        return LucideIcons.creditCard;
    }
  }

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'clothing':
        return isDark ? const Color(0xFFE8927C) : const Color(0xFFBE185D);
      case 'food & dining':
        return isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
      case 'travel & stay':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
      case 'study & books':
        return isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    }
  }

  void _cycleCurrency() {
    HapticFeedback.selectionClick();
    setState(() {
      final nextIndex = (_currency.index + 1) % VaultCurrency.values.length;
      _currency = VaultCurrency.values[nextIndex];
    });
    AppToastEngine().showToast(
      context,
      title: 'Currency Updated',
      message: 'Currency set to ${_currency.code} (${_currency.symbol})',
    );
  }

  void _cycleSort() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSort = (_selectedSort + 1) % _sortLabels.length;
    });
    AppToastEngine().showToast(
      context,
      title: 'Ledger Sorted',
      message: 'Active sorting: ${_sortLabels[_selectedSort]}',
    );
  }

  void _clipToWardrobe(ExpenseItem item) {
    HapticFeedback.mediumImpact();
    ref.read(wardrobeProvider.notifier).addOutfit(
          title: item.title,
          category: 'Treasury Lookbook',
          vibe: 'Bespoke Curated',
          tags: ['Expense Log', item.category, '₹${item.amount.toInt()}'],
          previewIcon: 'shirt',
        );

    AppToastEngine().showToast(
      context,
      title: 'Provenance Clipped',
      message: '"${item.title}" added to your curated Wardrobe Lookbook.',
    );
  }

  void _inspectTransaction(BuildContext context, ExpenseItem item, bool isDark) {
    HapticFeedback.selectionClick();
    final accent = _getCategoryColor(item.category, isDark);
    final titaniumPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
    final titaniumSecondary = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF475569);
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.15),
                blurRadius: 36,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.0),
                          ),
                          child: Icon(_getCategoryIcon(item.category), color: accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRANSACTION RECORD',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.8,
                                  color: titaniumSecondary,
                                ),
                              ),
                              Text(
                                'Certificate of Expense',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: titaniumPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: titaniumSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Swiss Bank Perforated Provenance Certificate
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 7),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: titaniumPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _currency.format(item.amount),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'TX: 0x${item.id.hashCode.toRadixString(16).padLeft(8, '0').toUpperCase()} Â· DATE: ${item.dateLong}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                              color: titaniumSecondary,
                            ),
                          ),
                          const Divider(height: 22, thickness: 0.8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: _buildCertField(
                                      'CATEGORY', item.category, isDark, titaniumSecondary, titaniumPrimary)),
                              Expanded(
                                  child: _buildCertField('BASE INR', '₹${item.amount.toStringAsFixed(0)}', isDark,
                                      titaniumSecondary, titaniumPrimary)),
                              Expanded(
                                  child: _buildCertField(
                                      'STATUS', 'CLEARED', isDark, titaniumSecondary, const Color(0xFF34D399),
                                      isAccent: true)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Authenticity Security Stamp & Barcode
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF000000) : const Color(0xFFEDF2F7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF34D399)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'NOTTEODO TREASURY AUDIT SEAL',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        color: isDark ? const Color(0xFFDDD6CA) : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 64, height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 7),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clipToWardrobe(item);
                      },
                      icon: const Icon(LucideIcons.shirt, size: 16),
                      label: Text(
                        'Clip to Lookbook',
                        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    )),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Edit expense',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      openEntryEditor(context, EntryKind.expense, editing: item);
                    },
                    icon: Icon(LucideIcons.pencil, size: 16, color: titaniumSecondary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Copy Receipt Certificate',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: 'ðŸ“œ NOTTEODO SOVEREIGN CERTIFICATE OF EXPENSE\n'
                            'Title: ${item.title}\n'
                            'Category: ${item.category}\n'
                            'Amount: ${_currency.format(item.amount)} (₹${item.amount.toInt()})\n'
                            'Provenance TX: 0x${item.id.hashCode.toRadixString(16).padLeft(8, '0').toUpperCase()}\n'
                            'Date: ${item.dateLong}\n'
                            'Audit Status: SECURED & CLEARED BY TREASURY VAULT',
                      ));
                      AppToastEngine().showToast(
                        context,
                        title: 'Certificate Copied',
                        message: 'Cryptographic receipt text copied to clipboard.',
                      );
                    },
                    icon: Icon(LucideIcons.copy, size: 16, color: titaniumSecondary),
                  ),
                  const SizedBox(width: 8),
                  Pressable(pressedScale: 0.95, hoverLift: 0, child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE8927C),
                      side: const BorderSide(color: Color(0xFFE8927C), width: 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(expensesProvider.notifier).deleteExpense(item.id);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: Text(
                      'Delete',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertField(String label, String value, bool isDark, Color subColor, Color mainColor,
      {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: subColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showNewDisbursementModal(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Clothing';
    bool clipToWardrobe = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
            final sheetBg = isDark ? const Color(0xFF000000) : Colors.white;
            final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
            final subColor = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF64748B);
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0);
            final primaryActionColor = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);

            void executeDisbursement() {
              final rawAmt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              final inrAmt = rawAmt / _currency.inrRate;
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty && inrAmt > 0) {
                ref.read(expensesProvider.notifier).addExpense(
                      title: title,
                      amount: inrAmt,
                      category: category,
                    );

                if (category == 'Clothing' && clipToWardrobe) {
                  ref.read(wardrobeProvider.notifier).addOutfit(
                        title: title,
                        category: 'Disbursement Garment',
                        vibe: 'Daily Casual',
                        tags: ['Expense', '₹${inrAmt.toInt()}'],
                        previewIcon: 'shirt',
                      );
                }

                Navigator.pop(ctx);
                AppToastEngine().showToast(
                  context,
                  title: 'Disbursement Recorded',
                  message: '₹${inrAmt.toStringAsFixed(0)} logged under $category',
                );
              } else {
                AppToastEngine().showToast(
                  context,
                  title: 'Incomplete Entry',
                  message: 'Please provide both an amount and merchant title.',
                );
              }
            }

            return Container(
                decoration: BoxDecoration(
                  color: sheetBg.withValues(alpha: isDark ? 0.95 : 0.98),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                    top: BorderSide(color: primaryActionColor.withValues(alpha: 0.6), width: 1.5),
                    left: BorderSide(color: borderColor, width: 1.0),
                    right: BorderSide(color: borderColor, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.15),
                      blurRadius: 36,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CAPITAL ALLOCATION STUDIO',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.8,
                                    color: primaryActionColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Record Disbursement',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.x, color: subColor, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Amount Input Field
                      Text(
                        'DISBURSEMENT AMOUNT (${_currency.code})',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amtCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 8),
                            child: Text(
                              _currency.symbol,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryActionColor,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '0.00',
                          hintStyle: GoogleFonts.jetBrainsMono(color: subColor.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryActionColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Preset Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [100, 250, 500, 1000, 2500, 5000].map((preset) {
                          return ActionChip(
                            label: Text(
                              '+${_currency.symbol}$preset',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF1F5F9),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              final cur = double.tryParse(amtCtrl.text.trim()) ?? 0;
                              amtCtrl.text = (cur + preset).toInt().toString();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Description / Merchant
                      Text(
                        'MEMORANDUM / MERCHANT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleCtrl,
                        style: GoogleFonts.spaceGrotesk(fontSize: 14.5, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'e.g. Japanese Indigo Selvage Denim, Espresso...',
                          hintStyle: GoogleFonts.spaceGrotesk(color: subColor.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryActionColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Category Selector Pills
                      Text(
                        'CATEGORY PROVENANCE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.where((c) => c != 'All').map((c) {
                          final isSelected = category == c;
                          final catColor = _getCategoryColor(c, isDark);

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                category = c;
                                if (c == 'Clothing') clipToWardrobe = true;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? catColor : borderColor,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(c),
                                    size: 14,
                                    color: isSelected ? catColor : subColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? (isDark ? Colors.white : AppColors.primary) : subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Lookbook Auto-Sync Toggle for Clothing
                      if (category == 'Clothing')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: primaryActionColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryActionColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.shirt, color: primaryActionColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Auto-clip to Lookbook',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      'Sync garment to curated digital wardrobe',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 11, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: clipToWardrobe,
                                activeColor: primaryActionColor,
                                onChanged: (val) {
                                  setModalState(() => clipToWardrobe = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 22),

                      // Executive Record Button
                      SizedBox(
                        width: double.infinity,
                        child: Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryActionColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: executeDisbursement,
                          child: Text(
                            'Authorize & Seal Disbursement',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        )),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }

  void _showAddSettlementDialog(BuildContext context, bool isDark) {
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController(text: 'You');
    final amtCtrl = TextEditingController();

    showSanctuaryDialog(
      context: context,
      builder: (dialogCtx) {
        final dialogBg = isDark ? const Color(0xFF000000) : Colors.white;
        final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
        final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0);
        final accent = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);

        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNDICATE LIQUIDITY INSCRIBER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record Member Debt',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: fromCtrl,
                  style: GoogleFonts.spaceGrotesk(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Debtor Member (From)',
                    labelStyle: GoogleFonts.spaceGrotesk(color: accent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: toCtrl,
                  style: GoogleFonts.spaceGrotesk(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Creditor Principal (To)',
                    labelStyle: GoogleFonts.spaceGrotesk(color: accent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.jetBrainsMono(color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Debt Amount (₹)',
                    labelStyle: GoogleFonts.spaceGrotesk(color: accent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Pressable(pressedScale: 0.95, hoverLift: 0, child: TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: Colors.white54)),
                    )),
                    const SizedBox(width: 8),
                    Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final from = fromCtrl.text.trim();
                        final to = toCtrl.text.trim();
                        final amt = amtCtrl.text.trim();
                        if (from.isNotEmpty && to.isNotEmpty && amt.isNotEmpty) {
                          ref.read(expensesProvider.notifier).addSettlement(
                                from: from,
                                to: to,
                                amount: amt,
                              );
                          Navigator.pop(dialogCtx);
                          AppToastEngine().showToast(
                            context,
                            title: 'Debt Inscribed',
                            message: '$from owes $to ₹$amt in settlement registry.',
                          );
                        }
                      },
                      child: Text(
                        'Inscribe Split',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyndicateEqualizerDialog(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    final billCtrl = TextEditingController(text: '4800');
    int memberCount = 4;
    double tipPercent = 0.10; // 10%
    double taxPercent = 0.05; // 5%

    showSanctuaryDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogBg = isDark ? const Color(0xFF000000) : Colors.white;
          final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
          final subColor = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF64748B);
          final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA);
          final cyanAccent = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);

          final rawBill = double.tryParse(billCtrl.text) ?? 0.0;
          final tipAmount = rawBill * tipPercent;
          final taxAmount = rawBill * taxPercent;
          final grandTotal = rawBill + tipAmount + taxAmount;
          final perPerson = memberCount > 0 ? (grandTotal / memberCount) : 0.0;

          return Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: borderColor, width: 1.2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cyanAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cyanAccent.withValues(alpha: 0.3)),
                              ),
                              child: Icon(LucideIcons.divide, color: cyanAccent, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SYNDICATE BILL EQUALIZER',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: cyanAccent,
                                  ),
                                ),
                                Text(
                                  'Precision Bill Split & Tip',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: subColor),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bill Input
                    TextField(
                      controller: billCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Total Bill Amount (₹)',
                        labelStyle: GoogleFonts.spaceGrotesk(color: cyanAccent),
                        prefixIcon: Icon(LucideIcons.receipt, color: cyanAccent, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Member Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Syndicate Members',
                            style:
                                GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(LucideIcons.minusCircle,
                                  size: 20, color: memberCount > 2 ? cyanAccent : subColor.withValues(alpha: 0.4)),
                              onPressed: memberCount > 2 ? () => setDialogState(() => memberCount--) : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: cyanAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$memberCount Members',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13, fontWeight: FontWeight.bold, color: cyanAccent),
                              ),
                            ),
                            IconButton(
                              icon: Icon(LucideIcons.plusCircle,
                                  size: 20, color: memberCount < 12 ? cyanAccent : subColor.withValues(alpha: 0.4)),
                              onPressed: memberCount < 12 ? () => setDialogState(() => memberCount++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Gratuity Tip Selection
                    Text('Gratuity & Hospitality Tip',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold, color: subColor)),
                    const SizedBox(height: 6),
                    Row(
                      children: [0.0, 0.05, 0.10, 0.15, 0.20].map((rate) {
                        final isSel = (tipPercent - rate).abs() < 0.01;
                        final label = rate == 0.0 ? '0%' : '${(rate * 100).toInt()}%';
                        return Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => tipPercent = rate),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    isSel ? cyanAccent : (isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? cyanAccent : borderColor),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Tax & Surcharge Selection
                    Text('Tax & Surcharge Tier',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold, color: subColor)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        {'label': '0% Flat', 'rate': 0.0},
                        {'label': '5% GST', 'rate': 0.05},
                        {'label': '12% Standard', 'rate': 0.12},
                        {'label': '18% Luxury', 'rate': 0.18},
                      ].map((taxItem) {
                        final rate = taxItem['rate'] as double;
                        final label = taxItem['label'] as String;
                        final isSel = (taxPercent - rate).abs() < 0.01;
                        return Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => taxPercent = rate),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    isSel ? cyanAccent : (isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? cyanAccent : borderColor),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Calculated Result Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF080808) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total (incl. Tip ₹${tipAmount.toStringAsFixed(0)})',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: subColor)),
                              RollingText('₹${grandTotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                            ],
                          ),
                          const Divider(height: 18, thickness: 0.8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('EACH MEMBER PAYS',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cyanAccent,
                                      letterSpacing: 1.0)),
                              Text(
                                '₹${perPerson.toStringAsFixed(0)}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cyanAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final shareAmt = perPerson.toStringAsFixed(0);
                              final defaultMembers = ['Aarav', 'Rohan', 'Priya', 'Kabir', 'Maya', 'Zaid', 'Tara'];
                              for (int i = 0; i < (memberCount - 1); i++) {
                                final name = i < defaultMembers.length ? defaultMembers[i] : 'Member ${i + 2}';
                                ref.read(expensesProvider.notifier).addSettlement(
                                      from: name,
                                      to: 'You',
                                      amount: shareAmt,
                                    );
                              }
                              Navigator.pop(dialogCtx);
                              AppToastEngine().showToast(
                                context,
                                title: 'Syndicate Split Inscribed',
                                message: '$memberCount-way split inscribed into registry at ₹$shareAmt per member.',
                              );
                            },
                            icon: const Icon(LucideIcons.checkCheck, size: 16),
                            label: Text('Inscribe to Ledger',
                                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          )),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Copy Split Memo',
                          icon: Icon(LucideIcons.copy, color: cyanAccent),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: 'ðŸ›ï¸ NOTTEODO SYNDICATE EXPEDITION\n'
                                  'Total Bill: ₹${grandTotal.toStringAsFixed(0)} (incl. ₹${tipAmount.toStringAsFixed(0)} tip)\n'
                                  'Split: $memberCount members\n'
                                  'Share per member: ₹${perPerson.toStringAsFixed(0)}\n'
                                  'Each member pays: ₹${perPerson.toStringAsFixed(0)}.\n'
                                  'Provenance ID: #0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}',
                            ));
                            AppToastEngine().showToast(
                              context,
                              title: 'Split Memo Copied',
                              message: 'Formatted expedition split summary copied to clipboard.',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryActionColor = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);
    final surfaceColor = isDark ? const Color(0xFF0F1116) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222733) : const Color(0xFFE2E8F0);

    final expensesState = ref.watch(expensesProvider);
    final totalAmount = expensesState.items.fold<double>(0, (sum, e) => sum + e.amount);
    final remainingBudget = (_monthlyBudget - totalAmount).clamp(0.0, _monthlyBudget);
    final budgetPercent = (totalAmount / _monthlyBudget).clamp(0.0, 1.0);

    // Calculate category breakdown sums
    final Map<String, double> categorySums = {};
    for (final exp in expensesState.items) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }

    // Filter items
    var filteredExpenses = expensesState.items.where((e) {
      final matchesCat = _selectedCategory == 'All' || e.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    // Sort items
    if (_selectedSort == 1) {
      filteredExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_selectedSort == 2) {
      filteredExpenses.sort((a, b) => a.amount.compareTo(b.amount));
    }

    final filteredTotal = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      physics: SanctuaryMotionEngine.fluidPhysics,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Top Header (Overflow-Proof)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'LIFESTYLE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: primaryActionColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expenses',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Button
              Pressable(
                pressedScale: 0.95,
                hoverLift: 0,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _showNewDisbursementModal(context, isDark),
                  icon: const Icon(LucideIcons.plus, size: 15),
                  label: Text(
                    'Add Expense',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Clean Executive Treasury Overview Pod
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryActionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.wallet, size: 18, color: primaryActionColor),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY SPENDING',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: primaryActionColor,
                              ),
                            ),
                            Text(
                              _currency.format(totalAmount),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _cycleCurrency,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.coins, size: 13, color: primaryActionColor),
                            const SizedBox(width: 6),
                            Text(
                              _currency.code,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budgetPercent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budgetPercent > 1.0
                          ? const Color(0xFFE53935)
                          : (isDark ? const Color(0xFF86CBB0) : const Color(0xFF2E7D5A)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickStat(
                      label: 'TOTAL SPENT',
                      value: _currency.format(totalAmount),
                      color: primaryTextColor,
                      subtextColor: subtextColor,
                    ),
                    InkWell(
                      onTap: () => _showEditBudgetDialog(context, isDark),
                      borderRadius: BorderRadius.circular(8),
                      child: _buildQuickStat(
                        label: 'BUDGET ✎',
                        value: _currency.format(_monthlyBudget),
                        color: primaryActionColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                    _buildQuickStat(
                      label: 'REMAINING',
                      value: _currency.format(remainingBudget),
                      color: remainingBudget > 0
                          ? (isDark ? const Color(0xFF86CBB0) : const Color(0xFF2E7D5A))
                          : const Color(0xFFE53935),
                      subtextColor: subtextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // 6. Category Filter Ribbon
          Text(
            'CATEGORY CLASSIFICATION',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: primaryActionColor,
            ),
          ),
          const SizedBox(height: 10),

          // Instant Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.spaceGrotesk(fontSize: 13, color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Search ledger provenance or merchant...',
                hintStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: subtextColor.withValues(alpha: 0.6)),
                prefixIcon: Icon(LucideIcons.search, size: 16, color: subtextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                final count = c == 'All'
                    ? expensesState.items.length
                    : expensesState.items.where((e) => e.category.toLowerCase() == c.toLowerCase()).length;
                final catColor = _getCategoryColor(c, isDark);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = c);
                    },
                    avatar: c != 'All'
                        ? Icon(
                            _getCategoryIcon(c),
                            size: 13,
                            color: isSelected ? Colors.white : catColor,
                          )
                        : null,
                    label: Text('$c ($count)'),
                    labelStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : primaryTextColor,
                    ),
                    selectedColor: primaryActionColor,
                    backgroundColor: surfaceColor,
                    side: BorderSide(color: isSelected ? primaryActionColor : borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          // 7. Syndicate Settlement Engine (P2P Liquidity Topology)
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                            ),
                            child: const Icon(LucideIcons.users, color: Color(0xFF34D399), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'P2P LIQUIDITY TOPOLOGY',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: const Color(0xFF34D399),
                                  ),
                                ),
                                Text(
                                  'Shared Expense Ledger',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    IconButton(
                      icon: const Icon(LucideIcons.divide, size: 18, color: Color(0xFF34D399)),
                      tooltip: 'Syndicate Bill Equalizer',
                      onPressed: () => _showSyndicateEqualizerDialog(context, isDark),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(LucideIcons.userPlus, size: 18, color: primaryActionColor),
                      tooltip: 'Inscribe Syndicate Split',
                      onPressed: () => _showAddSettlementDialog(context, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 14),



                // Settlement Items (Pure RenderBox Column)
                Column(
                  children: expensesState.settlements.map((s) {
                    final bool isSettled = s.isSettled;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSettled
                            ? (isDark ? const Color(0xFF0F1713) : const Color(0xFFF0FDF4))
                            : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSettled ? const Color(0xFF34D399).withValues(alpha: 0.3) : borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSettled ? const Color(0xFF34D399) : primaryActionColor,
                                width: 1.2,
                              ),
                              color: isDark ? const Color(0xFF222837) : const Color(0xFFE2E8F0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.from.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${s.from} owes ${s.to}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.amount.startsWith('₹') ? s.amount : '₹${s.amount}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSettled ? const Color(0xFF34D399) : const Color(0xFFE8927C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(expensesProvider.notifier).toggleSettlement(s.id);
                              AppToastEngine().showToast(
                                context,
                                title: isSettled ? 'Settlement Reopened' : 'Wire Cleared',
                                message: 'Ledger entry for ${s.from} updated.',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSettled ? const Color(0xFF34D399) : primaryActionColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSettled ? 'âœ“ Cleared' : 'Settle Up',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSettled && isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 8. Solari di Udine Split-Flap Ticker Header & Sort Controller
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TRANSACTION LEDGER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: primaryActionColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: _cycleSort,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.arrowUpDown, size: 12, color: subtextColor),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabels[_selectedSort],
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, color: subtextColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${filteredExpenses.length} transactions · Total: ${_currency.format(filteredTotal)}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 9. Transaction List (Pure RenderBox Column)
          if (filteredExpenses.isEmpty)
            const EmptyState(
  icon: LucideIcons.inbox,
  title: 'No expenses here',
  message: 'Nothing matches this filter yet. Log a spend with the + button.',
)
          else
            Column(
              children: filteredExpenses.map((item) {
                final catColor = _getCategoryColor(item.category, isDark);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _inspectTransaction(context, item, isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Category Icon Box
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getCategoryIcon(item.category), color: catColor, size: 18),
                          ),
                          const SizedBox(width: 12),

                          // Title & Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        ' Â· ${item.date}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(fontSize: 11, color: subtextColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Amount & Currency Conversion
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currency.format(item.amount),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              if (_currency != VaultCurrency.inr)
                                Text(
                                  '₹${item.amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: subtextColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Icon(LucideIcons.chevronRight, size: 15, color: subtextColor.withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ].revealed(),
      ),
    );
  }


  Widget _buildQuickStat({
    required String label,
    required String value,
    required Color color,
    required Color subtextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: subtextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showEditBudgetDialog(BuildContext context, bool isDark) {
    final controller = TextEditingController(text: _monthlyBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Set Monthly Budget',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your target monthly budget for runway and spending tracking.',
              style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${_currency.symbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) {
                setState(() => _monthlyBudget = parsed);
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
