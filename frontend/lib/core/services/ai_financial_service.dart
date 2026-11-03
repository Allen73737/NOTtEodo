import 'dart:convert';
import '../enterprise/sanctuary_logger.dart';
import '../state/sanctuary_state.dart';
import 'groq_ai_service.dart';

class ParsedExpenseResult {
  final double amount;
  final String title;
  final String category;
  final String note;
  final bool isConfident;

  const ParsedExpenseResult({
    required this.amount,
    required this.title,
    required this.category,
    this.note = '',
    this.isConfident = true,
  });
}

class AiFinancialService {
  static final AiFinancialService _instance = AiFinancialService._internal();
  factory AiFinancialService() => _instance;
  AiFinancialService._internal();

  static const List<String> standardCategories = [
    'Food & Dining',
    'Clothing',
    'Travel & Stay',
    'Study & Books',
    'Shopping',
    'Home',
    'Health',
    'Transport',
    'Bills',
    'General',
  ];

  /// Parses natural language expense text into structured data.
  /// Example inputs:
  /// - "Spent 450 at Starbucks on coffee"
  /// - "Dinner with team 1400"
  /// - "Bought Uniqlo linen trousers for 2990 under clothing"
  /// - "Paid electricity bill 3200"
  Future<ParsedExpenseResult> parseNaturalLanguageExpense(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      return const ParsedExpenseResult(amount: 0, title: '', category: 'General', isConfident: false);
    }

    // Try AI parsing via Groq cascade
    if (GroqAiService().isConfigured) {
      try {
        final prompt = '''You are a financial parser. Extract expense information from the text into strict JSON.
Available categories: ${standardCategories.join(', ')}.

Return ONLY valid JSON matching this schema:
{
  "amount": number,
  "title": string,
  "category": string,
  "note": string
}

Input: "$cleanInput"''';

        final aiResult = await GroqAiService().ask(query: prompt, scope: 'Financial');
        final rawAnswer = aiResult.answer.trim();
        
        // Extract JSON substring if wrapped in markdown code blocks
        String jsonStr = rawAnswer;
        final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(rawAnswer);
        if (codeBlockMatch != null) {
          jsonStr = codeBlockMatch.group(1) ?? rawAnswer;
        }

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final amt = double.tryParse(parsed['amount']?.toString() ?? '0') ?? 0.0;
        final title = parsed['title']?.toString() ?? 'Expense';
        var cat = parsed['category']?.toString() ?? 'General';
        final note = parsed['note']?.toString() ?? '';

        // Match to closest standard category
        final matchedCat = standardCategories.firstWhere(
          (c) => c.toLowerCase() == cat.toLowerCase(),
          orElse: () => 'General',
        );

        if (amt > 0 && title.isNotEmpty) {
          return ParsedExpenseResult(
            amount: amt,
            title: title,
            category: matchedCat,
            note: note,
            isConfident: true,
          );
        }
      } catch (e) {
        SanctuaryLogger().warn('AiFinancialService', 'AI parsing error: $e. Falling back to heuristic.');
      }
    }

    // Resilient Local Deterministic Heuristic Fallback
    return _heuristicParse(cleanInput);
  }

  ParsedExpenseResult _heuristicParse(String text) {
    // 1. Extract amount (e.g. 450, 450.00, ₹450, $450)
    final amtMatch = RegExp(r'(?:₹|\$|€|£|rs\.?|inr)?\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false).firstMatch(text);
    double amount = 0.0;
    if (amtMatch != null) {
      amount = double.tryParse(amtMatch.group(1)?.replaceAll(',', '') ?? '0') ?? 0.0;
    }

    // 2. Identify Category
    final lower = text.toLowerCase();
    String category = 'General';
    if (lower.contains('food') || lower.contains('dinner') || lower.contains('lunch') || lower.contains('coffee') || lower.contains('starbucks') || lower.contains('cafe') || lower.contains('restaurant') || lower.contains('swiggy') || lower.contains('zomato')) {
      category = 'Food & Dining';
    } else if (lower.contains('cloth') || lower.contains('shirt') || lower.contains('denim') || lower.contains('shoes') || lower.contains('zara') || lower.contains('uniqlo') || lower.contains('suit')) {
      category = 'Clothing';
    } else if (lower.contains('flight') || lower.contains('hotel') || lower.contains('airbnb') || lower.contains('trip') || lower.contains('stay') || lower.contains('ticket')) {
      category = 'Travel & Stay';
    } else if (lower.contains('uber') || lower.contains('ola') || lower.contains('fuel') || lower.contains('petrol') || lower.contains('cab') || lower.contains('train') || lower.contains('metro')) {
      category = 'Transport';
    } else if (lower.contains('bill') || lower.contains('wifi') || lower.contains('electricity') || lower.contains('recharge') || lower.contains('rent')) {
      category = 'Bills';
    } else if (lower.contains('book') || lower.contains('course') || lower.contains('study') || lower.contains('tuition')) {
      category = 'Study & Books';
    }

    // 3. Clean up title
    String title = text
        .replaceAll(RegExp(r'(?:spent|paid|bought|purchased|for|at|on|under|inr|rs\.?|₹|\$)\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\d+(?:[.,]\d{1,2})?'), '')
        .trim();
    if (title.isEmpty) {
      title = '$category Expense';
    } else {
      // Capitalize first letter
      title = title[0].toUpperCase() + title.substring(1);
    }

    return ParsedExpenseResult(
      amount: amount,
      title: title,
      category: category,
      note: 'Auto-parsed from: "$text"',
      isConfident: amount > 0,
    );
  }

  /// Generates concise executive spending insights based on current expenses and budget.
  Future<String> generateSpendingInsights({
    required List<ExpenseItem> expenses,
    required double monthlyBudget,
    required String currencySymbol,
  }) async {
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month).toList();
    final totalSpent = currentMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final remainingBudget = (monthlyBudget - totalSpent).clamp(0.0, monthlyBudget);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (daysInMonth - now.day) + 1;
    final dailyAllowance = remainingDays > 0 ? (remainingBudget / remainingDays) : 0.0;

    final Map<String, double> catSums = {};
    for (final e in currentMonthExpenses) {
      catSums[e.category] = (catSums[e.category] ?? 0.0) + e.amount;
    }

    String topCategory = 'None';
    double topCategorySpend = 0.0;
    catSums.forEach((cat, spend) {
      if (spend > topCategorySpend) {
        topCategorySpend = spend;
        topCategory = cat;
      }
    });

    if (GroqAiService().isConfigured && expenses.isNotEmpty) {
      try {
        final prompt = '''Generate an ultra-concise 2-sentence executive treasury commentary for this financial snapshot:
Total Monthly Budget: $currencySymbol$monthlyBudget
Current Spend: $currencySymbol$totalSpent (${((totalSpent / monthlyBudget) * 100).toStringAsFixed(1)}% of budget)
Remaining Runway: $currencySymbol$remainingBudget
Recommended Daily Burn Allowance: $currencySymbol${dailyAllowance.toStringAsFixed(0)}/day across $remainingDays remaining days
Top Category: $topCategory ($currencySymbol${topCategorySpend.toStringAsFixed(0)})

Directives:
- Keep it under 35 words.
- Executive, direct, actionable tone.
- Give a clear recommendation on pacing.''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Treasury');
        if (res.answer.trim().isNotEmpty) {
          return res.answer.trim();
        }
      } catch (e) {
        SanctuaryLogger().warn('AiFinancialService', 'AI insight error: $e');
      }
    }

    // Local deterministic insight fallback
    if (totalSpent > monthlyBudget) {
      return 'Budget limit reached ($currencySymbol${totalSpent.toStringAsFixed(0)} / $currencySymbol${monthlyBudget.toStringAsFixed(0)}). Recommend pausing non-essential discretionary disbursements.';
    } else if (totalSpent > monthlyBudget * 0.75) {
      return 'Treasury runway is at ${((remainingBudget / monthlyBudget) * 100).toStringAsFixed(0)}% with $remainingDays days left. Maintain burn under $currencySymbol${dailyAllowance.toStringAsFixed(0)}/day.';
    } else {
      return 'Pacing is healthy ($currencySymbol${totalSpent.toStringAsFixed(0)} spent). Top allocation is $topCategory. Safe daily allowance: $currencySymbol${dailyAllowance.toStringAsFixed(0)}/day.';
    }
  }
}
