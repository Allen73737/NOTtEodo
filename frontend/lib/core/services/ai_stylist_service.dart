import 'dart:convert';
import '../enterprise/sanctuary_logger.dart';
import '../state/sanctuary_state.dart';
import 'groq_ai_service.dart';

class StylistRecommendation {
  final String lookTitle;
  final String ensemble;
  final String fabricHarmony;
  final String occasion;
  final String stylingTip;
  final String? matchingOutfitId;

  const StylistRecommendation({
    required this.lookTitle,
    required this.ensemble,
    required this.fabricHarmony,
    required this.occasion,
    required this.stylingTip,
    this.matchingOutfitId,
  });
}

class AiStylistService {
  static final AiStylistService _instance = AiStylistService._internal();
  factory AiStylistService() => _instance;
  AiStylistService._internal();

  /// Curates an outfit recommendation based on existing wardrobe or creates a tailored style advice.
  Future<StylistRecommendation> recommendDailyOutfit({
    required List<WardrobeOutfit> wardrobe,
    String? occasion,
    String? weather,
  }) async {
    final currentHour = DateTime.now().hour;
    final timeContext = currentHour < 12 ? 'Morning' : currentHour < 17 ? 'Afternoon' : 'Evening';
    final targetOccasion = occasion ?? (currentHour < 18 ? 'Executive Studio & Daily Flow' : 'Evening Social & Dining');
    final weatherContext = weather ?? 'Mild · 22°C';

    if (GroqAiService().isConfigured) {
      try {
        final existingLookNames = wardrobe.map((o) => '- ${o.title}: ${o.items} (${o.fabric}, ${o.weather})').join('\n');
        final prompt = '''You are a master haute sartorial stylist and creative director.
Time of day: $timeContext.
Target Occasion: $targetOccasion.
Weather: $weatherContext.

User's Existing Wardrobe Pieces:
${existingLookNames.isNotEmpty ? existingLookNames : "No previously recorded looks. Suggest an iconic bespoke capsule look."}

Provide a refined, quiet-luxury outfit recommendation that balances tactile textures, color harmony, and effortless poise.
Return ONLY valid JSON matching this schema:
{
  "lookTitle": "Creative poetic look title e.g. Obsidian Tailored Minimalist",
  "ensemble": "Key pieces e.g. Japanese Indigo Selvage, Raw Silk Knit, Lugged Loafers",
  "fabricHarmony": "One sentence explaining tactile texture synergy",
  "occasion": "$targetOccasion",
  "stylingTip": "One bespoke styling tip (e.g. cuff finish, proportion rule, accessory choice)"
}''';

        final res = await GroqAiService().ask(query: prompt, scope: 'Sartorial Stylist');
        final raw = res.answer.trim();
        String jsonStr = raw;
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
        if (match != null) {
          jsonStr = match.group(1) ?? raw;
        }

        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        // Check if matches an existing outfit
        String? matchId;
        final title = decoded['lookTitle']?.toString() ?? 'Curated Daily Look';
        for (final o in wardrobe) {
          if (o.title.toLowerCase().contains(title.toLowerCase()) || title.toLowerCase().contains(o.title.toLowerCase())) {
            matchId = o.id;
            break;
          }
        }

        return StylistRecommendation(
          lookTitle: title,
          ensemble: decoded['ensemble']?.toString() ?? 'Italian Linen Overshirt & Raw Silk Chinos',
          fabricHarmony: decoded['fabricHarmony']?.toString() ?? 'Crisp linen structure balanced with fluid silk drape.',
          occasion: decoded['occasion']?.toString() ?? targetOccasion,
          stylingTip: decoded['stylingTip']?.toString() ?? 'Pair with minimal silver timepiece and unbuttoned top placket.',
          matchingOutfitId: matchId ?? (wardrobe.isNotEmpty ? wardrobe.first.id : null),
        );
      } catch (e) {
        SanctuaryLogger().warn('AiStylistService', 'Stylist recommendation failed: $e');
      }
    }

    // Deterministic curated styling fallback
    if (wardrobe.isNotEmpty) {
      final selected = wardrobe[DateTime.now().day % wardrobe.length];
      return StylistRecommendation(
        lookTitle: selected.title,
        ensemble: selected.items,
        fabricHarmony: '${selected.fabric} weave paired for ${selected.weather} conditions.',
        occasion: targetOccasion,
        stylingTip: 'Maintain clean silhouette proportions with monochrome tonal accents.',
        matchingOutfitId: selected.id,
      );
    }

    return StylistRecommendation(
      lookTitle: 'Atelier Relaxed Sartorial',
      ensemble: 'Unwashed Indigo Selvage, Off-White Heavy Cotton Tee, Cashmere Cardigan',
      fabricHarmony: 'Heavy denim foundation softened by fine gauge knitwear.',
      occasion: targetOccasion,
      stylingTip: 'Single-fold denim cuff to highlight selvedge ticker line.',
      matchingOutfitId: null,
    );
  }
}

