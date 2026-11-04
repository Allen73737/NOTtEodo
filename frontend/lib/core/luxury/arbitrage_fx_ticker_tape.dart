import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FxPair {
  final String symbol;
  final String pair;
  final double rate;
  final double changePercent;
  final bool isPositive;
  final String currencyCode;

  const FxPair({
    required this.symbol,
    required this.pair,
    required this.rate,
    required this.changePercent,
    required this.isPositive,
    required this.currencyCode,
  });
}

class ArbitrageFxTickerTape extends StatefulWidget {
  final ValueChanged<String>? onCurrencySelected;
  final String activeCurrencyCode;

  const ArbitrageFxTickerTape({
    super.key,
    this.onCurrencySelected,
    this.activeCurrencyCode = 'INR',
  });

  @override
  State<ArbitrageFxTickerTape> createState() => _ArbitrageFxTickerTapeState();
}

class _ArbitrageFxTickerTapeState extends State<ArbitrageFxTickerTape> {
  late final ScrollController _scrollController;
  Timer? _timer;

  static const List<FxPair> _pairs = [
    FxPair(symbol: '\$', pair: 'USD / INR', rate: 86.42, changePercent: 0.14, isPositive: true, currencyCode: 'USD'),
    FxPair(symbol: '€', pair: 'EUR / INR', rate: 93.18, changePercent: -0.08, isPositive: false, currencyCode: 'EUR'),
    FxPair(symbol: '£', pair: 'GBP / INR', rate: 109.85, changePercent: 0.31, isPositive: true, currencyCode: 'GBP'),
    FxPair(symbol: 'CHF', pair: 'CHF / INR', rate: 97.40, changePercent: 0.19, isPositive: true, currencyCode: 'USD'),
    FxPair(symbol: '¥', pair: 'JPY / INR', rate: 0.56, changePercent: -0.22, isPositive: false, currencyCode: 'USD'),
    FxPair(symbol: 'AED', pair: 'AED / INR', rate: 23.53, changePercent: 0.05, isPositive: true, currencyCode: 'USD'),
    FxPair(symbol: '₹', pair: 'INR / INR', rate: 1.00, changePercent: 0.00, isPositive: true, currencyCode: 'INR'),
    FxPair(symbol: 'S\$', pair: 'SGD / INR', rate: 64.12, changePercent: 0.11, isPositive: true, currencyCode: 'USD'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= maxExtent - 2) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(current + 1.0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF1C2224) : const Color(0xFFDDD6CA);

    // Quadruple items to create endless scrolling illusion
    final displayPairs = [..._pairs, ..._pairs, ..._pairs, ..._pairs];

    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          // Live Indicator Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : const Color(0xFFE8E3D8),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'FX ARBITRAGE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59),
                  ),
                ),
              ],
            ),
          ),

          // Marquee List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayPairs.length,
              itemBuilder: (context, index) {
                final pair = displayPairs[index];
                final isSelected = widget.activeCurrencyCode.toUpperCase() == pair.currencyCode.toUpperCase();

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onCurrencySelected?.call(pair.currencyCode);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: borderColor.withValues(alpha: 0.5))),
                      color: isSelected
                          ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2ECE1))
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pair.pair,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF16282C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pair.rate >= 10 ? pair.rate.toStringAsFixed(2) : pair.rate.toStringAsFixed(3),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF16282C),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${pair.isPositive ? '▲' : '▼'} ${(pair.changePercent.abs()).toStringAsFixed(2)}%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: pair.isPositive ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
