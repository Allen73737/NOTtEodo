import 'dart:convert';
import '../enterprise/sanctuary_logger.dart';
import '../utils/text_cleaner.dart';
import 'groq_ai_service.dart';

class PressureTestResult {
  final String ideaTitle;
  final String verdict;
  final List<String> blindSpots;
  final String capitalRisks;
  final String counterPerspective;
  final String hardeningRecommendation;

  const PressureTestResult({
    required this.ideaTitle,
    required this.verdict,
    required this.blindSpots,
    required this.capitalRisks,
    required this.counterPerspective,
    required this.hardeningRecommendation,
  });
}

class AiPressureTestService {
  static final AiPressureTestService _instance = AiPressureTestService._internal();
  factory AiPressureTestService() => _instance;
  AiPressureTestService._internal();

  /// Pressure-tests any idea, project, or business hypothesis against hidden risks and assumptions.
  Future<PressureTestResult> pressureTest(String title, String content) async {
    final cleanTitle = title.trim().isNotEmpty ? title.trim() : 'Project Hypothesis';
    final cleanContent = content.trim();

    if (GroqAiService().isConfigured) {
      try {
        final prompt = '''You are a ruthless, world-class executive sparring partner and strategist (devil's advocate).
Pressure-test this idea and uncover every hidden risk, blind spot, and fatal assumption before the user invests time or capital:
Title: "$cleanTitle"
Content:
"""
$cleanContent
"""

Directives:
- Be rigorous, direct, and constructive.
- Identify real operational, financial, and competitive vulnerabilities.

Return ONLY valid JSON:
{
  "verdict": "e.g. High Potential, Requires Hardening | High Execution Risk | Sound Foundation",
  "blindSpots": [
    "Blind spot 1: Unverified assumption or bottleneck",
    "Blind spot 2: Hidden dependency or regulatory/logistical hurdle",
    "Blind spot 3: User adoption or margin vulnerability"
  ],
  "capitalRisks": "1-sentence on financial or time-sink exposure",
  "counterPerspective": "The strongest argument AGAINST pursuing this as currently planned",
  "hardeningRecommendation": "1-sentence decisive advice to make this plan bulletproof"
}''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Strategic Sparring');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return PressureTestResult(
          ideaTitle: cleanTitle,
          verdict: SanctuaryTextCleaner.clean(decoded['verdict']?.toString() ?? 'High Potential, Needs Hardening'),
          blindSpots: (decoded['blindSpots'] as List<dynamic>?)?.map((e) => SanctuaryTextCleaner.clean(e.toString())).toList() ?? [],
          capitalRisks: SanctuaryTextCleaner.clean(decoded['capitalRisks']?.toString() ?? 'Monitor upfront cash burn carefully.'),
          counterPerspective: SanctuaryTextCleaner.clean(decoded['counterPerspective']?.toString() ?? 'Alternative approaches may yield faster feedback loops with lower capital outlay.'),
          hardeningRecommendation: SanctuaryTextCleaner.clean(decoded['hardeningRecommendation']?.toString() ?? 'Define a tight 2-week validation milestone before committing resources.'),
        );
      } catch (e) {
        SanctuaryLogger().warn('AiPressureTest', 'Pressure test AI error: $e');
      }
    }

    // Deterministic fallback
    return PressureTestResult(
      ideaTitle: cleanTitle,
      verdict: 'Sound Concept · Validation Required',
      blindSpots: [
        'Assumption on execution speed: tasks often take 2x longer without dedicated milestones.',
        'Cost projection: unexpected ancillary expenses often exceed baseline estimates by 20%.',
        'Opportunity cost: evaluate if this competes with your top quarterly priorities.',
      ],
      capitalRisks: 'Pace initial disbursements; avoid long-term vendor locks until first milestone is verified.',
      counterPerspective: 'Executing a smaller, stripped-down pilot first will test the core assumption with zero downside.',
      hardeningRecommendation: 'Establish clear stop-loss criteria and a 14-day measurable prototype gate.',
    );
  }
}
