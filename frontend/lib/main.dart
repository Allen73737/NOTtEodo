import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_dark_theme.dart';
import 'app/theme/app_motion_theme.dart';
import 'core/motion/motion.dart';

import 'core/security/security_controller.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/local_store.dart';
import 'core/services/reminder_service.dart';
import 'core/state/app_settings.dart';
import 'core/state/sanctuary_state.dart';
import 'core/widgets/sanctuary_bottom_dock.dart';
import 'core/widgets/radial_quick_add.dart';
import 'core/widgets/app_drawer.dart';
import 'core/widgets/scoped_ai_dialog.dart';
import 'core/widgets/dedicated_creation_screen.dart';
import 'core/widgets/floating_voice_ai_widget.dart';
import 'core/widgets/flip_clock_widget.dart';
import 'core/widgets/app_toast_engine.dart';
import 'core/widgets/universal_search_dialog.dart';
import 'core/performance/sanctuary_motion_engine.dart';
import 'core/widgets/celestial_horizon_dial.dart';
import 'core/widgets/sanctuary_desktop_rail.dart';

import 'features/auth/presentation/logo_reveal_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/signin_screen.dart';
import 'features/auth/presentation/app_lock_screen.dart';

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
import 'features/bin/presentation/bin_screen.dart';

import 'dart:async';
import 'core/services/sanctuary_supabase_service.dart';
import 'core/enterprise/app_config.dart';
import 'core/enterprise/sanctuary_logger.dart';
import 'core/enterprise/sanctuary_error_boundary.dart';
import 'core/enterprise/audit_ledger_engine.dart';
import 'core/enterprise/enterprise_shortcuts.dart';
import 'features/settings/presentation/enterprise_governance_screen.dart';
import 'features/settings/presentation/grand_master_luxury_suite_screen.dart';

enum AppStage { logoReveal, onboarding, signIn, locked, appShell }

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

    // 4. Load on-device data before the first frame so every module starts from what was saved.
    await LocalStore().init();
    final container = ProviderContainer();

    // 5. Cloud sign-in/sync is optional; it starts in the background once the client is ready.
    unawaited(SanctuarySupabaseService()
        .initialize(
          supabaseUrl: AppConfig.resolvedSupabaseUrl,
          supabaseAnonKey: AppConfig.resolvedSupabasePublishableKey,
        )
        .then((_) => CloudSyncService().start(onReload: () => reloadAllFromStore(container))));

    // 6. Due tasks, upcoming events and habit times raise reminders while the app is open.
    ReminderService().start(ReminderSources(
      tasks: () => container.read(tasksProvider),
      events: () => container.read(eventsProvider),
      habits: () => container.read(habitsProvider),
      enabled: () => container.read(appSettingsProvider).remindersEnabled,
    ));

    // 7. Append Genesis Startup Block to Audit Chain
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
      UncontrolledProviderScope(
        container: container,
        child: const SanctuaryErrorBoundary(
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

class NOTtEodoApp extends ConsumerStatefulWidget {
  const NOTtEodoApp({super.key});

  @override
  ConsumerState<NOTtEodoApp> createState() => _NOTtEodoAppState();
}

class _NOTtEodoAppState extends ConsumerState<NOTtEodoApp> with WidgetsBindingObserver {
  AppStage _stage = AppStage.logoReveal;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Auto-lock bookkeeping.
  DateTime _lastActivity = DateTime.now();
  DateTime? _hiddenAt;
  Timer? _idleTimer;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _idleTimer = Timer.periodic(const Duration(seconds: 20), (_) => _checkIdle());
    ScreenPrivacy.setSecure(ref.read(appSettingsProvider).blockScreenshots);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- App lock ----------------------------------------------------------------

  bool get _lockEnabled => LocalStore().hasPin && LocalStore().isReady;

  Duration get _autoLockAfter => Duration(minutes: ref.read(appSettingsProvider).autoLockMinutes);

  /// Covers the UI in the OS app switcher (mobile only; on the web a blurred
  /// window is not a privacy event and the overlay would just flicker).
  bool get _shieldSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_shieldSupported && ref.read(appSettingsProvider).privacyShield) {
      final obscure = state != AppLifecycleState.resumed;
      if (obscure != _obscured) setState(() => _obscured = obscure);
    }
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _hiddenAt ??= DateTime.now();
      if (_lockEnabled && _autoLockAfter == Duration.zero) _lock();
    } else if (state == AppLifecycleState.resumed) {
      final hiddenAt = _hiddenAt;
      _hiddenAt = null;
      _lastActivity = DateTime.now();
      if (hiddenAt != null && _lockEnabled && DateTime.now().difference(hiddenAt) >= _autoLockAfter) _lock();
    }
  }

  void _checkIdle() {
    if (!_lockEnabled || _stage != AppStage.appShell) return;
    final after = _autoLockAfter == Duration.zero ? const Duration(minutes: 1) : _autoLockAfter;
    if (DateTime.now().difference(_lastActivity) >= after) _lock();
  }

  Future<void> _lock() async {
    if (_stage == AppStage.locked || !_lockEnabled) return;
    await LocalStore().lock();
    if (!mounted) return;
    // Pages and dialogs pushed above the shell would otherwise stay on top of the lock screen.
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() => _stage = AppStage.locked);
    // Drop decrypted items from memory once the shell has faded out.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && LocalStore().isLocked) resetAllProviders(ref);
    });
  }

  /// Runs once the vault is open: load the decrypted data, then continue where the user belongs.
  void _onUnlocked() {
    _lastActivity = DateTime.now();
    ref.read(appSettingsProvider.notifier).reloadFromStore();
    reloadAllFromStore(ref);
    ScreenPrivacy.setSecure(ref.read(appSettingsProvider).blockScreenshots);
    unawaited(CloudSyncService().syncNow());
    setState(() => _stage = ref.read(appSettingsProvider).onboarded ? AppStage.appShell : AppStage.onboarding);
  }

  void _showStartupNotice() {
    final notice = LocalStore().startupNotice;
    if (notice == null) return;
    LocalStore().startupNotice = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx == null) return;
      showDialog<void>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: const Text('Started with a fresh vault'),
          content: Text(notice),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
    });
  }

  /// Follow the OS theme live while the setting is "System".
  @override
  void didChangePlatformBrightness() {
    if (ref.read(appSettingsProvider).themeMode == ThemeMode.system && mounted) setState(() {});
  }

  static bool _resolveDark(ThemeMode mode) => mode == ThemeMode.system
      ? PlatformDispatcher.instance.platformBrightness == Brightness.dark
      : mode == ThemeMode.dark;

  /// For use in build.
  bool get _isDarkMode => _resolveDark(ref.watch(appSettingsProvider.select((s) => s.themeMode)));

  final GlobalKey<ThemeWashState> _themeWashKey = GlobalKey<ThemeWashState>();

  /// Flips the theme behind an ink wash that blooms from the last touch point, and remembers it.
  void _setDarkMode(bool value) {
    if (value == _resolveDark(ref.read(appSettingsProvider).themeMode)) return;
    final wash = _themeWashKey.currentState;
    void apply() {
      if (mounted) ref.read(appSettingsProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    }

    if (wash == null) {
      apply();
    } else {
      wash.play(toDark: value, apply: apply);
    }
  }

  /// Where to go once the logo has played (or after sign-in).
  AppStage _entryStage() {
    // A PIN-locked vault cannot even tell whether onboarding happened until it is opened.
    if (LocalStore().isLocked) return AppStage.locked;
    _showStartupNotice();
    final settings = ref.read(appSettingsProvider);
    return settings.onboarded ? AppStage.appShell : AppStage.onboarding;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(appSettingsProvider.select((s) => s.reducedMotion));
    ref.listen<bool>(appSettingsProvider.select((s) => s.blockScreenshots), (_, on) => ScreenPrivacy.setSecure(on));
    return ThemeWash(
      key: _themeWashKey,
      reduceMotion: reduceMotion,
      child: MaterialApp(
        title: 'NOTtEodo â€” Notes. Tasks. Life.',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const SanctuaryScrollBehavior(),
        theme: AppMotionTheme.apply(AppTheme.lightTheme, dark: false),
        darkTheme: AppMotionTheme.apply(AppDarkTheme.darkTheme, dark: true),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        themeAnimationDuration: const Duration(milliseconds: 420),
        themeAnimationCurve: Curves.easeInOutCubic,
        navigatorKey: _navigatorKey,
        builder: (context, child) {
          Widget content = TouchAura(isDark: _isDarkMode, child: child ?? const SizedBox.shrink());
          // Any touch, scroll or key press counts as activity for auto-lock.
          content = Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _lastActivity = DateTime.now(),
            onPointerSignal: (_) => _lastActivity = DateTime.now(),
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (_, __) {
                _lastActivity = DateTime.now();
                return KeyEventResult.ignored;
              },
              child: content,
            ),
          );
          if (_obscured) {
            content = Stack(children: [content, Positioned.fill(child: _PrivacyShield(isDark: _isDarkMode))]);
          }
          if (!reduceMotion) return content;
          // Every Reveal, presence and transition in the motion system reads this flag.
          return MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: content);
        },
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          reverseDuration: const Duration(milliseconds: 380),
          switchInCurve: Motion.silk,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.04, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildStageScreen(),
        ),
      ),
    );
  }

  Widget _buildStageScreen() {
    switch (_stage) {
      case AppStage.logoReveal:
        return LogoRevealScreen(
          key: const ValueKey('logoReveal'),
          isDarkMode: _isDarkMode,
          onRevealComplete: () {
            setState(() => _stage = _entryStage());
          },
        );
      case AppStage.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onFinishOnboarding: () {
            ref.read(appSettingsProvider.notifier).completeOnboarding();
            setState(() => _stage = AppStage.signIn);
          },
        );
      case AppStage.signIn:
        return SignInScreen(
          key: const ValueKey('signIn'),
          onAuthenticated: () {
            unawaited(CloudSyncService().syncNow());
            setState(() => _stage = AppStage.appShell);
          },
        );
      case AppStage.locked:
        return AppLockScreen(
          key: const ValueKey('locked'),
          onUnlocked: _onUnlocked,
          onReset: () {
            resetAllProviders(ref);
            ref.invalidate(securityProvider);
            setState(() => _stage = AppStage.onboarding);
          },
        );
      case AppStage.appShell:
        return MainShellScreen(
          key: const ValueKey('appShell'),
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _setDarkMode,
          onLogout: () async {
            // Only a real sign-out resets sync; going to sign-in from local-only mode keeps
            // this device's unsynced edits so they are merged into the account.
            if (SanctuarySupabaseService().currentUser != null) {
              await SanctuarySupabaseService().signOut();
              CloudSyncService().resetForAccountChange();
            }
            if (mounted) setState(() => _stage = AppStage.signIn);
          },
        );
    }
  }
}

/// Covers the app in the OS task switcher so its snapshot shows nothing personal.
class _PrivacyShield extends StatelessWidget {
  final bool isDark;
  const _PrivacyShield({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(
          color: (isDark ? Colors.black : AppColors.background).withValues(alpha: 0.86),
          child: Center(
            child: Icon(LucideIcons.lock,
                size: 40, color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onLogout;
  final int initialIndex;

  const MainShellScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onLogout,
    this.initialIndex = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _activeIndex = widget.initialIndex;
  bool _aiModalOpen = false;
  bool _dedicatedCreationOpen = false;
  bool _searchOpen = false;
  bool _quickDialOpen = false;

  /// Mobile dock tucks away while reading (scrolling down) and returns on scroll up.
  bool _dockVisible = true;

  bool _onContentScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final atTop = n.metrics.pixels <= n.metrics.minScrollExtent + 24;
    final show = atTop || n.direction == ScrollDirection.forward;
    final hide = !atTop && n.direction == ScrollDirection.reverse;
    if (show && !_dockVisible) setState(() => _dockVisible = true);
    if (hide && _dockVisible) setState(() => _dockVisible = false);
    return false;
  }
  String _aiContext = 'Global';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
          backgroundColor: widget.isDarkMode ? const Color(0xFF000000) : AppColors.background,
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
          body: isDesktop
              ? _buildDesktopLayout(headerTextColor)
              : _buildMobileLayout(headerTextColor),
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
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                // Module title rolls up into place on every switch.
                                child: AnimatedSwitcher(
                                  duration: Motion.standard,
                                  switchInCurve: Motion.silk,
                                  transitionBuilder: (child, animation) => FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(animation),
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    _getModuleName(_activeIndex).toUpperCase(),
                                    key: ValueKey(_activeIndex),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.bodoniModa(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: headerTextColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (widget.isDarkMode ? const Color(0xFFE8927C) : AppColors.secondary).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'âŒ˜+${_activeIndex <= 4 ? (_activeIndex + 1) : "K"}',
                                  style: GoogleFonts.courierPrime(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isDarkMode ? const Color(0xFFE8927C) : AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Decorative instruments yield space first; the controls after
                              // them stay pinned and always reachable.
                              Flexible(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  reverse: true,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CelestialHorizonDial(isDark: widget.isDarkMode),
                                      const SizedBox(width: 10),
                                      const RepaintBoundary(child: FlipClockWidget()),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Sleek Raycast-Grade Search Command Pill
                              Pressable(
                                pressedScale: 0.97,
                                child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() => _searchOpen = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF1EDE4),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: widget.isDarkMode ? const Color(0xFF222222) : const Color(0xFFDFD8C8),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.search, size: 14, color: headerTextColor.withValues(alpha: 0.7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Search...',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: headerTextColor.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode ? Colors.black45 : Colors.white70,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: widget.isDarkMode ? Colors.white12 : Colors.black12,
                                          ),
                                        ),
                                        child: Text(
                                          'âŒ˜K',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: headerTextColor.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ),
                              const SizedBox(width: 8),
                              // Theme Switcher Button
                              IconButton(
                                icon: _ThemeGlyph(
                                  isDark: widget.isDarkMode,
                                  color: headerTextColor,
                                  size: 19,
                                ),
                                tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                                onPressed: () {
                                  SanctuaryHapticEngine.dialDetent();
                                  widget.onToggleDarkMode(!widget.isDarkMode);
                                },
                              ),
                              const SizedBox(width: 6),
                              // Curator Monogram Profile
                              Pressable(
                                onTap: () => setState(() => _activeIndex = 12),
                                pressedScale: 0.9,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.secondary.withValues(alpha: 0.2),
                                    border: Border.all(color: AppColors.secondary, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Consumer(
                                      builder: (context, ref, _) => Text(
                                        ref.watch(appSettingsProvider.select((s) => s.initial)),
                                        style: GoogleFonts.bodoniModa(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                  Divider(height: 1, color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8DFC8)),
                  Expanded(
                    child: ModuleSwitcher(
                      index: _activeIndex,
                      child: _buildActiveScreen(),
                    ),
                  ),
                ],
              ),
              const FloatingVoiceAiWidget(bottom: 24, right: 24),
              ..._buildSharedModals(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Color headerTextColor) {
    final isDark = widget.isDarkMode;

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              // Ultra-Refined, Prominent Sanctuary Mobile Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF000000).withValues(alpha: 0.95) : const Color(0xFFFAF8F5).withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8DFC8).withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Distinct, High-Contrast Curator Hamburger Menu Button + Title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Pressable(
                          child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF121212) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.menu,
                                  color: isDark ? const Color(0xFFFAF8F5) : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'NOTtEodo',
                              style: GoogleFonts.bodoniModa(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: headerTextColor,
                              ),
                            ),
                            Text(
                              'WORKSPACE',
                              style: GoogleFonts.dmSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Clean, High-Contrast Action Pod
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search trigger
                        Pressable(
                          child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _searchOpen = true),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF121212) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2),
                                  width: 1.0,
                                ),
                              ),
                              child: Icon(LucideIcons.search, size: 18, color: headerTextColor),
                            ),
                          ),
                        ),
                        ),
                        const SizedBox(width: 8),

                        // Light / Dark Canvas Toggle
                        Pressable(
                          child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onToggleDarkMode(!isDark);
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF121212) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF262626) : const Color(0xFFE2DDD2),
                                  width: 1.0,
                                ),
                              ),
                              child: _ThemeGlyph(
                                isDark: isDark,
                                size: 18,
                                color: headerTextColor,
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: _onContentScroll,
                  child: ModuleSwitcher(
                    index: _activeIndex,
                    child: _buildActiveScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            offset: Offset(0, _dockVisible || _quickDialOpen ? 0 : 1.25),
            duration: const Duration(milliseconds: 420),
            curve: Motion.silk,
            child: AnimatedOpacity(
              opacity: _dockVisible || _quickDialOpen ? 1 : 0,
              duration: const Duration(milliseconds: 260),
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
                  _dockVisible = true;
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
          ),
        ),
        // Positioned safely above the bottom dock on mobile to avoid overlap
        const FloatingVoiceAiWidget(bottom: 84, right: 18),
        ..._buildSharedModals(),
      ],
    );
  }

  List<Widget> _buildSharedModals() {
    // Each overlay stays mounted inside a MotionPresence so it can animate out, not just in.
    return [
      Positioned.fill(
        child: MotionPresence(
          visible: _quickDialOpen,
          style: PresenceStyle.fade,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _quickDialOpen = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.70),
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
      Positioned.fill(
        child: MotionPresence(
          visible: _dedicatedCreationOpen,
          style: PresenceStyle.sheet,
          child: DedicatedCreationScreen(
            activeIndex: _activeIndex,
            onClose: () {
              setState(() {
                _dedicatedCreationOpen = false;
              });
            },
            onItemSaved: (itemTitle) {
              AppToastEngine().showToast(
                context,
                title: 'Saved',
                message: '"$itemTitle" created successfully.',
              );
            },
          ),
        ),
      ),
      Positioned.fill(
        child: MotionPresence(
          visible: _aiModalOpen,
          style: PresenceStyle.dialog,
          child: ScopedAiDialog(
            contextScope: _aiContext,
            onClose: () {
              setState(() {
                _aiModalOpen = false;
              });
            },
          ),
        ),
      ),
      Positioned.fill(
        child: MotionPresence(
          visible: _searchOpen,
          style: PresenceStyle.palette,
          child: UniversalSearchDialog(
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
        ),
      ),
    ];
  }

  String _getModuleName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Notes';
      case 2:
        return 'Tasks';
      case 3:
        return 'Planner';
      case 4:
        return 'Wardrobe';
      case 5:
        return 'Expenses';
      case 6:
        return 'Travel';
      case 7:
        return 'Journal';
      case 8:
        return 'Moodboard';
      case 9:
        return 'Habits';
      case 10:
        return 'Shopping';
      case 11:
        return 'Settings';
      case 12:
        return 'Profile';
      case 13:
        return 'Vault';
      case 14:
        return 'Bin';
      default:
        return 'Workspace';
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
      case 14:
        return BinScreen(onOpenModule: (index) => setState(() => _activeIndex = index));
      default:
        return HomeScreen(onOpenAiModal: _openAiModal);
    }
  }

  void _handleLogout() {
    // Not signed in: this is the way to the sign-in screen, nothing to confirm.
    if (SanctuarySupabaseService().currentUser == null) {
      widget.onLogout();
      return;
    }
    showSanctuaryDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? AppColors.darkSurface : AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log Out?',
          style: GoogleFonts.bodoniModa(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? AppColors.darkTextPrimary : AppColors.primary,
          ),
        ),
        content: Text(
          'You will be signed out and sync will stop. Everything stays on this device; sign in again any time to resume syncing.',
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
                title: 'Logged Out',
                message: 'You have been successfully logged out.',
              );
            },
            child: Text('Log Out', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Sun/moon glyph that turns and cross-fades as the theme flips.
class _ThemeGlyph extends StatelessWidget {
  final bool isDark;
  final double size;
  final Color color;

  const _ThemeGlyph({required this.isDark, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Motion.settle,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => RotationTransition(
        turns: Tween(begin: -0.35, end: 0.0).animate(animation),
        child: ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: Icon(
        isDark ? LucideIcons.sun : LucideIcons.moon,
        key: ValueKey(isDark),
        size: size,
        color: color,
      ),
    );
  }
}
