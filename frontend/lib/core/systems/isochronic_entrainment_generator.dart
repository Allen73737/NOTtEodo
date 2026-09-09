import 'dart:math' as math;

/// Target Brainwave State
enum BrainwaveBand {
  delta, // 1 - 4 Hz (deep restorative sleep)
  theta, // 4 - 8 Hz (meditation, memory consolidation)
  alpha, // 8 - 12 Hz (calm flow state, relaxed focus)
  beta, // 12 - 30 Hz (active analytical thinking)
  gamma, // 30 - 50 Hz (peak cognitive insight)
}

/// Binaural & Isochronic Brainwave Entrainment Generator
/// Mathematical generator producing rhythmic acoustic amplitude envelopes
/// corresponding to target cerebral resonance frequencies.
class IsochronicEntrainmentGenerator {
  final BrainwaveBand targetBand;
  final double carrierFrequencyHz; // Base listening tone e.g. 216Hz or 432Hz

  const IsochronicEntrainmentGenerator({
    this.targetBand = BrainwaveBand.alpha,
    this.carrierFrequencyHz = 216.0,
  });

  double get pulseFrequencyHz {
    switch (targetBand) {
      case BrainwaveBand.delta:
        return 2.5;
      case BrainwaveBand.theta:
        return 6.0;
      case BrainwaveBand.alpha:
        return 10.0;
      case BrainwaveBand.beta:
        return 18.0;
      case BrainwaveBand.gamma:
        return 40.0;
    }
  }

  /// Evaluates the instantaneous amplitude modulation at time [tSeconds]
  double evaluateAmplitudeAtTime(double tSeconds) {
    // Isochronic pulse envelope: periodic cosine pulse with smooth taper
    final phase = (tSeconds * pulseFrequencyHz) % 1.0;
    final pulseWindow = 0.5 * (1.0 + math.cos(2 * math.pi * phase));
    return pulseWindow;
  }
}
