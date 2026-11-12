import 'dart:async';
import '../../../core/services/device_media_service.dart';
import '../../../core/services/ai_financial_service.dart';
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
import '../../../core/ai/ai_widgets.dart';
import '../../../core/ai/spending_insights.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/expense_pacing_graph_widget.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

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
  Timer? _searchDebounceTimer;
  double _monthlyBudget = 25000.0;
  VaultCurrency _currency = VaultCurrency.inr;
  int _selectedSort = 0; // 0: Most Recent, 1: Highest Amount, 2: Lowest Amount
  String? _aiSpendingInsight;
  bool _isLoadingAiInsight = false;

  @override
  void initState() {
    super.initState();
    _monthlyBudget = ref.read(appSettingsProvider).monthlyBudget ?? _monthlyBudget;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAiSpendingInsight();
    });
  }

  Future<void> _refreshAiSpendingInsight() async {
    if (_isLoadingAiInsight || !mounted) return;
    setState(() => _isLoadingAiInsight = true);
    final expenses = ref.read(expensesProvider).items;
    final insight = await AiFinancialService().generateSpendingInsights(
      expenses: expenses,
      monthlyBudget: _monthlyBudget,
      currencySymbol: _currency.symbol,
    );
    if (mounted) {
      setState(() {
        _aiSpendingInsight = insight;
        _isLoadingAiInsight = false;
      });
    }
  }

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
        return isDark ? const Color(0xFFC28E8E) : const Color(0xFFA87676);
      case 'food & dining':
        return isDark ? const Color(0xFFC88552) : const Color(0xFFA86C3E);
      case 'travel & stay':
        return isDark ? const Color(0xFF9E7B56) : const Color(0xFF7A5E3F);
      case 'study & books':
        return isDark ? const Color(0xFFD9725B) : const Color(0xFFC46851);
      default:
        return isDark ? const Color(0xFFC87A5B) : const Color(0xFF9E7B56);
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
          category: 'Wardrobe Expenses',
          vibe: 'Purchased',
          tags: ['Expense Log', item.category, '₹${item.amount.toInt()}'],
          previewIcon: 'shirt',
        );

    AppToastEngine().showToast(
      context,
      title: 'Added to Wardrobe',
      message: '"${item.title}" added to your Wardrobe.',
    );
  }

  void _inspectTransaction(BuildContext context, ExpenseItem item, bool isDark) {
    HapticFeedback.selectionClick();
    final accent = _getCategoryColor(item.category, isDark);
    final titaniumPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1917);
    final titaniumSecondary = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF635F59);
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
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
                  decoration: edBox(
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
                          decoration: edBox(
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.8,
                                  color: titaniumSecondary,
                                ),
                              ),
                              Text(
                                'Expense Details',
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

              // Digital Receipt Card
              Container(
                width: double.infinity,
                decoration: edBox(
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
                            'TX: 0x${item.id.hashCode.toRadixString(16).padLeft(8, '0').toUpperCase()} · DATE: ${item.dateLong}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
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
                                      'STATUS', 'CLEARED', isDark, titaniumSecondary, const Color(0xFFD9725B),
                                      isAccent: true)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Authenticity Security Stamp & Barcode
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: edBox(
                              color: isDark ? const Color(0xFF000000) : const Color(0xFFEDF2F7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFFD9725B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'NOTTEODO VERIFIED EXPENSE',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        color: isDark ? const Color(0xFFDDD6CA) : const Color(0xFF635F59),
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
                        backgroundColor: isDark ? const Color(0xFFD9725B) : const Color(0xFFC86446),
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
                        'Add to Wardrobe',
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
                    tooltip: 'Copy Receipt',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '🧾 NOTTEODO EXPENSE RECEIPT\n'
                            'Title: ${item.title}\n'
                            'Category: ${item.category}\n'
                            'Amount: ${_currency.format(item.amount)} (₹${item.amount.toInt()})\n'
                            'Transaction ID: 0x${item.id.hashCode.toRadixString(16).padLeft(8, '0').toUpperCase()}\n'
                            'Date: ${item.dateLong}\n'
                            'Status: Recorded & Verified',
                      ));
                      AppToastEngine().showToast(
                        context,
                        title: 'Receipt Copied',
                        message: 'Expense receipt copied to clipboard.',
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
            fontSize: 11,
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
    bool isRecurring = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
            final sheetBg = isDark ? const Color(0xFF000000) : Colors.white;
            final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1917);
            final subColor = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF635F59);
            final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
            final primaryActionColor = isDark ? const Color(0xFFE8927C) : const Color(0xFFC86446);

            void executeDisbursement() {
              final rawAmt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              final inrAmt = rawAmt / _currency.inrRate;
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty && inrAmt > 0) {
                ref.read(expensesProvider.notifier).addExpense(
                      title: title,
                      amount: inrAmt,
                      category: category,
                      recurring: isRecurring,
                    );

                if (category == 'Clothing' && clipToWardrobe) {
                  ref.read(wardrobeProvider.notifier).addOutfit(
                        title: title,
                        category: 'Purchased Clothing',
                        vibe: 'Daily Casual',
                        tags: ['Expense', '₹${inrAmt.toInt()}'],
                        previewIcon: 'shirt',
                      );
                }

                Navigator.pop(ctx);
                AppToastEngine().showToast(
                  context,
                  title: 'Expense Recorded',
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
                  border: Border.all(color: borderColor, width: 1.2),
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
                          decoration: edBox(
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
                                  'ADD EXPENSE',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.8,
                                    color: primaryActionColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'New Expense Entry',
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
                      const SizedBox(height: 14),

                      // AI Natural Language Quick Parsing Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: edBox(
                          color: primaryActionColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryActionColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.sparkles, size: 16, color: primaryActionColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'AI Quick Entry: "Dinner 1200" or paste receipt',
                                  hintStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: subColor.withValues(alpha: 0.5)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onSubmitted: (val) async {
                                  if (val.trim().isEmpty) return;
                                  final parsed = await AiFinancialService().parseNaturalLanguageExpense(val);
                                  setModalState(() {
                                    amtCtrl.text = parsed.amount > 0 ? parsed.amount.toStringAsFixed(0) : amtCtrl.text;
                                    titleCtrl.text = parsed.title;
                                    category = parsed.category;
                                  });
                                  HapticFeedback.mediumImpact();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Device Receipt Upload Button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                final media = await DeviceMediaService().pickImage();
                                if (media != null) {
                                  final parsed = await AiFinancialService().parseNaturalLanguageExpense(media.name);
                                  setModalState(() {
                                    if (titleCtrl.text.isEmpty) {
                                      titleCtrl.text = parsed.title;
                                      category = parsed.category;
                                    }
                                  });
                                  if (context.mounted) {
                                    AppToastEngine().showToast(
                                      context,
                                      title: 'Receipt Attached',
                                      message: 'Attached "${media.name}" from device.',
                                    );
                                  }
                                }
                              },
                              icon: Icon(LucideIcons.uploadCloud, size: 14, color: primaryActionColor),
                              label: Text(
                                'Upload Receipt from Device',
                                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: textColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Amount Input Field
                      Text(
                        'AMOUNT (${_currency.code})',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
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
                        'DESCRIPTION / MERCHANT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
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
                          hintText: 'e.g. Groceries, Team Lunch, Books...',
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
                        'CATEGORY',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
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
                              decoration: edBox(
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
                          decoration: edBox(
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
                                      'Auto-add to Wardrobe',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      'Add purchased clothing to your wardrobe',
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

                      // Monthly Recurring Toggle
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: edBox(
                          color: primaryActionColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryActionColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.repeat, color: primaryActionColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Recurring Expense',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Subscription, gym, utilities, or rent',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 11, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isRecurring,
                              activeColor: primaryActionColor,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                setModalState(() => isRecurring = val);
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
                            'Save Expense',
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

  /// Interactive Bill Splitter & Tip Calculator Modal
  void _showBillSplitterModal(BuildContext context, bool isDark) {
    final billCtrl = TextEditingController();
    int splitCount = 2;
    int tipPercent = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;
            final sheetBg = isDark ? const Color(0xFF000000) : Colors.white;
            final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1917);
            final subColor = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF635F59);
            final borderColor = isDark ? const Color(0xFF26221E) : const Color(0xFFE8E3D8);
            final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

            final billTotal = double.tryParse(billCtrl.text.trim()) ?? 0.0;
            final tipAmount = billTotal * (tipPercent / 100.0);
            final grandTotal = billTotal + tipAmount;
            final perPerson = splitCount > 0 ? (grandTotal / splitCount) : grandTotal;

            void recordMyShare() {
              if (perPerson <= 0) return;
              HapticFeedback.mediumImpact();
              ref.read(expensesProvider.notifier).addExpense(
                    title: 'Shared Bill (${splitCount}p split)',
                    amount: perPerson,
                    category: 'Food & Dining',
                    note: 'Bill: ${_currency.format(billTotal)} + Tip ${_currency.format(tipAmount)} ($tipPercent%)',
                  );
              Navigator.pop(ctx);
              AppToastEngine().showToast(
                context,
                title: 'Share Recorded',
                message: 'Your ${_currency.format(perPerson)} share added to Food & Dining.',
              );
            }

            void recordFriendOwed() {
              if (perPerson <= 0 || splitCount <= 1) return;
              HapticFeedback.mediumImpact();
              final friendShareTotal = grandTotal - perPerson;
              ref.read(expensesProvider.notifier).addSettlement(
                    from: 'Friends (${splitCount - 1}p)',
                    to: 'You',
                    amount: friendShareTotal.toStringAsFixed(0),
                  );
              Navigator.pop(ctx);
              AppToastEngine().showToast(
                context,
                title: 'Settlement Logged',
                message: '${_currency.format(friendShareTotal)} owed by friends added to Settlements.',
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: borderColor, width: 1.2),
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
                        decoration: edBox(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: edBox(
                            color: terracotta.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                          ),
                          child: Icon(LucideIcons.users, color: terracotta, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GROUP BILL & TIP SPLITTER',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: terracotta,
                                ),
                              ),
                              Text(
                                'Split Expenses Fairly',
                                style: GoogleFonts.bodoniModa(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Bill Total Input
                    Text(
                      'TOTAL BILL AMOUNT',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: billCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixText: '${_currency.symbol} ',
                        prefixStyle: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: terracotta),
                        hintText: '0.00',
                        hintStyle: GoogleFonts.jetBrainsMono(color: subColor.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF161412) : const Color(0xFFF6F2EB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: terracotta, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tip Percentage Chips
                    Text(
                      'TIP PERCENTAGE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [0, 5, 10, 15, 18, 20].map((t) {
                        final isSel = tipPercent == t;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => tipPercent = t);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: edBox(
                                color: isSel ? terracotta : (isDark ? const Color(0xFF161412) : const Color(0xFFF6F2EB)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSel ? terracotta : borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  '$t%',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // People Split Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUMBER OF PEOPLE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: subColor,
                              ),
                            ),
                            Text(
                              '$splitCount people sharing equally',
                              style: GoogleFonts.dmSans(fontSize: 12, color: subColor),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: splitCount > 1
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() => splitCount--);
                                    }
                                  : null,
                              icon: const Icon(LucideIcons.minusCircle, size: 20),
                              color: terracotta,
                            ),
                            Text(
                              '$splitCount',
                              style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            IconButton(
                              onPressed: splitCount < 20
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() => splitCount++);
                                    }
                                  : null,
                              icon: const Icon(LucideIcons.plusCircle, size: 20),
                              color: terracotta,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Results Summary Pod
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: edBox(
                        color: terracotta.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: terracotta.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal + Tip ($tipPercent%)', style: GoogleFonts.dmSans(fontSize: 12, color: subColor)),
                              Text(
                                '${_currency.format(billTotal)} + ${_currency.format(tipAmount)} = ${_currency.format(grandTotal)}',
                                style: GoogleFonts.jetBrainsMono(fontSize: 12, color: subColor),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'EACH PERSON OWES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: terracotta,
                                ),
                              ),
                              Text(
                                _currency.format(perPerson),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1-Tap Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: billTotal > 0 ? recordMyShare : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: terracotta),
                              foregroundColor: terracotta,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Record My Share',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                        ),
                        if (splitCount > 1) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: billTotal > 0 ? recordFriendOwed : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: terracotta,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Record Owed',
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  /// Financial Audit Report Export Modal
  void _showExportReportModal(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    final expensesState = ref.read(expensesProvider);
    final items = expensesState.items;
    final totalSpent = items.fold<double>(0, (sum, e) => sum + e.amount);

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Date,Title,Category,Amount,Currency,Recurring,Note');
    for (final e in items) {
      final safeTitle = e.title.replaceAll('"', '""');
      final safeNote = e.note.replaceAll('"', '""');
      csvBuffer.writeln('"${e.dateLong}","$safeTitle","${e.category}",${e.amount.toStringAsFixed(2)},"INR",${e.recurring},"$safeNote"');
    }

    final mdBuffer = StringBuffer();
    mdBuffer.writeln('# NOTtEodo Financial Audit Statement');
    mdBuffer.writeln('Generated: ${DateTime.now().toLocal().toString().split('.').first}');
    mdBuffer.writeln('Total Transactions: ${items.length}');
    mdBuffer.writeln('Total Spend: ${_currency.format(totalSpent)}\n');
    mdBuffer.writeln('## Itemized Ledger');
    for (final e in items) {
      final recMarker = e.recurring ? ' [Monthly Recurring]' : '';
      mdBuffer.writeln('- **${e.date}** · ${e.title}: ${_currency.format(e.amount)} (${e.category})$recMarker');
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final dialogBg = isDark ? const Color(0xFF141210) : Colors.white;
        final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1917);
        final subColor = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF635F59);
        final borderColor = isDark ? const Color(0xFF26221E) : const Color(0xFFE8E3D8);
        final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          title: Row(
            children: [
              Icon(LucideIcons.fileSpreadsheet, size: 20, color: terracotta),
              const SizedBox(width: 10),
              Text(
                'Financial Audit Export',
                style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export your entire financial ledger of ${items.length} transactions (${_currency.format(totalSpent)}) in standard portable formats.',
                style: GoogleFonts.dmSans(fontSize: 12.5, color: subColor, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: edBox(
                  color: terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: terracotta.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 16, color: terracotta),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Local Export • No telemetry or tracking.',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: terracotta),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Close', style: GoogleFonts.dmSans(color: subColor)),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: mdBuffer.toString()));
                Navigator.pop(dialogCtx);
                AppToastEngine().showToast(
                  context,
                  title: 'Markdown Statement Copied',
                  message: 'Formatted summary copied to clipboard.',
                );
              },
              icon: const Icon(LucideIcons.copy, size: 14),
              label: Text('Copy Markdown', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: terracotta,
                side: BorderSide(color: terracotta),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvBuffer.toString()));
                Navigator.pop(dialogCtx);
                AppToastEngine().showToast(
                  context,
                  title: 'CSV Export Copied',
                  message: 'Bank-compatible CSV copied to clipboard.',
                );
              },
              icon: const Icon(LucideIcons.download, size: 14),
              label: Text('Copy CSV', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Subscriptions & Monthly Commitments Inspector Modal
  void _showSubscriptionsModal(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    final expensesState = ref.read(expensesProvider);
    final recurring = expensesState.items.where((e) => e.recurring).toList();
    final monthlyTotal = recurring.fold<double>(0, (sum, e) => sum + e.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        final sheetBg = isDark ? const Color(0xFF000000) : Colors.white;
        final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1917);
        final subColor = isDark ? const Color(0xFFA6A6A6) : const Color(0xFF635F59);
        final borderColor = isDark ? const Color(0xFF26221E) : const Color(0xFFE8E3D8);
        final terracotta = isDark ? const Color(0xFFE8927C) : AppColors.secondary;

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.15),
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
                  decoration: edBox(color: borderColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: edBox(
                          color: terracotta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                        ),
                        child: Icon(LucideIcons.repeat, color: terracotta, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONTHLY OBLIGATIONS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: terracotta,
                            ),
                          ),
                          Text(
                            'Recurring Subscriptions',
                            style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 18, color: subColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total Commitment Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: edBox(
                  color: terracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Committed Monthly Overhead', style: GoogleFonts.dmSans(fontSize: 12.5, color: subColor)),
                    Text(
                      _currency.format(monthlyTotal),
                      style: GoogleFonts.jetBrainsMono(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (recurring.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No recurring subscriptions yet.\nToggle "Monthly Recurring" when adding rent or bills.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: subColor, height: 1.4),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: recurring.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = recurring[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: edBox(
                          color: isDark ? const Color(0xFF161412) : const Color(0xFFF7F3EC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    '${item.category} • Renews Monthly',
                                    style: GoogleFonts.dmSans(fontSize: 11.5, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _currency.format(item.amount),
                              style: GoogleFonts.jetBrainsMono(fontSize: 14.5, fontWeight: FontWeight.bold, color: terracotta),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
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
        final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1917);
        final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
        final accent = isDark ? const Color(0xFFE8927C) : const Color(0xFFC86446);

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
                  'ADD BILL SPLIT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record Split Balance',
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
                    labelText: 'Who owes (Name)',
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
                    labelText: 'Owed to (Name)',
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
                    labelText: 'Amount (₹)',
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
                            title: 'Split Added',
                            message: '$from owes $to ₹$amt.',
                          );
                        }
                      },
                      child: Text(
                        'Save Split',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
    final primaryActionColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final surfaceColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);

    final expensesState = ref.watch(expensesProvider);
    final today = DateTime.now();
    final totalAmount = expensesState.items
        .where((e) => e.spentAt.year == today.year && e.spentAt.month == today.month)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final insights = !ref.watch(appSettingsProvider.select((s) => s.smartSuggestions))
        ? const <Insight>[]
        : SpendingInsights.analyze(
      expensesState.items,
      now: today,
      monthlyBudget: _monthlyBudget,
      currency: _currency.symbol,
    );
    final remainingBudget = (_monthlyBudget - totalAmount).clamp(0.0, _monthlyBudget);
    final budgetPercent = (totalAmount / _monthlyBudget).clamp(0.0, 1.0);
    final recurringTotal = expensesState.items.where((e) => e.recurring).fold<double>(0, (sum, e) => sum + e.amount);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final daysLeft = (daysInMonth - today.day) + 1;
    final dailyAllowance = remainingBudget / (daysLeft > 0 ? daysLeft : 1);

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
                            fontSize: 11.5,
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
              // Executive Multi-Action Suite (Add, Split, Export)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pressable(
                    pressedScale: 0.95,
                    hoverLift: 0,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryActionColor,
                        side: BorderSide(color: primaryActionColor.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showBillSplitterModal(context, isDark),
                      icon: const Icon(LucideIcons.users, size: 13),
                      label: Text('Split', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                  ),
                  Pressable(
                    pressedScale: 0.95,
                    hoverLift: 0,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTextColor,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showExportReportModal(context, isDark),
                      icon: const Icon(LucideIcons.fileSpreadsheet, size: 13),
                      label: Text('Export', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                  ),
                  Pressable(
                    pressedScale: 0.95,
                    hoverLift: 0,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryActionColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showNewDisbursementModal(context, isDark),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: Text(
                        'Add Expense',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
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
                    Expanded(
                      child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: edBox(
                            color: primaryActionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.wallet, size: 18, color: primaryActionColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY SPENDING',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: primaryActionColor,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _currency.format(totalAmount),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ],
                    ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _cycleCurrency,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: edBox(
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
                          ? const Color(0xFFC0392B)
                          : (isDark ? const Color(0xFFE8927C) : const Color(0xFFC87A5B)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        label: 'SPENT',
                        value: _currency.format(totalAmount),
                        color: primaryTextColor,
                        subtextColor: subtextColor,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditBudgetDialog(context, isDark),
                        borderRadius: BorderRadius.circular(8),
                        child: _buildQuickStat(
                          label: 'BUDGET ✎',
                          value: _currency.format(_monthlyBudget),
                          color: primaryActionColor,
                          subtextColor: subtextColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildQuickStat(
                        label: 'REMAINING',
                        value: _currency.format(remainingBudget),
                        color: remainingBudget > 0
                            ? (isDark ? const Color(0xFFE8927C) : const Color(0xFFC87A5B))
                            : const Color(0xFFC0392B),
                        subtextColor: subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Daily Burn Rate Pacing & Monthly Recurring Commitments
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: edBox(
                          color: isDark ? const Color(0xFF141210) : const Color(0xFFF7F3EC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.flame, size: 14, color: primaryActionColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY ALLOWANCE',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: subtextColor,
                                    ),
                                  ),
                                  Text(
                                    '${_currency.format(dailyAllowance)} / day ($daysLeft days left)',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.5,
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
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showSubscriptionsModal(context, isDark),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: edBox(
                          color: isDark ? const Color(0xFF141210) : const Color(0xFFF7F3EC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryActionColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.repeat, size: 14, color: primaryActionColor),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SUBSCRIPTIONS',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: primaryActionColor,
                                  ),
                                ),
                                Text(
                                  _currency.format(recurringTotal),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // AI Treasury Intelligence Commentary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: edBox(
                    color: primaryActionColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryActionColor.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(LucideIcons.sparkles, size: 15, color: primaryActionColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'AI COMMENTARY',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: primaryActionColor,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _refreshAiSpendingInsight,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      LucideIcons.refreshCw,
                                      size: 11,
                                      color: subtextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _aiSpendingInsight ?? 'Analyzing your spending trends and budget pace...',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFD6D3D1) : const Color(0xFF44403C),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ExpensePacingGraphWidget(
            onAddExpense: () => _showNewDisbursementModal(context, isDark),
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 18),
            InsightsPanel(insights: insights, title: 'AI SPENDING INSIGHTS'),
          ],
          const SizedBox(height: 22),
          // 6. Category Filter Ribbon
          Text(
            'CATEGORIES & SEARCH',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: primaryActionColor,
            ),
          ),
          const SizedBox(height: 10),

          // Instant Search Bar
          Container(
            height: 44,
            decoration: edBox(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              onChanged: (val) {
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() => _searchQuery = val);
                  }
                });
              },
              style: GoogleFonts.spaceGrotesk(fontSize: 13, color: primaryTextColor),
              decoration: InputDecoration(
                hintText: 'Search expenses by merchant or note...',
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

          // 7. Bill Splits & Shared Balances
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
                            decoration: edBox(
                              color: primaryActionColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryActionColor.withValues(alpha: 0.4)),
                            ),
                            child: Icon(LucideIcons.users, color: primaryActionColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BILL SPLITS & SETTLEMENTS',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: primaryActionColor,
                                  ),
                                ),
                                Text(
                                  'Shared Bill Splits',
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
                      icon: Icon(LucideIcons.divide, size: 18, color: primaryActionColor),
                      tooltip: 'Split Bill Calculator',
                      onPressed: () => _showBillSplitterModal(context, isDark),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(LucideIcons.userPlus, size: 18, color: primaryActionColor),
                      tooltip: 'Add Split Balance',
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
                      decoration: edBox(
                        color: isSettled
                            ? (isDark ? const Color(0xFF161412) : const Color(0xFFF7F3EC))
                            : (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSettled ? primaryActionColor.withValues(alpha: 0.4) : borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: edBox(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSettled ? primaryActionColor : borderColor,
                                width: 1.2,
                              ),
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8),
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
                              color: isSettled ? primaryActionColor : const Color(0xFFE8927C),
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
                                title: isSettled ? 'Settlement Reopened' : 'Marked Settled',
                                message: 'Payment status for ${s.from} updated.',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: edBox(
                                color: isSettled ? primaryActionColor.withValues(alpha: 0.25) : primaryActionColor,
                                borderRadius: BorderRadius.circular(8),
                                border: isSettled ? Border.all(color: primaryActionColor) : null,
                              ),
                              child: Text(
                                isSettled ? '✓ Settled' : 'Settle Up',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSettled ? primaryActionColor : Colors.white,
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

          // 8. Transaction List Header & Sort Controller
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'TRANSACTIONS',
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
                  decoration: edBox(
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
                      decoration: edBox(
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
                            decoration: edBox(
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
                                        ' · ${item.date}',
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
                                    fontSize: 11,
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
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: subtextColor,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
                ref.read(appSettingsProvider.notifier).setMonthlyBudget(parsed);
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
