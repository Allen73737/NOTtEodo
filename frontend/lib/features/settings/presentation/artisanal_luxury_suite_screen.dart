import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 20 Luxury UI Enhancements
import '../../../../core/luxury/guilloche_pull_refresh.dart';
import '../../../../core/luxury/deckled_paper_tear.dart';
import '../../../../core/luxury/column_wheel_chronograph.dart';
import '../../../../core/luxury/liquid_mercury_trail.dart';
import '../../../../core/luxury/gyro_foil_stamper.dart';
import '../../../../core/luxury/astrolabe_date_picker.dart';
import '../../../../core/luxury/split_flap_board.dart';
import '../../../../core/luxury/thermal_receipt_tear.dart';
import '../../../../core/luxury/jewelers_loupe_inspector.dart';
import '../../../../core/luxury/blind_deboss_field.dart';
import '../../../../core/luxury/damascus_steel_badge.dart';
import '../../../../core/luxury/wax_melt_compression_ritual.dart';
import '../../../../core/luxury/reel_to_reel_tape_player.dart';
import '../../../../core/luxury/typewriter_carriage_mode.dart';
import '../../../../core/luxury/mother_of_pearl_shimmer.dart';

// 16 System Enhancements
import '../../../../core/systems/spatial_ambient_sound_service.dart';
import '../../../../core/systems/local_vector_search_engine.dart';
import '../../../../core/systems/zkp_expense_audit_service.dart';
import '../../../../core/systems/incognito_burner_vault.dart';
import '../../../../core/systems/offline_forex_engine.dart';
import '../../../../core/systems/mercury_envelope_funds.dart';
import '../../../../core/systems/tactile_audio_synthesizer.dart';
import '../../../../core/systems/force_directed_knowledge_graph.dart';
import '../../../../core/systems/sovereign_git_backup.dart';

/// Artisanal Luxury Sanctuary Suite
/// Interactive exhibition and command center uniting all 36 Haute Horlogerie UI
/// and Deep System Enhancements in NOTTeodo Sanctuary.
class ArtisanalLuxurySuiteScreen extends StatefulWidget {
  const ArtisanalLuxurySuiteScreen({super.key});

  @override
  State<ArtisanalLuxurySuiteScreen> createState() => _ArtisanalLuxurySuiteScreenState();
}

class _ArtisanalLuxurySuiteScreenState extends State<ArtisanalLuxurySuiteScreen> {
  // UI Interactive state
  bool _isChronographRunning = false;
  bool _isDeckleTorn = false;
  bool _isReelPlaying = false;
  String _splitFlapWord = 'SANCTUARY';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _typewriterCtrl = TextEditingController();
  final TextEditingController _debossCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<SearchMatchResult> _searchResults = [];
  String _zkpStatus = 'Ready to Generate Proof';
  String _forexResult = '100 USD = 8350.00 INR';

  @override
  void initState() {
    super.initState();
    // Index mock documents into on-device vector engine
    final engine = LocalVectorSearchEngine();
    engine.indexDocument(
      id: 'doc1',
      title: 'Haute Horlogerie Escapements',
      content: 'Swiss lever escapement design and tourbillon cage dynamics.',
      category: 'Research',
    );
    engine.indexDocument(
      id: 'doc2',
      title: 'Tuscan Linen Capsule Wardrobe',
      content: 'Italian linen tailoring and raw silk promenade accessories.',
      category: 'Wardrobe',
    );
  }

  @override
  void dispose() {
    _typewriterCtrl.dispose();
    _debossCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchQuery(String q) {
    setState(() {
      _searchResults = LocalVectorSearchEngine().search(q);
    });
  }

  void _runZkpAudit() {
    final proof = ZkpExpenseAuditService().generateProof(
      settlementId: 'settle_goa_01',
      settledAmount: 4850.0,
      memberSecretSalt: 'curator_salt_9981',
    );
    final isValid = ZkpExpenseAuditService().verifyProof(proof);
    setState(() {
      _zkpStatus = isValid
          ? '✓ ZKP Verified: Commitment mathematically proven zero-debt without bank log.'
          : '✗ Verification Failed';
    });
    TactileAudioSynthesizer().play(TactileSoundEffect.waxSealStamp);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFEAB368);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090A0C) : const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ARTISANAL LUXURY SUITE',
          style: GoogleFonts.bodoniModa(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: goldColor,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: DamascusSteelBadge(text: 'AES-256 VAULT'),
          ),
        ],
      ),
      body: LiquidMercuryTrail(
        child: GuillochePullRefresh(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 1200));
            TactileAudioSynthesizer().play(TactileSoundEffect.brassToggle);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Gyro Foil Banner
                GyroFoilStamper(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '36 BESPOKE ENHANCEMENTS ACTIVE',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: goldColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tactile horological mechanics synthesized with local neural intelligence and zero surveillance sovereignty.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 1: HOROLOGICAL MECHANICAL CONTROLS
                _sectionHeader('I. MECHANICAL & TEMPORAL DIALS', goldColor),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Column-Wheel Chronograph
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _boxDeco(isDark),
                        child: Column(
                          children: [
                            Text('COLUMN-WHEEL', style: _microHeader(goldColor)),
                            const SizedBox(height: 8),
                            ColumnWheelChronograph(
                              isRunning: _isChronographRunning,
                              onToggle: () {
                                setState(() => _isChronographRunning = !_isChronographRunning);
                                TactileAudioSynthesizer().play(TactileSoundEffect.brassToggle);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Wax Seal Habit Ritual
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _boxDeco(isDark),
                        child: Column(
                          children: [
                            Text('SEAL COMPRESSION', style: _microHeader(goldColor)),
                            const SizedBox(height: 4),
                            WaxMeltCompressionRitual(
                              onSealed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✨ Monogram Wax Seal Formed & Vaulted.')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Astrolabe Date Picker
                AstrolabeDatePicker(
                  initialDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                ),
                const SizedBox(height: 20),

                // Mechanical Split Flap Display
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _boxDeco(isDark),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SPLIT-FLAP SOLARI DIAL', style: _microHeader(goldColor)),
                          TextButton(
                            onPressed: () {
                              final words = ['SANCTUARY', 'CHRONOS', 'AESTHETE', 'HOROLOGY'];
                              final next = words[(words.indexOf(_splitFlapWord) + 1) % words.length];
                              setState(() => _splitFlapWord = next);
                              TactileAudioSynthesizer().play(TactileSoundEffect.typewriterBell);
                            },
                            child: Text('CYCLE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: goldColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SplitFlapBoard(text: _splitFlapWord),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 2: PHYSICAL PAPER & TACTILE ARTIFACTS
                _sectionHeader('II. PHYSICAL PARCHMENT & TEXTURE', goldColor),
                const SizedBox(height: 14),

                // Deckled Edge Paper Tear Demo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _boxDeco(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DECKLED PAPER TEAR', style: _microHeader(goldColor)),
                          ElevatedButton(
                            onPressed: () => setState(() => _isDeckleTorn = !_isDeckleTorn),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: Text(_isDeckleTorn ? 'RESET' : 'TEAR NOTE', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DeckledPaperTear(
                        isTorn: _isDeckleTorn,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFFAF7EE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Archived Reflection: Architecture of high-throughput zero-knowledge commitment systems.',
                            style: GoogleFonts.courierPrime(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Jeweler's Loupe Inspector Zone
                JewelersLoupeInspector(
                  child: MotherOfPearlShimmer(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LONG-PRESS FOR JEWELER’S LOUPE', style: _microHeader(goldColor)),
                          const SizedBox(height: 6),
                          Text(
                            'Inspecting Mother-of-Pearl Weave & 3x Barrel Distortion.',
                            style: GoogleFonts.bodoniModa(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Blind Deboss Indented Field
                BlindDebossField(
                  controller: _debossCtrl,
                  label: 'Blind Deboss Letterpress Field',
                  hintText: 'Type with physical debossed cotton indentation...',
                ),
                const SizedBox(height: 20),

                // Thermal Receipt Tear
                ThermalReceiptTear(
                  title: 'Anjuna Villa Split',
                  amount: 'INR 4,850.00',
                  lineItems: const [
                    'Villa Suite Stay  INR 3,200',
                    'Acoustic Bistro   INR 1,150',
                    'Scooter Fleet     INR 500',
                  ],
                  onTorn: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📜 Receipt Torn & Archival Slip Sealed.')),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Reel-to-Reel Tape Player
                ReelToReelTapePlayer(
                  title: 'Acoustic Memoir • Night Sketches',
                  isPlaying: _isReelPlaying,
                  onTogglePlay: () {
                    setState(() => _isReelPlaying = !_isReelPlaying);
                    TactileAudioSynthesizer().play(TactileSoundEffect.paperRustle);
                  },
                ),
                const SizedBox(height: 20),

                // Typewriter Carriage Mode
                TypewriterCarriageMode(controller: _typewriterCtrl),
                const SizedBox(height: 24),

                // SECTION 3: SYSTEM INTELLIGENCE & CRYPTOGRAPHY
                _sectionHeader('III. DEEP SYSTEMS & CRYPTOGRAPHY', goldColor),
                const SizedBox(height: 14),

                // Local Neural Vector RAG Search
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _boxDeco(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LOCAL NEURAL VECTOR SEARCH (ON-DEVICE RAG)', style: _microHeader(goldColor)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchQuery,
                        style: GoogleFonts.dmSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search semantically (e.g. "escapement" or "linen")...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._searchResults.map(
                          (r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.document.title, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('Score: ${(r.similarityScore * 100).toStringAsFixed(1)}%', style: GoogleFonts.courierPrime(fontSize: 11, color: goldColor)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ZKP Audit Trigger
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _boxDeco(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ZERO-KNOWLEDGE PROOF (ZKP) EXPENSE AUDIT', style: _microHeader(goldColor)),
                      const SizedBox(height: 8),
                      Text(_zkpStatus, style: GoogleFonts.courierPrime(fontSize: 11.5, color: const Color(0xFF86CBB0))),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _runZkpAudit,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E242B)),
                        child: Text('GENERATE ZKP SETTLEMENT PROOF', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mercury Envelope Sinking Funds Preview
                Row(
                  children: [
                    MercuryEnvelopeFundsWidget(
                      envelope: BudgetEnvelope(
                        id: 'env_1',
                        name: 'Horology Fund',
                        allocatedAmount: 1000,
                        spentAmount: 350,
                      ),
                    ),
                    const SizedBox(width: 14),
                    MercuryEnvelopeFundsWidget(
                      envelope: BudgetEnvelope(
                        id: 'env_2',
                        name: 'Riviera Travel',
                        allocatedAmount: 800,
                        spentAmount: 600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SECTION 4: SPATIAL AUDIO, FOREX & CONSTELLATION GRAPH
                _sectionHeader('IV. SPATIAL AUDIO & SOVEREIGN GRAPH', goldColor),
                const SizedBox(height: 14),

                // Binaural Spatial Sound Master
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _boxDeco(isDark),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BINAURAL SPATIAL SOUND SANCTUARY', style: _microHeader(goldColor)),
                          const SizedBox(height: 4),
                          Text('Clock Escapement • Rain on Leaded Glass • Hearth', style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          SpatialAmbientSoundService().isMasterActive ? Icons.volume_up : Icons.volume_off,
                          color: goldColor,
                        ),
                        onPressed: () {
                          setState(() {
                            SpatialAmbientSoundService().toggleMaster();
                          });
                          TactileAudioSynthesizer().play(TactileSoundEffect.brassToggle);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Offline Forex Engine Preview
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _boxDeco(isDark),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OFFLINE MULTI-CURRENCY FOREX ENGINE', style: _microHeader(goldColor)),
                          const SizedBox(height: 6),
                          Text(_forexResult, style: GoogleFonts.courierPrime(fontSize: 13, fontWeight: FontWeight.bold, color: goldColor)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final converted = OfflineForexEngine().convert(amount: 250, fromCode: 'EUR', toCode: 'USD');
                          setState(() {
                            _forexResult = '250 EUR = \$${converted.toStringAsFixed(2)} USD';
                          });
                          TactileAudioSynthesizer().play(TactileSoundEffect.brassToggle);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                        child: Text('CONVERT', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Interactive Force-Directed Knowledge Graph
                Container(
                  height: 180,
                  decoration: _boxDeco(isDark),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        ForceDirectedKnowledgeGraph(
                          initialNodes: [
                            GraphNode(id: '1', label: 'Notes', color: const Color(0xFFEAB368), position: const Offset(80, 80)),
                            GraphNode(id: '2', label: 'Tasks', color: const Color(0xFF86CBB0), position: const Offset(160, 100)),
                            GraphNode(id: '3', label: 'Vault', color: const Color(0xFFE8927C), position: const Offset(230, 70)),
                          ],
                          edges: [
                            GraphEdge(sourceId: '1', targetId: '2'),
                            GraphEdge(sourceId: '2', targetId: '3'),
                          ],
                        ),
                        Positioned(
                          top: 10,
                          left: 14,
                          child: Text('FORCE-DIRECTED CONSTELLATION GRAPH (DRAG NODES)', style: _microHeader(goldColor)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sovereign Git Backup Trigger
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _boxDeco(isDark),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SOVEREIGN GIT VAULT BACKUP', style: _microHeader(goldColor)),
                          const SizedBox(height: 4),
                          Text('Exports structured YAML frontmatter Markdown bundle.', style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final backup = SovereignGitBackup().formatNote(
                            id: 'n1',
                            title: 'Sanctuary Master Architecture',
                            space: 'Architecture',
                            tag: 'Vault',
                            date: '2026-09-08',
                            content: 'Full sovereign archive snapshot.',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('📦 Exported to: ${backup.relativePath}')),
                          );
                          TactileAudioSynthesizer().play(TactileSoundEffect.waxSealStamp);
                        },
                        icon: const Icon(Icons.download, size: 14, color: Colors.black),
                        label: Text('EXPORT BUNDLE', style: GoogleFonts.dmSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black)),
                        style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Incognito Burner Pad Summons
                const IncognitoBurnerVault(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color goldColor) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: goldColor,
      ),
    );
  }

  TextStyle _microHeader(Color goldColor) {
    return GoogleFonts.dmSans(
      fontSize: 9.5,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      color: goldColor,
    );
  }

  BoxDecoration _boxDeco(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF131316) : const Color(0xFFFAF7F0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? const Color(0xFF28282C) : const Color(0xFFE5DDD0),
        width: 1.2,
      ),
    );
  }
}
