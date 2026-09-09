/// Multi-Currency Offline Forex Engine
/// Provides an embedded cache of global fiat and precious metal exchange rates
/// for completely air-gapped travel and group expense settlement calculations.
class CurrencyRate {
  final String code;
  final String symbol;
  final String name;
  final double rateToUsd; // Relative to 1 USD base

  const CurrencyRate({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToUsd,
  });
}

class OfflineForexEngine {
  static final OfflineForexEngine _instance = OfflineForexEngine._internal();
  factory OfflineForexEngine() => _instance;
  OfflineForexEngine._internal();

  static const Map<String, CurrencyRate> _rates = {
    'USD': CurrencyRate(code: 'USD', symbol: '\$', name: 'US Dollar', rateToUsd: 1.0),
    'EUR': CurrencyRate(code: 'EUR', symbol: '€', name: 'Euro', rateToUsd: 0.92),
    'GBP': CurrencyRate(code: 'GBP', symbol: '£', name: 'British Pound', rateToUsd: 0.79),
    'INR': CurrencyRate(code: 'INR', symbol: '₹', name: 'Indian Rupee', rateToUsd: 83.5),
    'JPY': CurrencyRate(code: 'JPY', symbol: '¥', name: 'Japanese Yen', rateToUsd: 154.2),
    'CHF': CurrencyRate(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', rateToUsd: 0.90),
    'AED': CurrencyRate(code: 'AED', symbol: 'AED', name: 'UAE Dirham', rateToUsd: 3.67),
    'SGD': CurrencyRate(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', rateToUsd: 1.35),
    'XAU': CurrencyRate(code: 'XAU', symbol: 'oz', name: 'Gold Ounce', rateToUsd: 0.00041),
  };

  Map<String, CurrencyRate> get availableCurrencies => _rates;

  /// Converts any amount from one currency to another completely offline
  double convert({
    required double amount,
    required String fromCode,
    required String toCode,
  }) {
    final fromRate = _rates[fromCode.toUpperCase()]?.rateToUsd ?? 1.0;
    final toRate = _rates[toCode.toUpperCase()]?.rateToUsd ?? 1.0;

    // Convert from source to USD base, then to target currency
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

  String formatAmount(double amount, String currencyCode) {
    final cur = _rates[currencyCode.toUpperCase()];
    final symbol = cur?.symbol ?? currencyCode;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
