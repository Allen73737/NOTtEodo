/// Book Binding Grade
enum BindingGrade {
  clothHardcover,
  moroccoLeather,
  vellumBound,
  paperbackFirstEdition,
}

/// Heirloom Book Entry
class HeirloomVolume {
  final String volumeId;
  final String title;
  final String author;
  final int publicationYear;
  final BindingGrade binding;
  final String? loanedToRecipient;
  final String? exLibrisMotto;

  const HeirloomVolume({
    required this.volumeId,
    required this.title,
    required this.author,
    required this.publicationYear,
    required this.binding,
    this.loanedToRecipient,
    this.exLibrisMotto,
  });

  bool get isLoaned => loanedToRecipient != null && loanedToRecipient!.isNotEmpty;
}

/// Ex Libris Heirloom Library & Lending Ledger Service
/// Curates cherished physical literature with custom woodcut Ex Libris bookplates,
/// edition binding provenance, and custodial lending records.
class ExLibrisLedgerService {
  final List<HeirloomVolume> _catalog = [];

  List<HeirloomVolume> get catalog => List.unmodifiable(_catalog);

  void registerVolume({
    required String title,
    required String author,
    required int publicationYear,
    required BindingGrade binding,
    String? motto,
  }) {
    final vol = HeirloomVolume(
      volumeId: 'VOL-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      author: author,
      publicationYear: publicationYear,
      binding: binding,
      exLibrisMotto: motto ?? 'Ex Libris Sanctum',
    );
    _catalog.add(vol);
  }

  void recordLoan(String volumeId, String recipient) {
    final idx = _catalog.indexWhere((v) => v.volumeId == volumeId);
    if (idx != -1) {
      final old = _catalog[idx];
      _catalog[idx] = HeirloomVolume(
        volumeId: old.volumeId,
        title: old.title,
        author: old.author,
        publicationYear: old.publicationYear,
        binding: old.binding,
        loanedToRecipient: recipient,
        exLibrisMotto: old.exLibrisMotto,
      );
    }
  }

  void recordReturn(String volumeId) {
    final idx = _catalog.indexWhere((v) => v.volumeId == volumeId);
    if (idx != -1) {
      final old = _catalog[idx];
      _catalog[idx] = HeirloomVolume(
        volumeId: old.volumeId,
        title: old.title,
        author: old.author,
        publicationYear: old.publicationYear,
        binding: old.binding,
        loanedToRecipient: null,
        exLibrisMotto: old.exLibrisMotto,
      );
    }
  }
}
