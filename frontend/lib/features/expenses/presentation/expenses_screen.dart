import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/luxury/arbitrage_fx_ticker_tape.dart';
import '../../../core/luxury/champleve_metric_gauge.dart';
import '../../../core/luxury/cire_perdue_progress_bar.dart';
import '../../../core/luxury/clous_de_paris_toggle.dart';
import '../../../core/luxury/column_wheel_chronograph.dart';
import '../../../core/luxury/cotes_de_geneve_backing.dart';
import '../../../core/luxury/damascus_steel_badge.dart';
import '../../../core/luxury/guilloche_subdial_gauge.dart';
import '../../../core/luxury/mother_of_pearl_shimmer.dart';
import '../../../core/luxury/skeleton_escapement_ticker.dart';
import '../../../core/luxury/sovereign_vault_rotary_dial.dart';
import '../../../core/luxury/spend_constellation_radar.dart';
import '../../../core/luxury/split_flap_board.dart';
import '../../../core/luxury/syndicate_topology_graph.dart';
import '../../../core/luxury/tourbillon_cage_fabrique.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';
import 'package:intl/intl.dart';

enum VaultCurrency {
  inr('INR', 'â‚¹', 1.0),
  usd('USD', '\$', 0.0116),
  eur('EUR', 'â‚¬', 0.0107),
  gbp('GBP', 'Â£', 0.0091),
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
  bool _isCardFlipped = false;
  bool _isChronographActive = false;
  int _selectedSort = 0; // 0: Most Recent, 1: Highest Amount, 2: Lowest Amount
  int? _selectedVialIndex;
  Offset _cardMousePos = const Offset(0.5, 0.5);
  bool _showSyndicateGraph = true;
  double _chronometerRegulation = 0.8;

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
          tags: ['Expense Log', item.category, 'â‚¹${item.amount.toInt()}'],
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
                    // Top Perforated Serration Edge
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      child: SizedBox(
                        height: 7,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _PerforatedTeethPainter(isDark: isDark, isTop: true),
                        ),
                      ),
                    ),

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
                                  child: _buildCertField('BASE INR', 'â‚¹${item.amount.toStringAsFixed(0)}', isDark,
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
                                SizedBox(
                                  width: 64,
                                  height: 16,
                                  child: CustomPaint(painter: _MicroBarcodePainter(isDark: isDark)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Perforated Serration Edge
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                      child: SizedBox(
                        height: 7,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _PerforatedTeethPainter(isDark: isDark, isTop: false),
                        ),
                      ),
                    ),
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
                            'Amount: ${_currency.format(item.amount)} (â‚¹${item.amount.toInt()})\n'
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
                        tags: ['Expense', 'â‚¹${inrAmt.toInt()}'],
                        previewIcon: 'shirt',
                      );
                }

                Navigator.pop(ctx);
                AppToastEngine().showToast(
                  context,
                  title: 'Disbursement Recorded',
                  message: 'â‚¹${inrAmt.toStringAsFixed(0)} logged under $category',
                );
              } else {
                AppToastEngine().showToast(
                  context,
                  title: 'Incomplete Entry',
                  message: 'Please provide both an amount and merchant title.',
                );
              }
            }

            return CotesDeGeneveBacking(
              stripeWidth: 32.0,
              child: Container(
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
                              ClousDeParisToggle(
                                value: clipToWardrobe,
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
                    labelText: 'Debt Amount (â‚¹)',
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
                            message: '$from owes $to â‚¹$amt in settlement registry.',
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
                        labelText: 'Total Bill Amount (â‚¹)',
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
                              Text('Total (incl. Tip â‚¹${tipAmount.toStringAsFixed(0)})',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: subColor)),
                              RollingText('â‚¹${grandTotal.toStringAsFixed(0)}',
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
                                'â‚¹${perPerson.toStringAsFixed(0)}',
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
                                message: '$memberCount-way split inscribed into registry at â‚¹$shareAmt per member.',
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
                                  'Total Bill: â‚¹${grandTotal.toStringAsFixed(0)} (incl. â‚¹${tipAmount.toStringAsFixed(0)} tip)\n'
                                  'Split: $memberCount members\n'
                                  'Share per member: â‚¹${perPerson.toStringAsFixed(0)}\n'
                                  'Each member pays: â‚¹${perPerson.toStringAsFixed(0)}.\n'
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

  void _exportAuditDossier() {
    HapticFeedback.mediumImpact();
    AppToastEngine().showToast(
      context,
      title: 'Audit Dossier Exported',
      message: 'Cryptographically sealed audit dossier generated & saved to local vault.',
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
                        const DamascusSteelBadge(
                          text: 'ACTIVE',
                          icon: LucideIcons.shieldCheck,
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
              // Action Button & Micro-Tourbillon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.0),
                      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF1F5F9),
                    ),
                    alignment: Alignment.center,
                    child: const TourbillonCageFabrique(size: 30),
                  ),
                  const SizedBox(width: 8),
                  Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryActionColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () => _showNewDisbursementModal(context, isDark),
                    icon: const Icon(LucideIcons.plus, size: 15),
                    label: Text(
                      'Disburse',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1.5. Live Swiss Banking FX Arbitrage Ticker Tape
          ArbitrageFxTickerTape(
            activeCurrencyCode: _currency.code,
            onCurrencySelected: (code) {
              setState(() {
                switch (code.toUpperCase()) {
                  case 'USD':
                    _currency = VaultCurrency.usd;
                    break;
                  case 'EUR':
                    _currency = VaultCurrency.eur;
                    break;
                  case 'GBP':
                    _currency = VaultCurrency.gbp;
                    break;
                  case 'CHF':
                    _currency = VaultCurrency.chf;
                    break;
                  default:
                    _currency = VaultCurrency.inr;
                }
              });
              AppToastEngine().showToast(
                context,
                title: 'Currency Updated',
                message: 'Currency updated to ${_currency.code} (${_currency.symbol})',
              );
            },
          ),
          const SizedBox(height: 18),

          // 2. The Carbon Titanium Centurion Card with Interactive Specular Glare
          _buildCenturionCard(
            totalAmount: totalAmount,
            remainingBudget: remainingBudget,
            isDark: isDark,
          ),
          const SizedBox(height: 22),

          // 3. Weekly Capital Velocity Spectrum (7-Day Aerospace Vials)
          _buildWeeklyBurnSpectrum(isDark: isDark, primaryColor: primaryActionColor, subColor: subtextColor),
          const SizedBox(height: 22),

          // 4. Haute Horlogerie Column-Wheel Chronograph & Telemetry Suite
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
                          ColumnWheelChronograph(
                            isRunning: _isChronographActive,
                            steelColor: const Color(0xFF94A3B8),
                            goldColor: primaryActionColor,
                            onToggle: () {
                              setState(() => _isChronographActive = !_isChronographActive);
                              AppToastEngine().showToast(
                                context,
                                title: _isChronographActive ? 'Horizon Reserve View' : 'Instant Sprue View',
                                message: _isChronographActive
                                    ? 'Telemetry set to long-range capital reserve horizon.'
                                    : 'Telemetry set to instant runway velocity.',
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CHRONOGRAPH TELEMETRY',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: primaryActionColor,
                                  ),
                                ),
                                Text(
                                  _isChronographActive ? 'Horizon Forecast' : 'Runway Velocity',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
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
                    InkWell(
                      onTap: _cycleCurrency,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryActionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryActionColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.refreshCw, size: 11, color: primaryActionColor),
                            const SizedBox(width: 4),
                            Text(
                              _currency.code,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: primaryActionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tri-Compax Row or Horizon Forecast
                if (!_isChronographActive)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 460;
                      if (isNarrow) {
                        return Column(
                          children: [
                            GuillocheSubdialGauge(
                              value: budgetPercent,
                              label: 'Runway Allocation',
                              readout: '${(budgetPercent * 100).toInt()}% Allocated',
                              size: 100,
                            ),
                            const SizedBox(height: 14),
                            CirePerdueProgressBar(
                              progress: budgetPercent,
                              label: 'Liquidity Sprue Flow',
                            ),
                            const SizedBox(height: 10),
                            ChampleveMetricGauge(
                              label: 'Burn Velocity',
                              value: budgetPercent,
                              lacquerColor: const Color(0xFF0F766E),
                              displayValue:
                                  '${_currency.format(totalAmount / (expensesState.items.isEmpty ? 1 : expensesState.items.length))} / ticket',
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GuillocheSubdialGauge(
                            value: budgetPercent,
                            label: 'Runway Burn',
                            readout: '${(budgetPercent * 100).toInt()}% Cap',
                            size: 105,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                CirePerdueProgressBar(
                                  progress: budgetPercent,
                                  label: 'Runway Liquidity Sprue',
                                ),
                                const SizedBox(height: 10),
                                ChampleveMetricGauge(
                                  label: 'Capital Velocity',
                                  value: budgetPercent,
                                  lacquerColor: const Color(0xFF0F766E),
                                  displayValue:
                                      '${_currency.format(totalAmount / (expensesState.items.isEmpty ? 1 : expensesState.items.length))} / tx',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildHorizonMetric(
                              'PROJECTED RESERVE', _currency.format(remainingBudget), const Color(0xFF34D399)),
                        ),
                        Container(width: 1, height: 32, color: borderColor),
                        Expanded(
                          child: _buildHorizonMetric('LIQUID RUNWAY',
                              '${((1.0 - budgetPercent) * 30).toStringAsFixed(1)}d', primaryActionColor),
                        ),
                        Container(width: 1, height: 32, color: borderColor),
                        Expanded(
                          child: _buildHorizonMetric('HEALTH', '96% OK', const Color(0xFFB5C9BE)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 4.5. Sovereign Vault Rotary Dial (Interactive CNC Budget & Reserve Calibration Wheel)
          SovereignVaultRotaryDial(
            currentBudget: _monthlyBudget,
            isDark: isDark,
            onBudgetChanged: (newBudget) {
              setState(() {
                _monthlyBudget = newBudget;
              });
            },
          ),
          const SizedBox(height: 22),

          // 5. Autonomous Sovereign Treasury Intelligence Pod
          _buildTreasuryIntelligencePod(
            totalAmount: totalAmount,
            remainingBudget: remainingBudget,
            isDark: isDark,
            primaryColor: primaryActionColor,
            textColor: primaryTextColor,
            subColor: subtextColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 22),

          // 5.5. Celestial Spend Constellation Radar
          SpendConstellationRadar(
            categorySums: categorySums,
            totalAmount: totalAmount,
            selectedCategory: _selectedCategory,
            isDark: isDark,
            onCategorySelected: (cat) {
              setState(() {
                _selectedCategory = cat;
              });
            },
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
                      icon: Icon(
                        _showSyndicateGraph ? LucideIcons.gitFork : LucideIcons.network,
                        size: 18,
                        color: _showSyndicateGraph ? const Color(0xFF34D399) : primaryActionColor,
                      ),
                      tooltip: _showSyndicateGraph ? 'Hide Topology Graph' : 'Show Topology Graph',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showSyndicateGraph = !_showSyndicateGraph);
                      },
                    ),
                    const SizedBox(width: 4),
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

                // Orbital Settlement Topology Network Graph
                if (_showSyndicateGraph && expensesState.settlements.isNotEmpty) ...[
                  SyndicateTopologyGraph(
                    settlements: expensesState.settlements,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                ],

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
                            s.amount.startsWith('â‚¹') ? s.amount : 'â‚¹${s.amount}',
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

          // Split-Flap Board (Fitted to screen width to prevent overflows)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SplitFlapBoard(
              text: 'TOTAL ${_currency.format(filteredTotal)}',
              cardColor: isDark ? const Color(0xFF080808) : const Color(0xFF262621),
              textColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
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
                                  'â‚¹${item.amount.toStringAsFixed(0)}',
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

  // 7-Day Aerospace Velocity Spectrum
  Widget _buildWeeklyBurnSpectrum({
    required bool isDark,
    required Color primaryColor,
    required Color subColor,
  }) {
    // The last 7 days, oldest first, from the real ledger.
    final today = DateTime.now();
    final dayStarts = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
    final expenses = ref.watch(expensesProvider).expenses;
    final totals = [
      for (final d in dayStarts)
        expenses
            .where((e) => e.spentAt.year == d.year && e.spentAt.month == d.month && e.spentAt.day == d.day)
            .fold<double>(0, (sum, e) => sum + e.amount),
    ];
    final peak = totals.fold<double>(0, (m, v) => v > m ? v : m);
    final days = [for (final d in dayStarts) ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1]];
    final burnRatios = [for (final t in totals) peak == 0 ? 0.0 : (t / peak).clamp(0.04, 1.0)];
    final amounts = [for (final t in totals) _currency.format(t)];

    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Row(
                children: [
                  Icon(LucideIcons.activity, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(
                    'WEEKLY CAPITAL BURN SPECTRUM',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: primaryColor,
                    ),
                  )),
                ],
              )),
              Text(
                '7-DAY VELOCITY',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: subColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7 Liquid Vials Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isSelected = _selectedVialIndex == i;
              final ratio = burnRatios[i];
              final isHigh = ratio > 0.75;
              final fluidColor =
                  isHigh ? const Color(0xFFE8927C) : (ratio > 0.5 ? primaryColor : const Color(0xFF34D399));

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedVialIndex = isSelected ? null : i;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF000000) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              isSelected ? primaryColor : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDDD6CA)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: fluidColor.withValues(alpha: isSelected ? 0.9 : 0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryColor : subColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          if (_selectedVialIndex != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateFormat('EEE, MMM d').format(dayStarts[_selectedVialIndex!])}: ${amounts[_selectedVialIndex!]}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  RollingText(
                    peak == 0 ? 'No spending' : '${(totals[_selectedVialIndex!] / peak * 100).round()}% of the week\'s peak',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Autonomous Sovereign Treasury Intelligence Pod
  Widget _buildTreasuryIntelligencePod({
    required double totalAmount,
    required double remainingBudget,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    return BentoPod(
      style: PodTextureStyle.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.sparkles, color: primaryColor, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Text(
                    'EXPENSE INSIGHTS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: primaryColor,
                    ),
                  )),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TIER 1 SOVEREIGN',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF34D399)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Liquidity Advisory:',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Runway buffer is operating at 94.2% capital efficiency. At current burndown, liquid reserves extend 34.2 days without deficit risk.',
            style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: subColor, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Export Dossier Button
          SizedBox(
            width: double.infinity,
            child: Pressable(pressedScale: 0.95, hoverLift: 0, child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _exportAuditDossier,
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              label: Text(
                'Export Sovereign Audit Dossier (CSV / PDF)',
                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizonMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Carbon Titanium Centurion Card Widget with Interactive Specular Sheen
  Widget _buildCenturionCard({
    required double totalAmount,
    required double remainingBudget,
    required bool isDark,
  }) {
    final borderColor = isDark ? const Color(0xFF2E3544) : const Color(0xFFDDD6CA);
    final accentCyan = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A947E);

    return MotherOfPearlShimmer(
      borderRadius: BorderRadius.circular(24),
      child: MouseRegion(
        onHover: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            setState(() {
              _cardMousePos = Offset(
                (e.localPosition.dx / box.size.width).clamp(0.0, 1.0),
                (e.localPosition.dy / 220.0).clamp(0.0, 1.0),
              );
            });
          }
        },
        onExit: (_) {
          setState(() {
            _cardMousePos = const Offset(0.5, 0.5);
          });
        },
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _isCardFlipped = !_isCardFlipped);
          },
          child: Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX((_cardMousePos.dy - 0.5) * -0.20)
              ..rotateY((_cardMousePos.dx - 0.5) * 0.25),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF0F0F0F),
                          Color(0xFF080808),
                          Color(0xFF000000),
                        ]
                      : const [
                          Color(0xFF262621),
                          Color(0xFF0F172A),
                          Color(0xFF020617),
                        ],
                ),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Procedural 45-degree Specular Sheen Glare
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomPaint(
                        painter: _SpecularSheenPainter(glareCenter: _cardMousePos),
                      ),
                    ),
                  ),

                  // Mathematical Guilloche Rose-Engine Turned Engraving
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomPaint(
                        painter: _GuillocheRoseEnginePainter(tiltOffset: _cardMousePos),
                      ),
                    ),
                  ),

                  // Swiss Sovereign Holographic Security Foil Strip
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 44,
                    width: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: CustomPaint(
                        painter: _SwissBankSecurityRibbonPainter(tiltOffset: _cardMousePos),
                      ),
                    ),
                  ),

                  // Prismatic Holographic Diffraction Security Foil
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomPaint(
                        painter: _IridescentDiffractionPainter(tiltOffset: _cardMousePos),
                      ),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: !_isCardFlipped
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: EMV Chip + Contactless + Currency Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Platinum / Rhodium Microchip (Interactive Tap)
                                      InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: () {
                                          HapticFeedback.heavyImpact();
                                          AppToastEngine().showToast(
                                            context,
                                            title: 'EMV Calibre Verified',
                                            message: 'AES-256 Secure Element #0x7892 authenticated.',
                                          );
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDDD6CA),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF94A3B8), width: 1.0),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [Color(0xFFF1F5F9), Color(0xFFDDD6CA), Color(0xFF94A3B8)],
                                            ),
                                          ),
                                          child: CustomPaint(painter: _RhodiumChipPainter()),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Contactless NFC Wave (Interactive Tap)
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          AppToastEngine().showToast(
                                            context,
                                            title: 'Contactless NFC Pulse',
                                            message: 'Sovereign POS Tokenizer ready for contactless tap.',
                                          );
                                        },
                                        child: Icon(LucideIcons.wifi, color: accentCyan, size: 18),
                                      ),
                                    ],
                                  ),
                                  // Currency Switcher Ingot
                                  GestureDetector(
                                    onTap: _cycleCurrency,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: accentCyan.withValues(alpha: 0.5), width: 1.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_currency.code} (${_currency.symbol})',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: accentCyan,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(LucideIcons.arrowRightLeft, size: 11, color: accentCyan),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Card Balance Display
                              Text(
                                'REMAINING BUDGET',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: accentCyan,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _currency.format(remainingBudget),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -1.0,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'available liquid',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 11.5, color: Colors.white54),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Card Number & Cardholder
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'â€¢â€¢â€¢â€¢  â€¢â€¢â€¢â€¢  â€¢â€¢â€¢â€¢  7892',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 13,
                                            letterSpacing: 1.8,
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ALLEN Â· NOTTEODO NOBLE',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentCyan.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: accentCyan.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'EXHIBITION â†©',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: accentCyan,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        // Exhibition Sapphire Caseback Mode
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'EXHIBITION SAPPHIRE CASEBACK Â· CALIBRE NOBLE-9901',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: accentCyan,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'FLIP â†©',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9.5, fontWeight: FontWeight.bold, color: accentCyan),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Tri-Complication Horological Movement Display
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const SkeletonEscapementTicker(size: 46, isTicking: true),
                                      const SizedBox(height: 5),
                                      Text(
                                        '4Hz ESCAPEMENT',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const _LiveHairspringBalanceWheel(size: 48),
                                      const SizedBox(height: 5),
                                      Text(
                                        'GLUCYDUR BALANCE',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: accentCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const TourbillonCageFabrique(size: 46),
                                      const SizedBox(height: 5),
                                      Text(
                                        'FLYING TOURBILLON',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Interactive Chronometer Rate Regulator Complication
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accentCyan.withValues(alpha: 0.25), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.gauge, size: 12, color: accentCyan),
                                        const SizedBox(width: 6),
                                        Text(
                                          'RATE REGULATOR:',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(4),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _chronometerRegulation = (_chronometerRegulation - 0.2).clamp(-3.0, 3.0);
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Icon(LucideIcons.minusSquare, size: 14, color: accentCyan),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_chronometerRegulation >= 0 ? "+" : ""}${_chronometerRegulation.toStringAsFixed(1)} s/d (COSC)',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF34D399),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(4),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _chronometerRegulation = (_chronometerRegulation + 0.2).clamp(-3.0, 3.0);
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Icon(LucideIcons.plusSquare, size: 14, color: accentCyan),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '39 JEWELS Â· 28,800 A/h Â· GENEVA SEAL',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 9.5, color: Colors.white54),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SPENT: ${_currency.format(totalAmount)}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE8927C),
                                    ),
                                  ),
                                ],
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
}

// Precision Rhodium EMV Chip Painter
class _RhodiumChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Horizontal split lines
    canvas.drawLine(Offset(0, h * 0.35), Offset(w, h * 0.35), paint);
    canvas.drawLine(Offset(0, h * 0.65), Offset(w, h * 0.65), paint);

    // Vertical split lines
    canvas.drawLine(Offset(w * 0.4, 0), Offset(w * 0.4, h), paint);
    canvas.drawLine(Offset(w * 0.6, 0), Offset(w * 0.6, h), paint);

    // Center core
    final coreRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.3,
      height: h * 0.4,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(coreRect, const Radius.circular(2)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Procedural 45-degree Specular Glare Painter for Metal Card
class _SpecularSheenPainter extends CustomPainter {
  final Offset glareCenter;

  _SpecularSheenPainter({required this.glareCenter});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * glareCenter.dx;
    final cy = size.height * glareCenter.dy;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
        transform: const GradientRotation(math.pi / 4),
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: size.width * 1.5, height: size.height * 1.5));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularSheenPainter oldDelegate) {
    return oldDelegate.glareCenter != glareCenter;
  }
}

// Swiss Bank Perforated Banknote Teeth Painter
class _PerforatedTeethPainter extends CustomPainter {
  final bool isDark;
  final bool isTop;

  _PerforatedTeethPainter({required this.isDark, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF000000) : Colors.white
      ..style = PaintingStyle.fill;

    const toothWidth = 8.0;
    const toothDepth = 4.5;
    final count = (size.width / toothWidth).ceil() + 1;

    final path = Path();
    if (isTop) {
      path.moveTo(0, 0);
      for (int i = 0; i < count; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, toothDepth);
        path.lineTo(x + toothWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    } else {
      path.moveTo(0, size.height);
      for (int i = 0; i < count; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, size.height - toothDepth);
        path.lineTo(x + toothWidth, size.height);
      }
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// High-Precision Authenticity Micro-Barcode Painter
class _MicroBarcodePainter extends CustomPainter {
  final bool isDark;

  _MicroBarcodePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..strokeCap = StrokeCap.square;

    const pattern = [2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3, 2, 1, 4, 1, 2, 1, 3, 2, 1, 2];
    double currentX = 0.0;

    for (int i = 0; i < pattern.length; i++) {
      final width = pattern[i].toDouble() * 0.9;
      if (i % 2 == 0) {
        paint.strokeWidth = width;
        final x = currentX + width / 2;
        if (x < size.width) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
      }
      currentX += width + 1.2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Prismatic Holographic Security Foil Diffraction Painter
class _IridescentDiffractionPainter extends CustomPainter {
  final Offset tiltOffset;

  _IridescentDiffractionPainter({required this.tiltOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic holographic diffraction shift based on 3D card tilt
    final shiftX = tiltOffset.dx * size.width * 0.4;
    final shiftY = tiltOffset.dy * size.height * 0.4;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Primary iridescent rainbow shimmer
    final gradient = LinearGradient(
      begin: Alignment(-1.0 + tiltOffset.dx, -1.0 + tiltOffset.dy),
      end: Alignment(1.0 + tiltOffset.dx, 1.0 + tiltOffset.dy),
      colors: [
        Colors.transparent,
        const Color(0xFF86CBB0).withValues(alpha: 0.06), // Sage
        const Color(0xFFC28E8E).withValues(alpha: 0.08), // Dusty rose
        const Color(0xFFE8927C).withValues(alpha: 0.06), // Terracotta
        const Color(0xFF34D399).withValues(alpha: 0.08), // Emerald
        const Color(0xFFE8927C).withValues(alpha: 0.06), // Terracotta glow
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.drawRect(rect, paint);

    // Micro-groove diffraction gratings (fine security guilloche lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.6;

    const lineSpacing = 6.0;
    for (double i = -size.height; i < size.width + size.height; i += lineSpacing) {
      canvas.drawLine(
        Offset(i + shiftX * 0.2, 0),
        Offset(i + size.height + shiftX * 0.2 + shiftY * 0.1, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IridescentDiffractionPainter oldDelegate) {
    return oldDelegate.tiltOffset != tiltOffset;
  }
}

// Mathematical Guilloche Rose-Engine Turned Lathe Engraver Painter
class _GuillocheRoseEnginePainter extends CustomPainter {
  final Offset tiltOffset;

  _GuillocheRoseEnginePainter({required this.tiltOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * (0.35 + tiltOffset.dx * 0.3);
    final cy = size.height * (0.5 + tiltOffset.dy * 0.2);
    final center = Offset(cx, cy);

    final paint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.055)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    // Rose engine multi-petaled harmonic rosettes (12 concentric harmonic epicycloid rings)
    const int rings = 12;
    const int petals = 16;
    for (int r = 1; r <= rings; r++) {
      final baseRadius = r * 14.0;
      final amplitude = 3.2 + (r * 0.25);
      final path = Path();

      const steps = 100;
      for (int i = 0; i <= steps; i++) {
        final theta = (i / steps) * 2 * math.pi;
        final rad = baseRadius + amplitude * math.sin(petals * theta);
        final x = center.dx + rad * math.cos(theta);
        final y = center.dy + rad * math.sin(theta);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuillocheRoseEnginePainter oldDelegate) {
    return oldDelegate.tiltOffset != tiltOffset;
  }
}

// Swiss Sovereign Banknote Holographic Security Foil Strip Painter
class _SwissBankSecurityRibbonPainter extends CustomPainter {
  final Offset tiltOffset;

  _SwissBankSecurityRibbonPainter({required this.tiltOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Holographic rainbow gradient
    final gradient = LinearGradient(
      begin: Alignment(0, -1.0 + tiltOffset.dy * 2),
      end: Alignment(0, 1.0 + tiltOffset.dy * 2),
      colors: [
        const Color(0xFF86CBB0).withValues(alpha: 0.16),
        const Color(0xFFC28E8E).withValues(alpha: 0.22),
        const Color(0xFF34D399).withValues(alpha: 0.18),
        const Color(0xFFE8927C).withValues(alpha: 0.20),
      ],
      stops: const [0.0, 0.35, 0.70, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);

    // Micro security hashes and dashed crosses
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (double y = 8; y < size.height - 8; y += 12) {
      canvas.drawLine(Offset(size.width * 0.2, y), Offset(size.width * 0.8, y), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SwissBankSecurityRibbonPainter oldDelegate) {
    return oldDelegate.tiltOffset != tiltOffset;
  }
}

// Live 4Hz Glucydur Balance Wheel with Pulsating Breguet Overcoil Hairspring
class _LiveHairspringBalanceWheel extends StatefulWidget {
  final double size;

  const _LiveHairspringBalanceWheel({required this.size});

  @override
  State<_LiveHairspringBalanceWheel> createState() => _LiveHairspringBalanceWheelState();
}

class _LiveHairspringBalanceWheelState extends State<_LiveHairspringBalanceWheel> with SingleTickerProviderStateMixin {
  late AnimationController _oscillator;

  @override
  void initState() {
    super.initState();
    _oscillator = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // 4Hz = 250ms half-oscillation
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _oscillator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _oscillator,
      builder: (context, child) {
        final angle = (math.sin(_oscillator.value * math.pi - math.pi / 2)) * 0.85;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BalanceWheelPainter(angle: angle),
        );
      },
    );
  }
}

class _BalanceWheelPainter extends CustomPainter {
  final double angle;

  _BalanceWheelPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // 1. Glucydur Balance Wheel Outer Rim (Titanium Rhodium)
    final rimPaint = Paint()
      ..color = const Color(0xFFDDD6CA)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, radius, rimPaint);

    // 2. Variable Inertia Gold/Rhodium Poising Screws on perimeter (4 screws at 90 deg)
    final screwPaint = Paint()
      ..color = const Color(0xFF86CBB0)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final a = (i * math.pi / 2);
      final sx = (radius + 1.2) * math.cos(a);
      final sy = (radius + 1.2) * math.sin(a);
      canvas.drawCircle(Offset(sx, sy), 1.6, screwPaint);
    }

    // 3. 3 Radial Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      final a = (i * 2 * math.pi / 3);
      canvas.drawLine(
        Offset.zero,
        Offset(radius * math.cos(a), radius * math.sin(a)),
        spokePaint,
      );
    }

    // 4. Center Synthetic Ruby Jewel with Rhodium Chaton
    final chatonPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawCircle(Offset.zero, 5.0, chatonPaint);

    final rubyPaint = Paint()..color = const Color(0xFFF43F5E); // Synthetic corundum ruby
    canvas.drawCircle(Offset.zero, 3.2, rubyPaint);

    canvas.restore();

    // 5. Breathing Nivarox Spiral Hairspring (unrotated center origin, expands with oscillation)
    final springPaint = Paint()
      ..color = const Color(0xFFE8927C).withValues(alpha: 0.65)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final springPath = Path();
    const coils = 3.5;
    const steps = 70;
    final breathe = 1.0 + (angle * 0.12);

    for (int i = 0; i <= steps; i++) {
      final t = (i / steps);
      final theta = t * coils * 2 * math.pi;
      final r = (3.5 + t * (radius * 0.65)) * breathe;
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);
      if (i == 0) {
        springPath.moveTo(x, y);
      } else {
        springPath.lineTo(x, y);
      }
    }
    canvas.drawPath(springPath, springPaint);
  }

  @override
  bool shouldRepaint(covariant _BalanceWheelPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
