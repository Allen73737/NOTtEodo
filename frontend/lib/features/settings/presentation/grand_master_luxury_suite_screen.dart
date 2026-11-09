import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 20 New Luxury UI Components
import '../../../../core/luxury/cloisonne_enamel_badge.dart';
import '../../../../core/luxury/kintsugi_gold_seam.dart';
import '../../../../core/luxury/skeleton_escapement_ticker.dart';
import '../../../../core/luxury/clous_de_paris_toggle.dart';
import '../../../../core/luxury/grand_feu_enamel_card.dart';
import '../../../../core/luxury/astronomical_moonphase_disc.dart';
import '../../../../core/luxury/parchment_watermark_view.dart';
import '../../../../core/luxury/champleve_metric_gauge.dart';
import '../../../../core/luxury/tourbillon_cage_fabrique.dart';
import '../../../../core/luxury/gilded_edge_sweep.dart';
import '../../../../core/luxury/amber_tortoiseshell_container.dart';
import '../../../../core/luxury/breguet_hands_tracker.dart';
import '../../../../core/luxury/letterpress_type_sorter.dart';
import '../../../../core/luxury/torricelli_barometer_gauge.dart';
import '../../../../core/luxury/cotes_de_geneve_backing.dart';
import '../../../../core/luxury/suminagashi_ink_canvas.dart';
import '../../../../core/luxury/cire_perdue_progress_bar.dart';
import '../../../../core/luxury/guilloche_subdial_gauge.dart';
import '../../../../core/luxury/signet_intaglio_engraver.dart';
import '../../../../core/luxury/lapis_lazuli_shimmer_card.dart';

// 17 New Sovereign Systems Components
import '../../../../core/systems/steganography_carrier_vault.dart';
import '../../../../core/systems/circadian_color_drift_service.dart';
import '../../../../core/systems/sovereign_mesh_sync_engine.dart';
import '../../../../core/systems/monte_carlo_runway_engine.dart';
import '../../../../core/systems/timelock_cryo_vault_service.dart';
import '../../../../core/systems/linguistic_cadence_analyzer.dart';
import '../../../../core/systems/analog_tape_saturation_engine.dart';
import '../../../../core/systems/sovereign_rss_broadsheet_service.dart';
import '../../../../core/systems/micro_typography_engine.dart';
import '../../../../core/systems/keystroke_fatigue_pacer.dart';
import '../../../../core/systems/memory_palace_spatial_engine.dart';
import '../../../../core/systems/ex_libris_ledger_service.dart';
import '../../../../core/systems/ephemeral_clipboard_sanitizer.dart';
import '../../../../core/systems/isochronic_entrainment_generator.dart';
import '../../../../core/systems/antiquarian_print_formatter.dart';
import '../../../../core/systems/nostr_relay_sync_service.dart';
import '../../../../core/systems/horological_complication_service.dart';
import '../../../core/motion/motion.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Grand Master Luxury & Sovereign Suite (Series 2 - 37 Enhancements)
/// Comprehensive live exhibition and testbed showcasing Haute Horlogerie UI craftsmanship
/// and cryptographic sovereign privacy engines.
class GrandMasterLuxurySuiteScreen extends StatefulWidget {
  const GrandMasterLuxurySuiteScreen({super.key});

  @override
  State<GrandMasterLuxurySuiteScreen> createState() =>
      _GrandMasterLuxurySuiteScreenState();
}

class _GrandMasterLuxurySuiteScreenState
    extends State<GrandMasterLuxurySuiteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Interactive States
  bool _clousHobnailVal = true;
  double _breguetProgress = 0.65;
  List<String> _letterpressItems = [
    'Hermetic Manuscript',
    'Haute Horlogerie Complications',
    'Sovereign Vector Ledger',
    'Vitreous Enamel Seals',
  ];

  // Systems State
  String _steganographyResult = 'Ready to encode into pixels.';
  String _monteCarloSummary = 'Tap "Simulate Runway" to execute 2,000 runs.';
  String _timelockSummary = 'No sealed capsule in memory.';
  final TextEditingController _cadenceCtrl = TextEditingController(
    text: 'Silence is the sanctum of enduring thought. Words penned in serenity outlast fleeting storms.',
  );
  String _cadenceOutput = '';

  final TimelockCryoVaultService _cryoService = TimelockCryoVaultService();
  final SovereignMeshSyncEngine _meshEngine =
      SovereignMeshSyncEngine(peerId: 'SANCTUM_NODE_77');
  final KeystrokeFatiguePacer _fatiguePacer = KeystrokeFatiguePacer();
  final MemoryPalaceSpatialEngine _palaceEngine = MemoryPalaceSpatialEngine();
  final ExLibrisLedgerService _exLibrisService = ExLibrisLedgerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _analyzeCadence();

    // Populate default memory palace and library
    _palaceEngine.anchorNote(
      title: 'Principia Mathematica',
      chamber: PalaceChamber.eastAthenaeum,
      x: 35.0,
      y: 42.0,
      summary: 'Geometric proofs and timeless gravity.',
    );
    _exLibrisService.registerVolume(
      title: 'Meditations of Marcus Aurelius',
      author: 'Marcus Aurelius',
      publicationYear: 1898,
      binding: BindingGrade.moroccoLeather,
      motto: 'Amor Fati',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cadenceCtrl.dispose();
    super.dispose();
  }

  void _analyzeCadence() {
    final m = LinguisticCadenceAnalyzer.analyze(_cadenceCtrl.text);
    setState(() {
      _cadenceOutput =
          '${m.cadenceAssessment} · Diversity: ${(m.lexicalDiversity * 100).toInt()}% · Flesch: ${m.fleschReadingEase.toStringAsFixed(1)}';
    });
  }

  void _runMonteCarlo() {
    final result = MonteCarloRunwayEngine.simulate(
      initialSavings: 150000.0,
      monthlyBurnRate: 3500.0,
      annualReturnMean: 0.06,
      annualVolatility: 0.14,
      iterations: 2000,
    );
    setState(() {
      _monteCarloSummary =
          'Median: ${(result.medianRunwayMonths / 12).toStringAsFixed(1)} yrs · Worst 10%: ${(result.worstCase10thPercentileMonths / 12).toStringAsFixed(1)} yrs · Solvency: ${(result.probabilityOfSolvencyAtTargetYears * 100).toStringAsFixed(1)}%';
    });
  }

  void _testSteganography() {
    // Generate mock RGBA 100x100 pixel buffer
    final pixels = Uint8List(100 * 100 * 4);
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = (i % 256);
    }

    const secret = 'SEED: obsidian granite cedar twilight 9921';
    final encoded = SteganographyCarrierVault.encodePayload(
      rgbaPixels: pixels,
      secretPayload: secret,
    );
    final decoded = SteganographyCarrierVault.decodePayload(rgbaPixels: encoded);

    setState(() {
      _steganographyResult = 'Embedded & Extracted: "$decoded"';
    });
  }

  void _sealCryoCapsule() {
    final target = DateTime.now().add(const Duration(days: 365));
    final cap = _cryoService.sealCapsule(
      title: 'Epistle to Self (Anno 2027)',
      plaintext: 'Remember the tranquility cultivated during solitary craftsmanship.',
      targetUnlockTime: target,
    );
    setState(() {
      _timelockSummary = 'Sealed: "${cap.title}" (Unlocks in 365d)';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'GRAND MASTER SUITE',
          style: GoogleFonts.bodoniModa(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: goldColor,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: goldColor,
          labelColor: goldColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: GoogleFonts.cormorantGaramond(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          tabs: const [
            Tab(text: 'HOROLOGICAL UI (20)'),
            Tab(text: 'SOVEREIGN SYSTEMS (17)'),
          ],
        ),
      ),
      body: GildedEdgeSweep(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHorologicalUiTab(isDark, goldColor),
            _buildSovereignSystemsTab(isDark, goldColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHorologicalUiTab(bool isDark, Color goldColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1 & 4. Badges & Clous de Paris Toggles
          _sectionTitle('1 & 4. CLOISONNÉ ENAMEL & CLOUS DE PARIS HOBNAIL'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const CloisonneEnamelBadge(label: 'Grand Complication', icon: Icons.watch),
              const CloisonneEnamelBadge(
                label: 'Sovereign Core',
                enamelColor: Color(0xFF1B4D3E),
                icon: Icons.shield,
              ),
              ClousDeParisToggle(
                value: _clousHobnailVal,
                onChanged: (v) => setState(() => _clousHobnailVal = v),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Kintsugi Golden Seam
          _sectionTitle('2. KINTSUGI GOLDEN SEAM DIFF CELEBRATION'),
          const KintsugiGoldSeam(
            originalText: 'Draft: Expenses recorded in cloud database with external ping.',
            revisedText: 'Sealed: Encrypted discrete-log commitments anchored 100% on-device.',
          ),
          const SizedBox(height: 24),

          // 3 & 9. Escapement & Tourbillon Kinetic Fabrique
          _sectionTitle('3 & 9. 4Hz MECHANICAL ESCAPEMENT & 3D TOURBILLON CAGE'),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  SkeletonEscapementTicker(size: 64),
                  SizedBox(height: 6),
                  Text('4Hz (28,800 vph)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Column(
                children: [
                  TourbillonCageFabrique(size: 72),
                  SizedBox(height: 6),
                  Text('60s Carriage Inertia', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Grand Feu Kiln Firing
          _sectionTitle('5. GRAND FEU 800°C VITREOUS ENAMEL FIRING'),
          GrandFeuEnamelCard(
            title: 'CERAMIC HOROLOGICAL CERTIFICATE',
            child: Text(
              'Tap the flame icon above to trigger the 800°C kiln-firing thermal pulse transition into porcelain glaze.',
              style: GoogleFonts.spectral(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          const SizedBox(height: 24),

          // 6 & 12. Astronomical Moonphase & Breguet Hands
          _sectionTitle('6 & 12. ASTRONOMICAL MOONPHASE & BLUED BREGUET POMME HANDS'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const AstronomicalMoonphaseDisc(size: 110),
              Column(
                children: [
                  BreguetHandsTracker(progress: _breguetProgress),
                  Slider(
                    value: _breguetProgress,
                    activeColor: goldColor,
                    onChanged: (v) => setState(() => _breguetProgress = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 7. Parchment Watermark
          _sectionTitle('7. TRANSLUCENT PARCHMENT FIBER WATERMARK'),
          ParchmentWatermarkView(
            child: Text(
              'Hover or move your cursor across this card to observe the heraldic crest shining through translucent vellum paper fibers.',
              style: GoogleFonts.spectral(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          const SizedBox(height: 24),

          // 8 & 17. Champleve Bas-Relief & Cire Perdue Bronze
          _sectionTitle('8 & 17. CHAMPLEVÉ CARVED GAUGE & CIRE PERDUE CASTING'),
          const ChampleveMetricGauge(
            label: 'Opulent Reserve Ratio',
            value: 0.78,
            displayValue: '78.4% Funded',
          ),
          const SizedBox(height: 10),
          const CirePerdueProgressBar(
            progress: 0.85,
            label: 'Milestone Bronze Lost-Wax Smelting',
          ),
          const SizedBox(height: 24),

          // 11. Tortoiseshell & Amber Container
          _sectionTitle('11. TORTOISESHELL & AMBER RESIN GLASSMORPHISM'),
          AmberTortoiseshellContainer(
            child: Text(
              'Organic acetate and warm cognac resin optical panel providing rich, restful contrast with zero blue-light strain.',
              style: GoogleFonts.spectral(fontSize: 13, color: const Color(0xFFE8DAC8)),
            ),
          ),
          const SizedBox(height: 24),

          // 13. Letterpress Lead Type Sorter
          _sectionTitle('13. GUTENBERG LEAD TYPE COMPOSING STICK SORTER'),
          LetterpressTypeSorter(
            items: _letterpressItems,
            onReordered: (newList) => setState(() => _letterpressItems = newList),
          ),
          const SizedBox(height: 24),

          // 14 & 18. Torricelli Barometer & Guilloche Subdial
          _sectionTitle('14 & 18. TORRICELLI MERCURY BAROMETER & GUILLOCHÉ SUB-DIAL'),
          const TorricelliBarometerGauge(
            pressureRatio: 0.74,
            statusDescription: '764 mmHg · Serene Atmospheric Pressure',
          ),
          const SizedBox(height: 14),
          const Center(
            child: GuillocheSubdialGauge(
              value: 0.82,
              label: 'Solvency Chronometer',
              readout: '82% SECURE',
            ),
          ),
          const SizedBox(height: 24),

          // 15 & 16. Cotes de Geneve & Suminagashi Floating Ink
          _sectionTitle('15 & 16. CÔTES DE GENÈVE & SUMINAGASHI INK RIPPLE'),
          Container(
            height: 120,
            decoration: edBox(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CotesDeGeneveBacking(
                child: SuminagashiInkCanvas(
                  child: Center(
                    child: Text(
                      'Drag cursor or finger across to disturb fluid ink ribbons.',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: goldColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 19 & 20. Signet Ring Intaglio & Lapis Lazuli Shimmer
          _sectionTitle('19 & 20. SIGNET RING INTAGLIO & LAPIS LAZULI STONE'),
          Row(
            children: [
              const SignetIntaglioEngraver(monogram: 'NV', size: 80),
              const SizedBox(width: 14),
              Expanded(
                child: LapisLazuliShimmerCard(
                  child: Text(
                    'Royal Afghan Lapis Lazuli plate with procedural sparkling pyrite gold dust flecks.',
                    style: GoogleFonts.spectral(fontSize: 12.5, color: const Color(0xFFFAF6EE)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ].revealed(),
      ),
    );
  }

  Widget _buildSovereignSystemsTab(bool isDark, Color goldColor) {
    final kelvin = CircadianColorDriftService.getEffectiveKelvin();
    final complication = HorologicalComplicationService.pollTelemetry();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telemetry & Complication
          _sectionTitle('40. HAUTE HORLOGERIE COMPLICATION TELEMETRY'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: edBox(
              color: isDark ? const Color(0xFF141312) : const Color(0xFFFAF7EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _telemetryColumn('TIME', complication.timeHhMm),
                _telemetryColumn('LUNATION', complication.moonPhaseSummary.split('·').first),
                _telemetryColumn('SOLAR', complication.solarAltitudeDeg),
                _telemetryColumn('PRESSURE', complication.cognitiveAtmosphereMmHg.split('·').first),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 21. Steganography Image Carrier
          _sectionTitle('21. STEGANOGRAPHIC IMAGE CARRIER VAULT (LSB ENCODER)'),
          Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
            onPressed: _testSteganography,
            icon: const Icon(Icons.hide_image_outlined, size: 16),
            label: const Text('ENCODE & EXTRACT TEST PAYLOAD'),
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
          )),
          const SizedBox(height: 6),
          Text(_steganographyResult, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 24),

          // 22. Circadian Drift
          _sectionTitle('22. CIRCADIAN COLOR TEMPERATURE & SERIF WEIGHT DRIFT'),
          Text(
            'Solar Altitude Kelvin: ${kelvin.toStringAsFixed(0)}K (Daylight 6500K ➔ Night 2200K)',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: goldColor),
          ),
          const SizedBox(height: 24),

          // 23. Sovereign Mesh Sync
          _sectionTitle('23. SOVEREIGN AD-HOC MESH SYNC (ZERO-ROUTER P2P)'),
          Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
            onPressed: () {
              _meshEngine.broadcastPayload(
                payloadType: 'CRDT_MERGE',
                encryptedData: 'crdt_delta_v4_aes256',
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
            child: const Text('BROADCAST AD-HOC MESH PACKET'),
          )),
          Text(
            'Packets in local mesh log: ${_meshEngine.packetLog.length}',
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 24),

          // 24. Monte Carlo Simulator
          _sectionTitle('24. MONTE CARLO MULTI-DECADE WEALTH RUNWAY SIMULATOR'),
          Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
            onPressed: _runMonteCarlo,
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
            child: const Text('EXECUTE 2,000 MONTE CARLO PATHS'),
          )),
          const SizedBox(height: 6),
          Text(_monteCarloSummary, style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: goldColor)),
          const SizedBox(height: 24),

          // 25. Epistolary Time-Lock Vault
          _sectionTitle('25. EPISTOLARY TIME-LOCKED CRYO-VAULT'),
          Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
            onPressed: _sealCryoCapsule,
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
            child: const Text('SEAL TIME-LOCKED CAPSULE (1 YEAR)'),
          )),
          const SizedBox(height: 6),
          Text(_timelockSummary, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 24),

          // 26. Linguistic Cadence Analyzer
          _sectionTitle('26. LINGUISTIC CADENCE & SENTIMENT FLUIDITY ANALYZER'),
          TextField(
            controller: _cadenceCtrl,
            maxLines: 2,
            style: GoogleFonts.spectral(fontSize: 13),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              hintText: 'Enter prose to evaluate cadence...',
            ),
            onChanged: (_) => _analyzeCadence(),
          ),
          const SizedBox(height: 6),
          Text(_cadenceOutput, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: goldColor)),
          const SizedBox(height: 24),

          // 29 & 37. Tape Saturation & Isochronic Generator
          _sectionTitle('29 & 37. ANALOG MASTER TAPE SATURATION & ISOCHRONIC ENTRAINMENT'),
          Builder(
            builder: (context) {
              final tapeEngine = AnalogTapeSaturationEngine();
              tapeEngine.startTapeHead();
              final state = tapeEngine.computeState(1.2);
              const isochronic = IsochronicEntrainmentGenerator(targetBand: BrainwaveBand.alpha);

              return Text(
                'Tape Hiss: ${state.tapeHissDb.toStringAsFixed(1)} dB · Wow & Flutter: ${(state.wowAndFlutter * 100).toStringAsFixed(2)}% · Isochronic Band: Alpha (${isochronic.pulseFrequencyHz} Hz)',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
              );
            },
          ),
          const SizedBox(height: 24),

          // 30 & 31. Broadsheet Reader & Micro-Typography
          _sectionTitle('30 & 31. SOVEREIGN BROADSHEET & MICRO-TYPOGRAPHY LIGATURES'),
          Builder(
            builder: (context) {
              const raw = '<p>Philosophy---"Artisan flow" with difficult ligatures fi and fl.</p>';
              final clean = SovereignRssBroadsheetService.parseAndSanitizeRawFeed(
                rawHtmlOrText: raw,
                title: 'Of Solitude',
                author: 'Michel de Montaigne',
                publication: 'Essais',
              );
              final withLigatures = MicroTypographyEngine.applyClassicalLigaturesAndQuotes(clean.cleanText);

              return Text(
                'Sanitized & Ligature-Applied: $withLigatures',
                style: GoogleFonts.spectral(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
              );
            },
          ),
          const SizedBox(height: 24),

          // 33 & 36. Keystroke Fatigue Pacer & Ephemeral Clipboard
          _sectionTitle('33 & 36. KEYSTROKE FATIGUE PACER & EPHEMERAL CLIPBOARD PURGE'),
          Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton(
            onPressed: () {
              _fatiguePacer.recordKeyPress();
              EphemeralClipboardSanitizer.copyEphemeralSecret(
                secret: 'SEALED_VAULT_KEY_ALPHA',
                timeout: const Duration(seconds: 15),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied key. Auto-purging clipboard in 15 seconds.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
            child: const Text('TEST KEY RECORD & ARMED 15s CLIPBOARD PURGE'),
          )),
          Text(
            _fatiguePacer.guidanceMessage,
            style: GoogleFonts.spectral(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 24),

          // 34 & 35. Memory Palace & Ex Libris Ledger
          _sectionTitle('34 & 35. 3D MEMORY PALACE CHAMBERS & EX LIBRIS BOOKPLATES'),
          Text(
            'Anchored Loci: ${_palaceEngine.anchors.first.title} in ${_palaceEngine.anchors.first.chamber.name}',
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
          ),
          Text(
            'Ex Libris Volume: "${_exLibrisService.catalog.first.title}" (${_exLibrisService.catalog.first.exLibrisMotto})',
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: goldColor),
          ),
          const SizedBox(height: 24),

          // 38 & 39. Antiquarian Signature Print & Nostr Relay Sync
          _sectionTitle('38 & 39. ANTIQUARIAN SIGNATURE PRINT FORMATTER & NOSTR BACKUP'),
          Builder(
            builder: (context) {
              final folios = AntiquarianPrintFormatter.generateOctavoSignatureImposition(32);
              const nostr = NostrRelaySyncService(publicKeyHex: 'npub1sanctuaryhautehorlogerie99');
              final ev = nostr.createEncryptedNoteEvent(
                noteTitle: 'Sovereign Journal',
                encryptedCiphertext: 'nip44_ciphertext_mock_hash',
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Octavo Signatures Created: ${folios.length} bifolium sheets', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Nostr Event Signed: ${ev.id.substring(0, 24)}... (Kind: ${ev.kind})', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: goldColor)),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: const Color(0xFFD4AF37),
        ),
      ),
    );
  }

  Widget _telemetryColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: const Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
