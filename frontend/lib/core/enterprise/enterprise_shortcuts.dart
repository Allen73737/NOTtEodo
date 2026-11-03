import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../motion/motion.dart';

/// Intent definitions for Enterprise Keyboard Navigation
class UniversalSearchIntent extends Intent {
  const UniversalSearchIntent();
}

class DedicatedCreationIntent extends Intent {
  const DedicatedCreationIntent();
}

class RadialDialIntent extends Intent {
  const RadialDialIntent();
}

class EnterpriseGovernanceIntent extends Intent {
  const EnterpriseGovernanceIntent();
}

class GrandMasterSuiteIntent extends Intent {
  const GrandMasterSuiteIntent();
}

class ThemeToggleIntent extends Intent {
  const ThemeToggleIntent();
}

class EscapeOverlayIntent extends Intent {
  const EscapeOverlayIntent();
}

class HelpShortcutsIntent extends Intent {
  const HelpShortcutsIntent();
}

class NavigateModuleIntent extends Intent {
  final int moduleIndex;
  const NavigateModuleIntent(this.moduleIndex);
}

/// Enterprise Keyboard Shortcuts Wrapper
/// Provides workstation-grade hotkeys for enterprise operators & power users.
class EnterpriseShortcutsWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onOpenSearch;
  final VoidCallback onDedicatedAdd;
  final VoidCallback onToggleQuickDial;
  final VoidCallback onOpenEnterpriseGovernance;
  final VoidCallback onOpenGrandMasterSuite;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onCloseOverlays;
  final ValueChanged<int> onSelectModule;

  const EnterpriseShortcutsWrapper({
    super.key,
    required this.child,
    required this.onOpenSearch,
    required this.onDedicatedAdd,
    required this.onToggleQuickDial,
    required this.onOpenEnterpriseGovernance,
    required this.onOpenGrandMasterSuite,
    required this.onToggleDarkMode,
    required this.onCloseOverlays,
    required this.onSelectModule,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // Search / Command Palette: Ctrl+K / Cmd+K
        SingleActivator(LogicalKeyboardKey.keyK, control: true): UniversalSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true): UniversalSearchIntent(),

        // Dedicated Creation Studio: Ctrl+N / Cmd+N
        SingleActivator(LogicalKeyboardKey.keyN, control: true): DedicatedCreationIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): DedicatedCreationIntent(),

        // Radial Quick Dial: Ctrl+D / Cmd+D
        SingleActivator(LogicalKeyboardKey.keyD, control: true): RadialDialIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, meta: true): RadialDialIntent(),

        // Enterprise Governance (SOC2): Ctrl+E / Cmd+E
        SingleActivator(LogicalKeyboardKey.keyE, control: true): EnterpriseGovernanceIntent(),
        SingleActivator(LogicalKeyboardKey.keyE, meta: true): EnterpriseGovernanceIntent(),

        // Grand Master Suite: Ctrl+G / Cmd+G
        SingleActivator(LogicalKeyboardKey.keyG, control: true): GrandMasterSuiteIntent(),
        SingleActivator(LogicalKeyboardKey.keyG, meta: true): GrandMasterSuiteIntent(),

        // OLED Dark Mode Toggle: Ctrl+L / Cmd+L
        SingleActivator(LogicalKeyboardKey.keyL, control: true): ThemeToggleIntent(),
        SingleActivator(LogicalKeyboardKey.keyL, meta: true): ThemeToggleIntent(),

        // Escape: Dismiss overlays
        SingleActivator(LogicalKeyboardKey.escape): EscapeOverlayIntent(),

        // Shortcut Cheat Sheet: Ctrl+/ or Cmd+/
        SingleActivator(LogicalKeyboardKey.slash, control: true): HelpShortcutsIntent(),
        SingleActivator(LogicalKeyboardKey.slash, meta: true): HelpShortcutsIntent(),

        // Module Quick Switchers: Ctrl+1..Ctrl+5
        SingleActivator(LogicalKeyboardKey.digit1, control: true): NavigateModuleIntent(0),
        SingleActivator(LogicalKeyboardKey.digit2, control: true): NavigateModuleIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3, control: true): NavigateModuleIntent(2),
        SingleActivator(LogicalKeyboardKey.digit4, control: true): NavigateModuleIntent(3),
        SingleActivator(LogicalKeyboardKey.digit5, control: true): NavigateModuleIntent(4),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UniversalSearchIntent: CallbackAction<UniversalSearchIntent>(
            onInvoke: (_) => onOpenSearch(),
          ),
          DedicatedCreationIntent: CallbackAction<DedicatedCreationIntent>(
            onInvoke: (_) => onDedicatedAdd(),
          ),
          RadialDialIntent: CallbackAction<RadialDialIntent>(
            onInvoke: (_) => onToggleQuickDial(),
          ),
          EnterpriseGovernanceIntent: CallbackAction<EnterpriseGovernanceIntent>(
            onInvoke: (_) => onOpenEnterpriseGovernance(),
          ),
          GrandMasterSuiteIntent: CallbackAction<GrandMasterSuiteIntent>(
            onInvoke: (_) => onOpenGrandMasterSuite(),
          ),
          ThemeToggleIntent: CallbackAction<ThemeToggleIntent>(
            onInvoke: (_) => onToggleDarkMode(),
          ),
          EscapeOverlayIntent: CallbackAction<EscapeOverlayIntent>(
            onInvoke: (_) => onCloseOverlays(),
          ),
          HelpShortcutsIntent: CallbackAction<HelpShortcutsIntent>(
            onInvoke: (_) => _showShortcutsDialog(context),
          ),
          NavigateModuleIntent: CallbackAction<NavigateModuleIntent>(
            onInvoke: (intent) => onSelectModule(intent.moduleIndex),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }

  void _showShortcutsDialog(BuildContext context) {
    showSanctuaryDialog(
      context: context,
      builder: (ctx) => const EnterpriseShortcutsDialog(),
    );
  }
}

/// Haute Horlogerie Keyboard Shortcuts Dialog
class EnterpriseShortcutsDialog extends StatelessWidget {
  const EnterpriseShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0);
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    const accentColor = Color(0xFFEAB368);

    final shortcuts = [
      {'keys': 'Ctrl / âŒ˜ + K', 'desc': 'Universal Search & Command Palette'},
      {'keys': 'Ctrl / âŒ˜ + N', 'desc': 'Create New Entry'},
      {'keys': 'Ctrl / âŒ˜ + D', 'desc': 'Quick Action Menu'},
      {'keys': 'Ctrl / âŒ˜ + E', 'desc': 'Enterprise Governance & SOC2 Console'},
      {'keys': 'Ctrl / âŒ˜ + G', 'desc': 'UI Showcase & Diagnostics'},
      {'keys': 'Ctrl / âŒ˜ + L', 'desc': 'Toggle Dark / Light Theme'},
      {'keys': 'Ctrl / âŒ˜ + 1..5', 'desc': 'Switch Modules (Home..Expenses)'},
      {'keys': 'Esc', 'desc': 'Dismiss Overlays & Drawers'},
      {'keys': 'Ctrl / âŒ˜ + /', 'desc': 'Open Keyboard Shortcuts'},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.command, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Command Shortcuts',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: secondaryTextColor, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Keyboard shortcuts for quick navigation and actions',
              style: GoogleFonts.dmSans(fontSize: 12, color: secondaryTextColor),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: shortcuts.length,
                separatorBuilder: (_, __) => Divider(
                  height: 12,
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9),
                ),
                itemBuilder: (context, i) {
                  final item = shortcuts[i];
                  return Reveal(style: RevealStyle.slideIn, distance: 18, child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['desc']!,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF121212) : const Color(0xFFECE5D5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item['keys']!,
                          style: GoogleFonts.courierPrime(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ));
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Pressable(pressedScale: 0.95, hoverLift: 0, child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Dismiss',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
