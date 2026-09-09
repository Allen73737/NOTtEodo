/// Spatial Memory Palace Room
enum PalaceChamber {
  vestibule,
  grandRotunda,
  eastAthenaeum,
  westObservatory,
  scriptorium,
  cloisteredGarden,
}

/// An Idea or Note anchored spatially in a Memory Chamber
class MemoryLocus {
  final String locusId;
  final String title;
  final PalaceChamber chamber;
  final double coordinateX; // 0.0 to 100.0 relative chamber space
  final double coordinateY;
  final String summary;

  const MemoryLocus({
    required this.locusId,
    required this.title,
    required this.chamber,
    required this.coordinateX,
    required this.coordinateY,
    required this.summary,
  });
}

/// Hermetic 3D Memory Palace Spatial Anchoring Engine
/// Maps notes and sacred reflections onto coordinates of classical architectural chambers
/// using the ancient Greek Method of Loci for enhanced spatial recall.
class MemoryPalaceSpatialEngine {
  final List<MemoryLocus> _anchors = [];

  List<MemoryLocus> get anchors => List.unmodifiable(_anchors);

  void anchorNote({
    required String title,
    required PalaceChamber chamber,
    required double x,
    required double y,
    required String summary,
  }) {
    final locus = MemoryLocus(
      locusId: 'LOC-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      chamber: chamber,
      coordinateX: x.clamp(0.0, 100.0),
      coordinateY: y.clamp(0.0, 100.0),
      summary: summary,
    );
    _anchors.add(locus);
  }

  List<MemoryLocus> getLociInChamber(PalaceChamber chamber) {
    return _anchors.where((l) => l.chamber == chamber).toList();
  }
}
