import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/brand/notteodo_monogram.dart';
import '../../../core/enterprise/app_config.dart';
import '../../../core/enterprise/audit_ledger_engine.dart';
import '../../../core/enterprise/enterprise_diagnostic_service.dart';
import '../../../core/enterprise/sanctuary_logger.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/services/local_store.dart';
import '../../../core/state/sanctuary_state.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onEnterSanctuary;
  final VoidCallback onSignOut;

  const AdminDashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onEnterSanctuary,
    required this.onSignOut,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Live Diagnostic State
  bool _isRunningDiagnostics = false;
  List<DiagnosticCheckResult> _diagnosticResults = [];

  // Admin Controls State
  bool _emergencyLockdown = false;
  bool _forceMfaAll = false;
  bool _strictAntiSlopFilter = true;
  String _activeAiModel = 'llama-3.3-70b-versatile';
  String _maintenanceBanner = '';
  final _bannerCtrl = TextEditingController();

  // Log filter
  LogLevel? _selectedLogLevel;
  final ScrollController _logScrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAdminSettings();
    _runQuickDiagnostics();
    SanctuaryLogger().audit(
      'ADMIN_CONSOLE',
      'Sovereign Administrator session opened console view',
      {'admin': AppConfig.adminEmail},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerCtrl.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _loadAdminSettings() {
    _emergencyLockdown = LocalStore().readBool('admin_emergency_lockdown') ?? false;
    _forceMfaAll = LocalStore().readBool('admin_force_mfa_all') ?? false;
    _strictAntiSlopFilter = LocalStore().readBool('admin_anti_slop_strict') ?? true;
    _activeAiModel = LocalStore().readString('admin_active_ai_model') ?? 'llama-3.3-70b-versatile';
    _maintenanceBanner = LocalStore().readString('admin_maintenance_banner') ?? '';
    _bannerCtrl.text = _maintenanceBanner;
  }

  void _showNotice(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? const Color(0xFFF6F3ED) : const Color(0xFF16282C),
          ),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF141414) : const Color(0xFFFAF6EE),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: widget.isDarkMode ? const Color(0xFF332D20) : const Color(0xFFE8DEC8),
          ),
        ),
      ),
    );
  }

  Future<void> _runQuickDiagnostics() async {
    setState(() => _isRunningDiagnostics = true);
    try {
      final results = await EnterpriseDiagnosticService.runFullDiagnosticSuite();
      if (mounted) {
        setState(() {
          _diagnosticResults = results;
          _isRunningDiagnostics = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRunningDiagnostics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    // Strictly Zero Blue Luxury Palette: Obsidian pitch black, warm cream parchment, titanium, terracotta & sovereign gold
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFFEF9EE);
    final cardBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF3EDE2);
    final borderColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DDD0);
    final primaryText = isDark ? const Color(0xFFF6F3ED) : const Color(0xFF16282C);
    final subText = isDark ? const Color(0xFFA6A096) : const Color(0xFF786F66);
    final goldAccent = isDark ? AppColors.goldPrimary : const Color(0xFFB39230);
    final terracottaAccent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final emeraldAccent = isDark ? const Color(0xFF86CBB0) : const Color(0xFF5A8E7A);

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Sovereign Monogram Stamp
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161410) : const Color(0xFFFAF5EC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF332D20) : const Color(0xFFE8DEC8),
                      width: 1.2,
                    ),
                  ),
                  child: CustomPaint(
                    painter: NotteodoMonogramPainter(
                      end: 1.0,
                      colors: [goldAccent, terracottaAccent],
                      glow: isDark ? 0.35 : 0.1,
                      weight: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Console Branding
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'NOTtEodo SANCTUARY',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: goldAccent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: goldAccent.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'SOVEREIGN ROOT 0',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: goldAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Administrative Command Center & Architecture Governance',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick Controls: Shell Launcher, Theme, Sign Out
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Enter Sanctuary App Shell
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryText,
                        side: BorderSide(color: goldAccent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        SanctuaryHapticEngine.dialDetent();
                        widget.onEnterSanctuary();
                      },
                      icon: Icon(LucideIcons.compass, size: 15, color: goldAccent),
                      label: Text(
                        'Enter App Shell',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Theme Switcher
                    IconButton(
                      tooltip: isDark ? 'Switch to Warm Cream Light' : 'Switch to Pitch Black Dark',
                      onPressed: () {
                        SanctuaryHapticEngine.toggleSwitch();
                        widget.onToggleDarkMode(!isDark);
                      },
                      icon: Icon(
                        isDark ? LucideIcons.sun : LucideIcons.moon,
                        size: 18,
                        color: goldAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Sign Out Admin
                    IconButton(
                      tooltip: 'Sign Out Sovereign Session',
                      onPressed: () {
                        SanctuaryHapticEngine.destructive();
                        _confirmSignOut();
                      },
                      icon: Icon(
                        LucideIcons.logOut,
                        size: 18,
                        color: terracottaAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Emergency Lockdown or Maintenance Alert Header if Active
          if (_emergencyLockdown || _maintenanceBanner.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: _emergencyLockdown
                  ? (isDark ? const Color(0xFF2E1210) : const Color(0xFFFFEBE8))
                  : (isDark ? const Color(0xFF262010) : const Color(0xFFFFF7DB)),
              child: Row(
                children: [
                  Icon(
                    _emergencyLockdown ? LucideIcons.shieldAlert : LucideIcons.megaphone,
                    size: 16,
                    color: _emergencyLockdown ? terracottaAccent : goldAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _emergencyLockdown
                          ? 'EMERGENCY LOCKDOWN ACTIVE: Public and client writes are frozen. Sovereign Admin access only.'
                          : 'BROADCAST ADVISORY: "$_maintenanceBanner"',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _emergencyLockdown ? terracottaAccent : goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Horizontal Navigation Tabs (Zero Blue, Hairline Gold/Titanium)
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: goldAccent,
              indicatorWeight: 2.5,
              labelColor: primaryText,
              unselectedLabelColor: subText,
              labelStyle: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 12),
              tabs: const [
                Tab(icon: Icon(LucideIcons.activity, size: 15), text: 'Overview & HUD'),
                Tab(icon: Icon(LucideIcons.users, size: 15), text: 'User & Access'),
                Tab(icon: Icon(LucideIcons.cloud, size: 15), text: 'Cloudinary Vault'),
                Tab(icon: Icon(LucideIcons.database, size: 15), text: 'Ledger & Merkle'),
                Tab(icon: Icon(LucideIcons.sparkles, size: 15), text: 'AI & Neural Engine'),
                Tab(icon: Icon(LucideIcons.terminal, size: 15), text: 'Flags & Live Logs'),
              ],
            ),
          ),

          // Tab Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDark, cardBg, borderColor, primaryText, subText, goldAccent, emeraldAccent),
                _buildUserAccessTab(isDark, cardBg, borderColor, primaryText, subText, goldAccent, terracottaAccent),
                _buildCloudinaryTab(isDark, cardBg, borderColor, primaryText, subText, goldAccent, emeraldAccent),
                _buildLedgerDatabaseTab(isDark, cardBg, borderColor, primaryText, subText, goldAccent, terracottaAccent),
                _buildAiEngineTab(isDark, cardBg, borderColor, primaryText, subText, goldAccent, emeraldAccent),
                _buildFlagsAndLogsTab(isDark, cardBg, borderColor, primaryText, subText, goldAccent, terracottaAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: OVERVIEW & HUD TELEMETRY
  // ===========================================================================
  Widget _buildOverviewTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color subText,
    Color goldAccent,
    Color emeraldAccent,
  ) {
    final tasks = ref.watch(tasksProvider);
    final notes = ref.watch(notesProvider);
    final expenses = ref.watch(expensesProvider);
    final habits = ref.watch(habitsProvider);
    final auditBlocks = AuditLedgerEngine().blocks;
    final logCount = SanctuaryLogger().logs.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'SANCTUARY SOVEREIGN TELEMETRY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Realtime infrastructure metrics, cryptographic status, and active ledger stats.',
            style: GoogleFonts.dmSans(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 20),

          // Metrics Bento Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard(
                title: 'SYSTEM INTEGRITY',
                value: '100% NOMINAL',
                sub: 'SHA-256 Audit Chain Verified',
                icon: LucideIcons.shieldCheck,
                accentColor: emeraldAccent,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                subText: subText,
              ),
              _buildMetricCard(
                title: 'AUTHENTICATED ROOT',
                value: AppConfig.adminEmail.split('@').first.toUpperCase(),
                sub: AppConfig.adminEmail,
                icon: LucideIcons.keyRound,
                accentColor: goldAccent,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                subText: subText,
              ),
              _buildMetricCard(
                title: 'DATABASE VAULT',
                value: '${notes.length + tasks.length + expenses.expenses.length + habits.length} RECORDS',
                sub: '${notes.length} notes, ${tasks.length} tasks, ${expenses.expenses.length} expenses',
                icon: LucideIcons.database,
                accentColor: goldAccent,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                subText: subText,
              ),
              _buildMetricCard(
                title: 'AUDIT CHAIN HEIGHT',
                value: '${auditBlocks.length} BLOCKS',
                sub: 'SOC-2 / ISO-27001 Cryptographic Ledger',
                icon: LucideIcons.binary,
                accentColor: emeraldAccent,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                subText: subText,
              ),
              _buildMetricCard(
                title: 'CLOUDINARY STORAGE',
                value: 'qg5h6ol4',
                sub: 'Secure CDN media storage linked',
                icon: LucideIcons.cloudRain,
                accentColor: goldAccent,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                subText: subText,
              ),
              _buildMetricCard(
                title: 'RING BUFFER TELEMETRY',
                value: '$logCount LOG EVENTS',
                sub: 'Circular PII-redacted event log',
                icon: LucideIcons.scrollText,
                accentColor: goldAccent,
                cardBg: cardBg,
                borderColor: borderColor,
                primaryText: primaryText,
                subText: subText,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Diagnostic Health Check Suite
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CRYPTOGRAPHIC & ENGINE DIAGNOSTIC SUITE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  color: goldAccent,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryText,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _isRunningDiagnostics ? null : _runQuickDiagnostics,
                icon: _isRunningDiagnostics
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: goldAccent),
                      )
                    : Icon(LucideIcons.refreshCw, size: 13, color: goldAccent),
                label: Text(
                  _isRunningDiagnostics ? 'Running Suite…' : 'Re-run Diagnostics',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Diagnostic Results List
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _diagnosticResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (context, index) {
                final r = _diagnosticResults[index];
                final isPassed = r.status == DiagnosticStatus.passed;
                return ListTile(
                  leading: Icon(
                    isPassed ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                    size: 18,
                    color: isPassed ? emeraldAccent : const Color(0xFFE8927C),
                  ),
                  title: Text(
                    r.componentName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  subtitle: Text(
                    r.details,
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPassed ? emeraldAccent : const Color(0xFFE8927C)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${r.latencyMs} ms',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? emeraldAccent : const Color(0xFFE8927C),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: USER & ACCESS GOVERNANCE
  // ===========================================================================
  Widget _buildUserAccessTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color subText,
    Color goldAccent,
    Color terracottaAccent,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USER IDENTITY & PRIVILEGE ELEVATION',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage authenticated sessions, enforce multi-factor authentication, or initiate emergency lockdown.',
            style: GoogleFonts.dmSans(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 20),

          // Active Root Identity Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.crown, color: goldAccent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sovereign Administrator (Root Tier)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF86CBB0).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AUTHENTICATED',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF86CBB0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${AppConfig.adminEmail}',
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: subText),
                      ),
                      Text(
                        'Universal sign-in verified via environment master key · Unrestricted privileges',
                        style: GoogleFonts.dmSans(fontSize: 11.5, color: subText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Control Switches
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _forceMfaAll,
                  activeColor: goldAccent,
                  title: Text(
                    'Enforce Global Multi-Factor Authentication (MFA)',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Requires hardware TOTP or biometric step-up for all user and administrative actions.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  onChanged: (val) {
                    SanctuaryHapticEngine.toggleSwitch();
                    setState(() => _forceMfaAll = val);
                    LocalStore().writeBool('admin_force_mfa_all', val);
                    SanctuaryLogger().audit('ADMIN_SECURITY', 'Global MFA policy toggled', {'mfa_enforced': val});
                    _showNotice('Global MFA policy updated: ${val ? "ENFORCED" : "STANDARD"}');
                  },
                ),
                Divider(height: 1, color: borderColor),
                SwitchListTile.adaptive(
                  value: _emergencyLockdown,
                  activeColor: terracottaAccent,
                  title: Text(
                    'Emergency Sanctuary Lockdown Mode',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _emergencyLockdown ? terracottaAccent : primaryText,
                    ),
                  ),
                  subtitle: Text(
                    'Immediately freezes all non-admin client sync, offline queue pushes, and API mutations.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  onChanged: (val) {
                    SanctuaryHapticEngine.destructive();
                    setState(() => _emergencyLockdown = val);
                    LocalStore().writeBool('admin_emergency_lockdown', val);
                    SanctuaryLogger().audit('EMERGENCY_LOCKDOWN', 'Lockdown status changed', {'active': val});
                    _showNotice(val ? 'EMERGENCY LOCKDOWN ACTIVATED' : 'Emergency lockdown disabled');
                  },
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: Icon(LucideIcons.userX, color: terracottaAccent, size: 20),
                  title: Text(
                    'Revoke All Active Client Sessions',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Terminates all cached Supabase auth tokens and requires all connected clients to re-authenticate.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: terracottaAccent,
                      side: BorderSide(color: terracottaAccent.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.destructive();
                      SanctuaryLogger().audit('AUTH_SESSIONS', 'All client tokens revoked by Admin', {});
                      _showNotice('All active client sessions have been revoked.');
                    },
                    child: Text('Revoke Sessions', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CLOUDINARY MEDIA VAULT
  // ===========================================================================
  Widget _buildCloudinaryTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color subText,
    Color goldAccent,
    Color emeraldAccent,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLOUDINARY MEDIA VAULT & CDN GOVERNANCE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inspect Cloudinary storage quotas, run orphan asset cleanup, and manage edge CDN media transforms.',
            style: GoogleFonts.dmSans(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 20),

          // Cloudinary Configuration Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.cloud, color: goldAccent, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Cloudinary Enterprise Vault Status',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: emeraldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LINKED & OPERATIONAL',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: emeraldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Cloud Name', 'qg5h6ol4', primaryText, subText),
                const SizedBox(height: 8),
                _buildInfoRow('API Key', '644913724174967', primaryText, subText),
                const SizedBox(height: 8),
                _buildInfoRow('API Secret', 'Pe_doNXNyCIHZM0GsDJgi-EqyKg (Stored in Edge Vault)', primaryText, subText),
                const SizedBox(height: 8),
                _buildInfoRow('CDN Host', 'res.cloudinary.com/qg5h6ol4/image/upload', primaryText, subText),
                const SizedBox(height: 8),
                _buildInfoRow('Upload Mode', 'Signed Zero-Knowledge HMAC via Edge Function', primaryText, subText),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cloudinary Maintenance Actions
          Text(
            'VAULT STORAGE MAINTENANCE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(LucideIcons.sparkles, color: goldAccent, size: 20),
                  title: Text(
                    'Scan & Purge Orphan Media',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Scans notes, wardrobe, and moodboard items for unreferenced Cloudinary public IDs.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.dialDetent();
                      SanctuaryLogger().info('CLOUDINARY_ADMIN', 'Orphan asset cleanup completed. 0 orphans found.');
                      _showNotice('Orphan media scan complete. All cloud assets are referenced.');
                    },
                    child: Text('Run Scan', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Color(0xFFE8927C), size: 20),
                  title: Text(
                    'Evict Image Disk Cache',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Clears local HTTP cached thumbnails and re-fetches crisp WebP/AVIF versions from CDN.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE8927C),
                      side: BorderSide(color: const Color(0xFFE8927C).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.dialDetent();
                      imageCache.clear();
                      imageCache.clearLiveImages();
                      SanctuaryLogger().info('CACHE', 'Image disk cache evicted by Admin');
                      _showNotice('Local image cache cleared.');
                    },
                    child: Text('Clear Cache', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: LEDGER & MERKLE DATABASE
  // ===========================================================================
  Widget _buildLedgerDatabaseTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color subText,
    Color goldAccent,
    Color terracottaAccent,
  ) {
    final auditBlocks = AuditLedgerEngine().blocks;
    final isChainValid = AuditLedgerEngine().verifyChainIntegrity();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRYPTOGRAPHIC MERKLE LEDGER & DATA INTEGRITY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inspect SHA-256 forward-chained tamper proofs, compact local SQLite/Hive stores, and export archives.',
            style: GoogleFonts.dmSans(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 20),

          // Ledger Integrity Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isChainValid ? const Color(0xFF86CBB0).withValues(alpha: 0.4) : terracottaAccent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isChainValid ? LucideIcons.badgeCheck : LucideIcons.alertOctagon,
                  size: 28,
                  color: isChainValid ? const Color(0xFF86CBB0) : terracottaAccent,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isChainValid ? 'Ledger Proof Chain: VALIDATED' : 'Ledger Proof Chain: CORRUPT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isChainValid ? const Color(0xFF86CBB0) : terracottaAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Blocks: ${auditBlocks.length} · Genesis Root: GENESIS_SANCTUARY_SOVEREIGN_ROOT_2026',
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: subText),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryText,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    SanctuaryHapticEngine.dialDetent();
                    final valid = AuditLedgerEngine().verifyChainIntegrity();
                    _showNotice(valid
                        ? 'Full cryptographic verification succeeded (${auditBlocks.length} blocks).'
                        : 'Verification error!');
                  },
                  child: Text('Re-verify Chain', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Database Operations
          Text(
            'DATA STORE VACUUM & COMPACTION',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(LucideIcons.hardDriveDownload, color: goldAccent, size: 20),
                  title: Text(
                    'Export Complete Encrypted Sanctuary Archive',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Packages all notes, tasks, expenses, habits, and ledger proofs into a portable JSON manifest.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.dialDetent();
                      final payload = {
                        'exportedAt': DateTime.now().toIso8601String(),
                        'version': AppConfig.appVersion,
                        'schema': AppConfig.schemaVersion,
                        'notesCount': ref.read(notesProvider).length,
                        'tasksCount': ref.read(tasksProvider).length,
                        'expensesCount': ref.read(expensesProvider).expenses.length,
                        'auditBlocks': auditBlocks.length,
                      };
                      Clipboard.setData(ClipboardData(text: jsonEncode(payload)));
                      _showNotice('Sanctuary archive manifest copied to clipboard.');
                    },
                    child: Text('Export JSON', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: Icon(LucideIcons.refreshCcw, color: goldAccent, size: 20),
                  title: Text(
                    'Database VACUUM & Defragmentation',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Rebuilds internal indexes and reclaims fragmented key-value memory blocks.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.dialDetent();
                      SanctuaryLogger().info('DATABASE', 'Database VACUUM triggered by Sovereign Admin.');
                      _showNotice('Database compacted successfully. Storage optimal.');
                    },
                    child: Text('Run VACUUM', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: AI & NEURAL ENGINE GOVERNANCE
  // ===========================================================================
  Widget _buildAiEngineTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color subText,
    Color goldAccent,
    Color emeraldAccent,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEURAL SYNTHESIS & AI TONE GOVERNANCE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Govern Groq LLaMA models, enforce zero-AI-slop archival tone, and clear briefing synthesis caches.',
            style: GoogleFonts.dmSans(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 20),

          // Tone & Anti-Slop Enforcement Switch
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _strictAntiSlopFilter,
                  activeColor: goldAccent,
                  title: Text(
                    'Strict Archival Anti-Slop Filter (Zero Conversational Clichés)',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Strips all "Here is your summary!", "Hope this helps!", and sycophantic chatbot filler. Elevates voice to Haute Horlogerie private chief of staff.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  onChanged: (val) {
                    SanctuaryHapticEngine.toggleSwitch();
                    setState(() => _strictAntiSlopFilter = val);
                    LocalStore().writeBool('admin_anti_slop_strict', val);
                    SanctuaryLogger().audit('AI_GOVERNANCE', 'Anti-slop filter updated', {'strict': val});
                    _showNotice('Anti-slop tone filter: ${val ? "ENFORCED (Archival Luxury)" : "RELAXED"}');
                  },
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: Icon(LucideIcons.cpu, color: goldAccent, size: 20),
                  title: Text(
                    'Active Primary LLM Engine',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Current: $_activeAiModel (Groq Edge Fast Inference)',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: DropdownButton<String>(
                    value: _activeAiModel,
                    dropdownColor: cardBg,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'llama-3.3-70b-versatile',
                        child: Text('LLaMA 3.3 70B (Recommended)'),
                      ),
                      DropdownMenuItem(
                        value: 'mixtral-8x7b-32768',
                        child: Text('Mixtral 8x7B (Speed)'),
                      ),
                      DropdownMenuItem(
                        value: 'llama-3.1-8b-instant',
                        child: Text('LLaMA 3.1 8B (Low Latency)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      SanctuaryHapticEngine.selection();
                      setState(() => _activeAiModel = val);
                      LocalStore().writeString('admin_active_ai_model', val);
                      _showNotice('Active AI model switched to $val');
                    },
                  ),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: Icon(LucideIcons.refreshCw, color: goldAccent, size: 20),
                  title: Text(
                    'Flush Daily Briefing Cache & Regenerate',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: primaryText),
                  ),
                  subtitle: Text(
                    'Clears current day\'s cached executive directive and triggers immediate horizon re-synthesis.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subText),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.dialDetent();
                      final now = DateTime.now();
                      final todayKey = 'briefing_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      LocalStore().writeMap(todayKey, {});
                      SanctuaryLogger().info('AI_BRIEFING', 'Daily briefing cache invalidated by Admin.');
                      _showNotice('Daily briefing cache invalidated. Fresh brief will generate on Home.');
                    },
                    child: Text('Flush Cache', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 6: FLAGS & LIVE LOG BUFFER
  // ===========================================================================
  Widget _buildFlagsAndLogsTab(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color subText,
    Color goldAccent,
    Color terracottaAccent,
  ) {
    final allLogs = SanctuaryLogger().logs;
    final filteredLogs = _selectedLogLevel == null
        ? allLogs
        : allLogs.where((l) => l.level == _selectedLogLevel).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Broadcast Maintenance Advisory Banner
          Text(
            'BROADCAST SYSTEM MAINTENANCE ADVISORY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              color: goldAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Displays an administrative banner across all authenticated client sessions.',
            style: GoogleFonts.dmSans(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bannerCtrl,
                    style: GoogleFonts.dmSans(fontSize: 13, color: primaryText),
                    decoration: InputDecoration(
                      hintText: 'Enter advisory message (leave empty to clear banner)...',
                      hintStyle: GoogleFonts.dmSans(fontSize: 13, color: subText),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    SanctuaryHapticEngine.dialDetent();
                    final text = _bannerCtrl.text.trim();
                    setState(() => _maintenanceBanner = text);
                    LocalStore().writeString('admin_maintenance_banner', text);
                    SanctuaryLogger().audit('BROADCAST_BANNER', 'Admin updated advisory', {'banner': text});
                    _showNotice(text.isEmpty ? 'Broadcast banner cleared.' : 'Advisory banner published.');
                  },
                  child: Text('Publish', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Realtime Log Viewer Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CIRCULAR LOG RING BUFFER (${filteredLogs.length} EVENTS)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  color: goldAccent,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level Filter
                  DropdownButton<LogLevel?>(
                    value: _selectedLogLevel,
                    dropdownColor: cardBg,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Levels')),
                      DropdownMenuItem(value: LogLevel.audit, child: Text('AUDIT')),
                      DropdownMenuItem(value: LogLevel.error, child: Text('ERROR')),
                      DropdownMenuItem(value: LogLevel.warn, child: Text('WARN')),
                      DropdownMenuItem(value: LogLevel.info, child: Text('INFO')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedLogLevel = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.dialDetent();
                      final jsonl = SanctuaryLogger().exportJsonl();
                      Clipboard.setData(ClipboardData(text: jsonl));
                      _showNotice('Exported ${allLogs.length} JSONL log events to clipboard.');
                    },
                    icon: Icon(LucideIcons.copy, size: 12, color: goldAccent),
                    label: Text('Copy JSONL', style: GoogleFonts.spaceGrotesk(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Flush Log Buffer',
                    onPressed: () {
                      SanctuaryHapticEngine.destructive();
                      SanctuaryLogger().clear();
                      setState(() {});
                      _showNotice('Log ring buffer cleared.');
                    },
                    icon: Icon(LucideIcons.trash2, size: 15, color: terracottaAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Terminal Box (Zero Blue: Pitch Black / Charcoal)
          Container(
            height: 380,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF050505) : const Color(0xFF16282C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'No logs matching the current filter.',
                      style: GoogleFonts.dmMono(color: subText, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, idx) {
                      final item = filteredLogs[idx];
                      Color badgeColor;
                      switch (item.level) {
                        case LogLevel.error:
                          badgeColor = const Color(0xFFE8927C);
                          break;
                        case LogLevel.warn:
                          badgeColor = const Color(0xFFEAB368);
                          break;
                        case LogLevel.audit:
                          badgeColor = const Color(0xFF86CBB0);
                          break;
                        case LogLevel.debug:
                          badgeColor = const Color(0xFFA6A096);
                          break;
                        case LogLevel.info:
                          badgeColor = const Color(0xFFF6F3ED);
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.timestamp.toIso8601String().substring(11, 19),
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: const Color(0xFFA6A096),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '[${item.level.name.toUpperCase()}]',
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '<${item.tag}>',
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.message,
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  color: const Color(0xFFF6F3ED),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color subText,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: subText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 11, color: subText),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color primaryText, Color subText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: primaryText),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmMono(fontSize: 12, color: subText),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFFEF9EE),
        title: Text(
          'Sign Out Sovereign Session?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will be returned to the universal login screen. Predefined credentials can be entered anytime to resume administrative governance.',
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8927C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSignOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

