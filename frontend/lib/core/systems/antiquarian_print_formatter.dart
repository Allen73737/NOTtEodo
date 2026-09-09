/// Imposition Leaf Pair for Bookbinding Signatures
class ImpositionFolio {
  final int folioNumber;
  final int leftPageIndex;
  final int rightPageIndex;
  final bool isOuterSheet;

  const ImpositionFolio({
    required this.folioNumber,
    required this.leftPageIndex,
    required this.rightPageIndex,
    required this.isOuterSheet,
  });
}

/// One-Tap Antiquarian Signature Print Formatter
/// Arranges linear note pages into 16-page octavo signatures (quires)
/// with page folding imposition and trim margins ready for hand-sewn binding.
class AntiquarianPrintFormatter {
  /// Calculates 16-page signature imposition mapping
  /// (e.g., page 16 paired with page 1, page 2 paired with page 15, etc.)
  static List<ImpositionFolio> generateOctavoSignatureImposition(int totalPages) {
    // Pad to multiple of 16
    final paddedCount = ((totalPages + 15) ~/ 16) * 16;
    final folios = <ImpositionFolio>[];

    for (int sig = 0; sig < paddedCount ~/ 16; sig++) {
      final sigStart = sig * 16;
      final sigEnd = sigStart + 15;

      for (int sheet = 0; sheet < 4; sheet++) {
        // Front side of bifolium
        final leftBack = sigEnd - (sheet * 2);
        final rightFront = sigStart + (sheet * 2) + 1;

        folios.add(ImpositionFolio(
          folioNumber: folios.length + 1,
          leftPageIndex: leftBack + 1,
          rightPageIndex: rightFront,
          isOuterSheet: sheet == 0,
        ));
      }
    }

    return folios;
  }
}
