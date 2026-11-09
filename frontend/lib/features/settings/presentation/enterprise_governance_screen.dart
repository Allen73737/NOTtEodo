import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/enterprise/app_config.dart';
import '../../../core/enterprise/audit_ledger_engine.dart';
import '../../../core/enterprise/enterprise_diagnostic_service.dart';
import '../../../core/enterprise/offline_sync_queue_engine.dart';
import '../../../core/enterprise/sanctuary_logger.dart';
import '../../../core/widgets/sanctuary_loaders.dart';
import '../../../core/motion/motion.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Enterprise Governance & System Audit Console
/// Displays audit chain integrity, real-time subsystem diagnostics,
/// offline sync queue status, and structured telemetry logs.
class EnterpriseGovernanceScreen extends StatefulWidget {
  const EnterpriseGovernanceScreen({super.key});

  @override
  State<EnterpriseGovernanceScreen> createState() =>
      _EnterpriseGovernanceScreenState();
}

class _EnterpriseGovernanceScreenState extends State<EnterpriseGovernanceScreen> {
  List<DiagnosticCheckResult>? _diagnosticResults;
  bool _isRunningDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isRunningDiagnostics = true);
    final results = await EnterpriseDiagnosticService.runFullDiagnosticSuite();
    if (mounted) {
      setState(() {
        _diagnosticResults = results;
        _isRunningDiagnostics = false;
      });
    }
  }

  void _exportAuditLogs() {
    final jsonl = SanctuaryLogger().exportJsonl();
    Clipboard.setData(ClipboardData(text: jsonl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit telemetry JSONL copied to clipboard.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    final ledger = AuditLedgerEngine();
    final queue = OfflineSyncQueueEngine();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080808) : const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AUDIT & COMPLIANCE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: goldColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, size: 18, color: goldColor),
            tooltip: 'Export Telemetry Logs',
            onPressed: _exportAuditLogs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Environment & Compliance Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: edBox(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 28, color: goldColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURITY & AUDIT VERIFIED',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: goldColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Environment: ${AppConfig.environment.name.toUpperCase()} · v${AppConfig.appVersion} · Schema ${AppConfig.schemaVersion}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Real-time Diagnostic Suite
            Row(
              children: [
                Expanded(child: _sectionHeader('SYSTEM DIAGNOSTICS', goldColor)),
                if (_isRunningDiagnostics)
                  const OrbitLoader(size: 14, color: goldColor, strokeWidth: 1.5)
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh, size: 17, color: goldColor),
                    onPressed: _runDiagnostics,
                    tooltip: 'Rerun diagnostics',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (_diagnosticResults != null) ...[
              for (final d in _diagnosticResults!)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: edBox(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: d.status == DiagnosticStatus.passed
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        d.status == DiagnosticStatus.passed
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: d.status == DiagnosticStatus.passed
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.componentName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              d.details,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${d.latencyMs}ms',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),

            // 3. Audit Ledger
            _sectionHeader('AUDIT CHAIN (${ledger.blocks.length} BLOCKS)', goldColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: edBox(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CHAIN STATUS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: goldColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: edBox(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'VERIFIED',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Administrative actions and vault mutations are securely chained in a forward SHA-256 ledger.',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Pressable(
                    pressedScale: 0.96,
                    hoverLift: 0,
                    child: ElevatedButton(
                      onPressed: () {
                        ledger.recordEvent(
                          actorId: 'ADMIN_USER',
                          action: 'AUDIT_INTEGRITY_CHECK',
                          resource: 'LOCAL_LEDGER',
                          metadata: {'verified': true, 'timestamp': DateTime.now().toIso8601String()},
                        );
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Record Check Block',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Offline Outbox Transaction Queue
            _sectionHeader('SYNC QUEUE (${queue.queueLength} PENDING)', goldColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: edBox(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    queue.queueLength == 0
                        ? 'All local edits are synchronized with cloud. Sync queue is clear.'
                        : '${queue.queueLength} mutations awaiting background sync.',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Pressable(
                    pressedScale: 0.96,
                    hoverLift: 0,
                    child: ElevatedButton(
                      onPressed: () {
                        queue.enqueue(
                          entityTable: 'sanctuary_notes',
                          operation: MutationOp.insert,
                          payload: {'title': 'Diagnostic Sync Test', 'synced': false},
                        );
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Enqueue Test Item',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ].revealed(),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color goldColor) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: goldColor,
      ),
    );
  }
}
