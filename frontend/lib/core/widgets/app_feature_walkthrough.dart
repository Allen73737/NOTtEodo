import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';

class WalkthroughStep {
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String actionLabel;
  final int? targetModuleIndex; // 0: Home, 1: Notes, 2: Tasks, 3: Planner, etc.

  const WalkthroughStep({
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.actionLabel,
    this.targetModuleIndex,
  });
}

class AppFeatureWalkthroughModal extends StatefulWidget {
  final ValueChanged<int>? onNavigateModule;
  final VoidCallback? onTriggerNodo;
  final VoidCallback? onTriggerVoice;
  final VoidCallback onDismiss;

  const AppFeatureWalkthroughModal({
    super.key,
    required this.onDismiss,
    this.onNavigateModule,
    this.onTriggerNodo,
    this.onTriggerVoice,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<int>? onNavigateModule,
    VoidCallback? onTriggerNodo,
    VoidCallback? onTriggerVoice,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Walkthrough',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => AppFeatureWalkthroughModal(
        onDismiss: () => Navigator.of(ctx).pop(),
        onNavigateModule: onNavigateModule,
        onTriggerNodo: onTriggerNodo,
        onTriggerVoice: onTriggerVoice,
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  State<AppFeatureWalkthroughModal> createState() => _AppFeatureWalkthroughModalState();
}

class _AppFeatureWalkthroughModalState extends State<AppFeatureWalkthroughModal> {
  int _currentStep = 0;

  static const List<WalkthroughStep> _steps = [
    WalkthroughStep(
      title: 'COMMAND CENTER',
      headline: 'Homescreen & Daily Focus',
      description:
          'Your central dashboard displays today\'s top priorities, recent notes, and budget health. Filter your view with one tap between Focus, Treasury, and Lifestyle.',
      icon: LucideIcons.layoutDashboard,
      actionLabel: 'Go to Homescreen',
      targetModuleIndex: 0,
    ),
    WalkthroughStep(
      title: 'APP NAVIGATION',
      headline: 'Dedicated Feature Modules',
      description:
          'Access Notes with tactile spaces, Tasks with Eisenhower urgency, Intelligent Planner with calendar sync, Treasury budget envelopes, Wardrobe, and Journal.',
      icon: LucideIcons.layers,
      actionLabel: 'Explore Notes & Spaces',
      targetModuleIndex: 1,
    ),
    WalkthroughStep(
      title: 'NODO AI COMPANION',
      headline: 'Meet Nodo: Roaming AI Assistant',
      description:
          'Nodo is your animated circular companion. It roams gently across your screen, offers helpful suggestions, summarizes notes, and breaks down complex goals.',
      icon: LucideIcons.sparkles,
      actionLabel: 'Interact with Nodo',
    ),
    WalkthroughStep(
      title: 'HANDS-FREE CAPTURE',
      headline: 'Voice Capture & Quick Add',
      description:
          'Tap the microphone dial to dictate tasks or notes on the fly. Natural language processing automatically extracts dates like "tomorrow 3pm".',
      icon: LucideIcons.mic,
      actionLabel: 'Try Voice Capture',
    ),
    WalkthroughStep(
      title: 'CUSTOMIZATION',
      headline: 'Universal Fonts & System Reminders',
      description:
          'Personalize typography with universal and per-section font selectors, enable Duolingo-style daily engagement notifications, and choose your favorite audio tones.',
      icon: LucideIcons.slidersHorizontal,
      actionLabel: 'Open Settings & Fonts',
      targetModuleIndex: 11, // Settings
    ),
  ];

  void _next() {
    SanctuaryHapticEngine.dialDetent();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismiss();
    }
  }

  void _prev() {
    SanctuaryHapticEngine.dialDetent();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _executeStepAction(WalkthroughStep step) {
    SanctuaryHapticEngine.dialDetent();
    if (step.targetModuleIndex != null) {
      widget.onNavigateModule?.call(step.targetModuleIndex!);
      widget.onDismiss();
    } else if (step.headline.contains('Nodo')) {
      widget.onTriggerNodo?.call();
      widget.onDismiss();
    } else if (step.headline.contains('Voice')) {
      widget.onTriggerVoice?.call();
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final cardBg = isDark ? const Color(0xFF141210) : const Color(0xFFFFFDF8);

    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: isDark ? 0.94 : 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2622) : const Color(0xFFE8DFC8),
                    width: 1.2,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Top Row: Eyebrow + Skip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          step.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: accentColor,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: subtextColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(
                          'Skip Walkthrough',
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hero Icon & Headline
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Icon(step.icon, size: 22, color: accentColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.headline,
                              style: GoogleFonts.bodoniModa(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Feature Step ${_currentStep + 1} of ${_steps.length}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    step.description,
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      height: 1.5,
                      color: primaryTextColor.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Interactive Feature Action Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _executeStepAction(step),
                      icon: Icon(step.icon, size: 15, color: accentColor),
                      label: Text(
                        step.actionLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar Indicators
                  Row(
                    children: List.generate(_steps.length, (idx) {
                      final isActive = idx == _currentStep;
                      final isPassed = idx < _currentStep;
                      return Expanded(
                        child: Container(
                          height: 3.5,
                          margin: EdgeInsets.only(right: idx < _steps.length - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isActive
                                ? accentColor
                                : (isPassed
                                    ? accentColor.withValues(alpha: 0.4)
                                    : (isDark ? Colors.white12 : Colors.black12)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Controls: Back & Next
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        TextButton.icon(
                          onPressed: _prev,
                          icon: const Icon(LucideIcons.chevronLeft, size: 16),
                          label: Text('Back', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(foregroundColor: subtextColor),
                        )
                      else
                        const SizedBox.shrink(),
                      ElevatedButton.icon(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(isLast ? LucideIcons.check : LucideIcons.chevronRight, size: 16),
                        label: Text(
                          isLast ? 'Complete Tour' : 'Next Feature',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
),
);
  }
}
