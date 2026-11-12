import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/editorial/editorial_mode.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/widgets/app_toast_engine.dart';

/// Wraps any screen or flow during an Admin Audit Session.
/// Overlays a floating sovereign inspector pill that allows:
/// 1. 1-Tap return to the Admin Dashboard
/// 2. Live toggle between Editorial view and Bento Cards view to inspect layout rendering
/// 3. Live toggle between Light and Dark mode to verify contrast and colors
/// 4. 1-Tap diagnostic snapshot copied to clipboard for instant bug reporting
class ScreenAuditInspectorHost extends ConsumerWidget {
  final String screenName;
  final Widget child;
  final ValueChanged<bool>? onToggleDarkMode;

  const ScreenAuditInspectorHost({
    super.key,
    required this.screenName,
    required this.child,
    this.onToggleDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditorial = settings.cardStyle == 'editorial';
    const terracotta = Color(0xFFD9725B);

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Floating Sovereign Inspector Pill Bar
          Positioned(
            left: 14,
            bottom: 20,
            right: 14,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F2)).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE2DDD2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back to Admin
                    InkWell(
                      onTap: () {
                        SanctuaryHapticEngine.dialDetent();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: terracotta.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.arrowLeft, size: 13, color: terracotta),
                            const SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Screen Name Pill
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: terracotta,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'LIVE AUDIT',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: terracotta,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            screenName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // View Style Switcher (Editorial vs Bento Cards)
                    InkWell(
                      onTap: () {
                        toggleViewStyle(context, ref);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221E1A) : const Color(0xFFECE5D8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: terracotta.withValues(alpha: isEditorial ? 0.7 : 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEditorial ? LucideIcons.newspaper : LucideIcons.layoutGrid,
                              size: 12,
                              color: terracotta,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEditorial ? 'Editorial' : 'Cards',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isEditorial ? terracotta : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Theme Switcher (Dark vs Light)
                    InkWell(
                      onTap: () {
                        SanctuaryHapticEngine.toggleSwitch();
                        onToggleDarkMode?.call(!isDark);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221E1A) : const Color(0xFFECE5D8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          size: 13,
                          color: terracotta,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Copy Telemetry Snapshot
                    InkWell(
                      onTap: () {
                        SanctuaryHapticEngine.selection();
                        final info = 'NOTtEodo Audit Snapshot\n'
                            'Screen: $screenName\n'
                            'Theme: ${isDark ? 'Dark' : 'Light'}\n'
                            'View: ${settings.cardStyle}\n'
                            'Font Scale: ${(UiPrefs.of(settings).textScaleFactor * 100).toInt()}%\n'
                            'Time: ${DateTime.now().toIso8601String()}';
                        Clipboard.setData(ClipboardData(text: info));
                        AppToastEngine().showToast(
                          context,
                          title: 'Snapshot Copied',
                          message: 'Diagnostic telemetry copied to clipboard.',
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221E1A) : const Color(0xFFECE5D8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.clipboardCopy, size: 13, color: terracotta),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

