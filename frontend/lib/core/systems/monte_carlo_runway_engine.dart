import 'dart:math' as math;

/// Monte Carlo Runway Simulation Result
class MonteCarloSimulationResult {
  final double medianRunwayMonths;
  final double worstCase10thPercentileMonths;
  final double bestCase90thPercentileMonths;
  final double probabilityOfSolvencyAtTargetYears;
  final int totalSimulations;

  const MonteCarloSimulationResult({
    required this.medianRunwayMonths,
    required this.worstCase10thPercentileMonths,
    required this.bestCase90thPercentileMonths,
    required this.probabilityOfSolvencyAtTargetYears,
    required this.totalSimulations,
  });
}

/// Monte Carlo Multi-Decade Wealth Runway Simulator
/// Executes on-device stochastic Brownian motion iterations to model
/// savings depletion, market variance, and inflation volatility.
class MonteCarloRunwayEngine {
  /// Runs N stochastic simulations of wealth trajectory
  static MonteCarloSimulationResult simulate({
    required double initialSavings,
    required double monthlyBurnRate,
    double annualReturnMean = 0.05,
    double annualVolatility = 0.12,
    double annualInflation = 0.03,
    int horizonYears = 10,
    int iterations = 2000,
  }) {
    final rand = math.Random(101);
    final runwayResults = <double>[];
    int solventCountAtHorizon = 0;

    final monthlyReturnMean = annualReturnMean / 12.0;
    final monthlyVolatility = annualVolatility / math.sqrt(12.0);
    final monthlyInflation = annualInflation / 12.0;
    final totalMonths = horizonYears * 12;

    for (int iter = 0; iter < iterations; iter++) {
      double balance = initialSavings;
      double burn = monthlyBurnRate;
      int monthsSurvived = 0;

      for (int m = 0; m < totalMonths; m++) {
        if (balance <= 0) break;

        // Box-Muller transform for standard normal random variable
        final u1 = math.max(1e-9, rand.nextDouble());
        final u2 = rand.nextDouble();
        final z = math.sqrt(-2.0 * math.log(u1)) * math.cos(2 * math.pi * u2);

        // Stochastic return with volatility
        final r = monthlyReturnMean + (monthlyVolatility * z);
        balance = (balance * (1.0 + r)) - burn;
        burn *= (1.0 + monthlyInflation);
        monthsSurvived++;
      }

      if (balance > 0) {
        solventCountAtHorizon++;
      }
      runwayResults.add(monthsSurvived.toDouble());
    }

    runwayResults.sort();

    final p10Index = (iterations * 0.10).floor();
    final p50Index = (iterations * 0.50).floor();
    final p90Index = (iterations * 0.90).floor();

    return MonteCarloSimulationResult(
      worstCase10thPercentileMonths: runwayResults[p10Index],
      medianRunwayMonths: runwayResults[p50Index],
      bestCase90thPercentileMonths: runwayResults[p90Index],
      probabilityOfSolvencyAtTargetYears: solventCountAtHorizon / iterations,
      totalSimulations: iterations,
    );
  }
}
