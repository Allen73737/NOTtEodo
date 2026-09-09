import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_dark_theme.dart';

import 'core/services/app_alert_engine.dart';
import 'core/widgets/sanctuary_bottom_dock.dart';
import 'core/widgets/radial_quick_add.dart';
import 'core/widgets/app_drawer.dart';
import 'core/widgets/stitch_logo_widget.dart';
import 'core/widgets/scoped_ai_dialog.dart';
import 'core/widgets/dedicated_creation_screen.dart';
import 'core/widgets/ambient_particle_canvas.dart';
import 'core/widgets/kinetic_ambient_canvas.dart';
import 'core/widgets/floating_voice_ai_widget.dart';
import 'core/widgets/time_sky_header.dart';
import 'core/widgets/flip_clock_widget.dart';
import 'core/widgets/app_toast_engine.dart';
import 'core/widgets/universal_search_dialog.dart';
import 'core/performance/sanctuary_motion_engine.dart';
import 'core/widgets/celestial_horizon_dial.dart';
import 'core/widgets/sanctuary_desktop_rail.dart';

import 'features/auth/presentation/logo_reveal_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/signin_screen.dart';

import 'features/home/presentation/home_screen.dart';
import 'features/notes/presentation/notes_screen.dart';
import 'features/tasks/presentation/tasks_screen.dart';
import 'features/planner/presentation/planner_screen.dart';
import 'features/wardrobe/presentation/wardrobe_screen.dart';
import 'features/expenses/presentation/expenses_screen.dart';
import 'features/travel/presentation/travel_screen.dart';
import 'features/journal/presentation/journal_screen.dart';
import 'features/moodboard/presentation/moodboard_screen.dart';
import 'features/habits/presentation/habits_screen.dart';
import 'features/shopping/presentation/shopping_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/presentation/archived_hidden_vault.dart';

import 'dart:async';
import 'core/services/sanctuary_supabase_service.dart';
import 'core/enterprise/app_config.dart';
import 'core/enterprise/sanctuary_logger.dart';
import 'core/enterprise/sanctuary_error_boundary.dart';
import 'core/enterprise/audit_ledger_engine.dart';
import 'core/enterprise/enterprise_shortcuts.dart';
import 'features/settings/presentation/enterprise_governance_screen.dart';
import 'features/settings/presentation/grand_master_luxury_suite_screen.dart';

enum AppStage { logoReveal, onboarding, signIn, appShell }

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Enterprise Structured Logger & Session Correlation
    final sessionId = 'SES-${DateTime.now().toUtc().millisecondsSinceEpoch}';
    SanctuaryLogger().setCorrelationId(sessionId);
    SanctuaryLogger().info('Bootstrap', 'Bootstrapping ${AppConfig.appName} in ${AppConfig.environment.name} mode.');

    // 2. Hook Flutter framework exceptions
    FlutterError.onError = (details) {
      SanctuaryLogger().error(
        'FlutterFramework',
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // 3. Hook PlatformDispatcher exceptions
    PlatformDispatcher.instance.onError = (error, stack) {
      SanctuaryLogger().error(
        'PlatformDispatcher',
        'Unhandled platform fault',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    GoogleFonts.config.allowRuntimeFetching = true;

    // 4. Initialize Cloud / Local Resilient Services
    await SanctuarySupabaseService().initialize(
      supabaseUrl: AppConfig.supabaseUrl,
      supabaseAnonKey: AppConfig.supabasePublishableKey,
    );

    // 5. Append Genesis Startup Block to Audit Chain
    AuditLedgerEngine().recordEvent(
      actorId: 'SYSTEM_BOOT',
      action: 'APP_INITIALIZED',
      resource: 'SANCTUARY_CORE',
      metadata: {
        'flavor': AppConfig.environment.name,
        'version': AppConfig.appVersion,
        'session': sessionId,
      },
    );

    runApp(
      const ProviderScope(
        child: SanctuaryErrorBoundary(
          child: NOTtEodoApp(),
        ),
      ),
    );
  }, (error, stack) {
    SanctuaryLogger().error(
      'ZoneGuarded',
      'Asynchronous zone exception caught',
      error: error,
      stackTrace: stack,
    );
  });
}

class NOTtEodoApp extends StatefulWidget {
  const NOTtEodoApp({super.key});

  @override
  State<NOTtEodoApp> createState() => _NOTtEodoAppState();
}

class _NOTtEodoAppState extends State<NOTtEodoApp> {
  AppStage _stage = AppStage.logoReveal;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTtEodo — Notes. Tasks. Life.',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const SanctuaryScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppDarkTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildStageScreen(),
      ),
    );
  }

  Widget _buildStageScreen() {
    switch (_stage) {
      case AppStage.logoReveal:
        return LogoRevealScreen(
          key: const ValueKey('logoReveal'),
          onRevealComplete: () {
            setState(() => _stage = AppStage.onboarding);
          },
        );
      case AppStage.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinishOnboarding: () {
            setState(() => _stage = AppStage.signIn);
          },
        );
      case AppStage.signIn:
        return SignInScreen(
          key: const ValueKey('signIn'),
          onAuthenticated: () {
            setState(() => _stage = AppStage.appShell);
          },
        );
      case AppStage.appShell:
        return MainShellScreen(
          key: const ValueKey('appShell'),
          isDarkMode: _isDarkMode,
          onToggleDarkMode: (val) {
            setState(() => _isDarkMode = val);
          },
          onLogout: () {
            setState(() => _stage = AppStage.signIn);
          },
        );
    }
  }
}

class MainShellScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onLogout;

  const MainShellScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onLogout,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}class _MainShellScreenState extends State<MainShellScreen> {
  int _activeIndex = 0;
  bool _aiModalOpen = false;
  bool _dedicatedCreationOpen = false;
  bool _searchOpen = false;
  bool _quickDialOpen = false;
  String _aiContext = 'Global';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppAlertEngine().checkForTriggeredAlerts(context);
    });
  }

  void _openAiModal(String scope) {
    setState(() {
      _aiContext = scope;
      _aiModalOpen = true;
    });
  }

  void _handleDedicatedAdd() {
    setState(() {
      _dedicatedCreationOpen = true;
    });
  }

  void _handleQuickAction(String action) {
    setState(() {
      switch (action) {
        case 'Note':
          _activeIndex = 1;
          break;
        case 'Task':
          _activeIndex = 2;
          break;
        case 'Event':
          _activeIndex = 3;
          break;
        case 'Wardrobe':
          _activeIndex = 4;
          break;
        case 'Expense':
          _activeIndex = 5;
          break;
        case 'Memoir':
          _activeIndex = 7;
          break;
        case 'Pin':
          _activeIndex = 8;
          break;
        case 'Shopping':
          _activeIndex = 10;
          break;
      }
      _dedicatedCreationOpen = true;
    });
    AppToastEngine().showToast(
      context,
      title: 'Sanctuary $action Studio',
      message: 'Opened dedicated creation canvas for $action',
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerTextColor = widget.isDarkMode ? const Color(0xFFF4F1EA) : AppColors.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AppToastOverlay(
      child: TimeSkyHeader(
        child: EnterpriseShortcutsWrapper(
          onOpenSearch: () {
            setState(() => _searchOpen = !_searchOpen);
          },
          onDedicatedAdd: _handleDedicatedAdd,
          onToggleQuickDial: () {
            setState(() => _quickDialOpen = !_quickDialOpen);
          },
          onOpenEnterpriseGovernance: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnterpriseGovernanceScreen()),
            );
          },
          onOpenGrandMasterSuite: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrandMasterLuxurySuiteScreen()),
            );
          },
          onToggleDarkMode: () {
            widget.onToggleDarkMode(!widget.isDarkMode);
          },
          onCloseOverlays: () {
            if (_searchOpen || _quickDialOpen || _dedicatedCreationOpen || _aiModalOpen) {
              setState(() {
                _searchOpen = false;
                _quickDialOpen = false;
                _dedicatedCreationOpen = false;
                _aiModalOpen = false;
              });
            } else if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
          },
          onSelectModule: (index) {
            setState(() => _activeIndex = index);
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            drawer: !isDesktop
                ? AppDrawer(
                    activeIndex: _activeIndex,
                    isDarkMode: widget.isDarkMode,
                    onToggleDarkMode: widget.onToggleDarkMode,
                    onLogout: _handleLogout,
                    onSelectModule: (index) {
                      setState(() {
                        _activeIndex = index;
                      });
                    },
                  )
                : null,
            body: SanctuaryCursorTracer(
              child: KineticAmbientCanvas(
                child: RepaintBoundary(
                  child: AmbientParticleCanvas(
                    child: isDesktop
                        ? _buildDesktopLayout(headerTextColor)
                        : _buildMobileLayout(headerTextColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Color headerTextColor) {
    return Row(
      children: [
        SanctuaryDesktopRail(
          activeIndex: _activeIndex,
          isDarkMode: widget.isDarkMode,
          onToggleDarkMode: widget.onToggleDarkMode,
          onLogout: _handleLogout,
          onSelectModule: (index) {
            setState(() => _activeIndex = index);
          },
        ),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  // Desktop Workstation Top Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getModuleName(_activeIndex).toUpperCase(),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.2,
                                color: headerTextColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (widget.isDarkMode ? const Color(0xFFEAB368) : AppColors.secondary).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'HOTKEY: ⌘+${_activeIndex <= 4 ? (_activeIndex + 1) : "K"}',
                                style: GoogleFonts.courierPrime(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isDarkMode ? const Color(0xFFEAB368) : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CelestialHorizonDial(isDark: widget.isDarkMode),
                            const SizedBox(width: 10),
                            const RepaintBoundary(child: FlipClockWidget()),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(LucideIcons.search, color: headerTextColor, size: 20),
                              tooltip: 'Search Sanctuary (Ctrl + K)',
                              onPressed: () => setState(() => _searchOpen = true),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _activeIndex = 12),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondary.withValues(alpha: 0.2),
                                  border: Border.all(color: AppColors.secondary, width: 1.5),
                                ),
                                child: Center(
                                  child: Text('A', style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: widget.isDarkMode ? const Color(0xFF1E2832) : const Color(0xFFE8DFC8)),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_activeIndex),
                        child: _buildActiveScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const RepaintBoundary(child: FloatingVoiceAiWidget()),
              ..._buildSharedModals(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Color headerTextColor) {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.menu, color: headerTextColor, size: 24),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    const StitchLogoWidget(fontSize: 22, showMonogramN: true),
                    Row(
                      children: [
                        CelestialHorizonDial(isDark: widget.isDarkMode),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(LucideIcons.search, color: headerTextColor, size: 19),
                          tooltip: 'Search Sanctuary (Ctrl + K)',
                          onPressed: () {
                            setState(() => _searchOpen = true);
                          },
                        ),
                        const SizedBox(width: 2),
                        const RepaintBoundary(child: FlipClockWidget()),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_activeIndex),
                    child: _buildActiveScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const RepaintBoundary(child: FloatingVoiceAiWidget()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: RepaintBoundary(
            child: SanctuaryBottomDock(
              activeIndex: _activeIndex,
              isQuickDialOpen: _quickDialOpen,
              onToggleQuickDial: () {
                setState(() => _quickDialOpen = !_quickDialOpen);
              },
              onTabSelected: (index) {
                setState(() {
                  _activeIndex = index;
                  if (_quickDialOpen) _quickDialOpen = false;
                });
              },
              onDedicatedAddTapped: _handleDedicatedAdd,
              onOpenSearch: () {
                setState(() => _searchOpen = true);
              },
              onOpenAi: () => _openAiModal('Global'),
              onQuickAction: _handleQuickAction,
            ),
          ),
        ),
        ..._buildSharedModals(),
      ],
    );
  }

  List<Widget> _buildSharedModals() {
    return [
      if (_quickDialOpen)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _quickDialOpen = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Stack(
                  children: [
                    RadialQuickAddMenu(
                      isOpen: true,
                      onClose: () => setState(() => _quickDialOpen = false),
                      onActionSelected: (action) {
                        setState(() => _quickDialOpen = false);
                        _handleQuickAction(action);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (_dedicatedCreationOpen)
        DedicatedCreationScreen(
          activeIndex: _activeIndex,
          onClose: () {
            setState(() {
              _dedicatedCreationOpen = false;
            });
          },
          onItemSaved: (itemTitle) {
            AppToastEngine().showToast(
              context,
              title: 'Sanctuary Entry Sealed',
              message: '"$itemTitle" created in active sanctuary module!',
            );
          },
        ),
      if (_aiModalOpen)
        ScopedAiDialog(
          contextScope: _aiContext,
          onClose: () {
            setState(() {
              _aiModalOpen = false;
            });
          },
        ),
      if (_searchOpen)
        UniversalSearchDialog(
          onClose: () {
            setState(() {
              _searchOpen = false;
            });
          },
          onNavigateToModule: (moduleIndex) {
            setState(() {
              _activeIndex = moduleIndex;
              _searchOpen = false;
            });
          },
        ),
    ];
  }

  String _getModuleName(int index) {
    switch (index) {
      case 0:
        return 'Home Overview';
      case 1:
        return 'Notes & Spaces';
      case 2:
        return 'Tasks & Wax Stamps';
      case 3:
        return 'Planner Ribbon Dial';
      case 4:
        return 'Wardrobe Lookbook';
      case 5:
        return 'Expenses & Receipts';
      case 6:
        return 'Travel & Voyages';
      case 7:
        return 'Voice Journal Memoirs';
      case 8:
        return 'Moodboard Pins';
      case 9:
        return 'Habits & Streaks';
      case 10:
        return 'Shopping Tally Tags';
      case 11:
        return 'Settings & Security Audit';
      case 12:
        return 'Curator Sanctuary Profile';
      case 13:
        return 'Protected Archive Vault';
      default:
        return 'Sanctuary Workspace';
    }
  }

  Widget _buildActiveScreen() {
    switch (_activeIndex) {
      case 0:
        return HomeScreen(onOpenAiModal: _openAiModal);
      case 1:
        return NotesScreen(onOpenAiModal: _openAiModal);
      case 2:
        return const TasksScreen();
      case 3:
        return const PlannerScreen();
      case 4:
        return const WardrobeScreen();
      case 5:
        return const ExpensesScreen();
      case 6:
        return TravelScreen(onOpenAiModal: _openAiModal);
      case 7:
        return const JournalScreen();
      case 8:
        return const MoodboardScreen();
      case 9:
        return const HabitsScreen();
      case 10:
        return const ShoppingScreen();
      case 11:
        return const SettingsScreen();
      case 12:
        return ProfileScreen(onLogout: _handleLogout);
      case 13:
        return ArchivedHiddenVault(onClose: () => setState(() => _activeIndex = 0));
      default:
        return HomeScreen(onOpenAiModal: _openAiModal);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? AppColors.darkSurface : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Seal & Log Out Curator?',
          style: GoogleFonts.bodoniModa(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? AppColors.darkTextPrimary : AppColors.primary,
          ),
        ),
        content: Text(
          'Your sanctuary session will be sealed. You can sign back in anytime to restore your notes, wardrobe lookbooks, and journal memoirs.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: widget.isDarkMode ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activeIndex = 0;
              });
              widget.onLogout();
              AppToastEngine().showToast(
                context,
                title: 'Sanctuary Sealed',
                message: 'Curator session logged out cleanly.',
              );
            },
            child: Text('Seal & Log Out', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
