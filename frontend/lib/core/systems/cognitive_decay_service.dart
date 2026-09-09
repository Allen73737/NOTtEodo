import 'dart:math';
import 'package:flutter/material.dart';

/// Procedural Cognitive Decay & Knowledge Evergreen Reminder
/// Calculates note dormancy intervals and patina color shifts, while organizing
/// forgotten insights into an automated "Evergreen Curator" recap.
class CognitiveDecayService {
  static final CognitiveDecayService _instance = CognitiveDecayService._internal();
  factory CognitiveDecayService() => _instance;
  CognitiveDecayService._internal();

  /// Calculates a decay factor from 0.0 (fresh) to 1.0 (deeply dormant / needs review)
  double calculateDecayFactor(DateTime lastReviewedDate) {
    final daysDormant = DateTime.now().difference(lastReviewedDate).inDays;
    // Sigmoid decay curve peaking around 60 days
    return (1.0 / (1.0 + exp(-(daysDormant - 45) / 15))).clamp(0.0, 1.0);
  }

  /// Provides an elegant vellum patina tint for aging notes
  Color getPatinaColor(double decayFactor, bool isDark) {
    if (decayFactor < 0.15) return Colors.transparent;

    final alpha = (decayFactor * 0.14).clamp(0.0, 0.18);
    // Aged tea-stain vellum amber in light mode, deep smoky slate in dark mode
    return isDark
        ? const Color(0xFF38332B).withValues(alpha: alpha)
        : const Color(0xFFC49A45).withValues(alpha: alpha);
  }

  /// Generates evergreen prompts for notes that have aged over 30 days
  List<String> generateEvergreenPrompts(String title, DateTime lastReviewed) {
    final days = DateTime.now().difference(lastReviewed).inDays;
    return [
      'It has been $days days since you meditated on "$title". Does this spark still align with your trajectory?',
      'Synthesize: Can "$title" be linked to your active projects?',
    ];
  }
}
