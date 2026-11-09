import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../performance/sanctuary_motion_engine.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

class WalkthroughStep {
  final String title;
  final String headline;
  final String badge;
  final String description;
  final String proTip;
  final List<String> highlights;
  final IconData icon;
  final String actionLabel;
  final int? targetModuleIndex; // 0: Home, 1: Notes, 2: Tasks, 3: Planner, etc.

  const WalkthroughStep({
    required this.title,
    required this.headline,
    required this.badge,
    required this.description,
    required this.proTip,
    required this.highlights,
    required this.icon,
    required this.actionLabel,
    this.targetModuleIndex,
  });
}

class AppFeatureWalkthroughModal extends StatefulWidget {
  final ValueChanged<int>? onNavigateModule;
  final VoidCallback? onTriggerNodo;
  final VoidCallback? onTriggerVoice;
  final VoidCallback? onTriggerOmniCapture;
  final VoidCallback? onToggleEditorial;
  final VoidCallback onDismiss;

  const AppFeatureWalkthroughModal({
    super.key,
    required this.onDismiss,
    this.onNavigateModule,
    this.onTriggerNodo,
    this.onTriggerVoice,
    this.onTriggerOmniCapture,
    this.onToggleEditorial,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<int>? onNavigateModule,
    VoidCallback? onTriggerNodo,
    VoidCallback? onTriggerVoice,
    VoidCallback? onTriggerOmniCapture,
    VoidCallback? onToggleEditorial,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Walkthrough',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => AppFeatureWalkthroughModal(
        onDismiss: () => Navigator.of(ctx).pop(),
        onNavigateModule: onNavigateModule,
        onTriggerNodo: onTriggerNodo,
        onTriggerVoice: onTriggerVoice,
        onTriggerOmniCapture: onTriggerOmniCapture,
        onToggleEditorial: onToggleEditorial,
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
    // Step 1: Command Center
    WalkthroughStep(
      title: '01 · COMMAND CENTER',
      headline: 'Homescreen & Morning Briefing',
      badge: 'DAILY SANCTUARY',
      description:
          'Your central briefing unifies today\'s top priorities, recent notes, active streak flames, and real-time budget health. Filter your perspective with one tap between Focus, Treasury, and Lifestyle.',
      proTip:
          'Tap the wax seal stamp each evening to complete your mindful Zen Review and lock in your daily streak.',
      highlights: [
        '1-Tap priority checklist with haptic feedback',
        'Streak flame evolution tiers & streak freezes',
        'Evening Zen Review with gratitude reflection',
      ],
      icon: LucideIcons.layoutDashboard,
      actionLabel: 'Open Homescreen',
      targetModuleIndex: 0,
    ),

    // Step 2: Dual Visual Architecture
    WalkthroughStep(
      title: '02 · ADAPTIVE PRESENTATION',
      headline: 'Dual Visual Architecture',
      badge: 'BENTO & EDITORIAL',
      description:
          'Switch instantly between two distinct aesthetic worlds: tactile 120Hz Bento Cards (spring dynamics, chamfers, and depth) or Swiss Editorial print mode (Kinfolk-inspired typography, flush margins, and quiet calm).',
      proTip:
          'Tap the "Aa" pill in the top bar, drawer, or settings to transform every screen in real time.',
      highlights: [
        'Bento Cards: 120Hz spring physics & 3D micro-haptics',
        'Swiss Editorial: Literary serif titles & flush paper rows',
        'Both modes share 100% of all data and features',
      ],
      icon: LucideIcons.columns,
      actionLabel: 'Explore Swiss Editorial',
      targetModuleIndex: 0,
    ),

    // Step 3: Omni-Capture Speed Hub
    WalkthroughStep(
      title: '03 · SMART CAPTURE',
      headline: 'Omni-Capture Speed Hub',
      badge: 'NLP ENGINE',
      description:
          'Never friction-switch between apps to write something down. Type naturally like "Dinner with Sarah \$45 tomorrow at 7pm #dining" and Notteodo\'s on-device NLP parser automatically routes everything.',
      proTip:
          'Tap the floating lightning bolt or long-press the NOTtEodo launcher icon on Android for instant capture.',
      highlights: [
        'Natural-language date & time extraction',
        'Automatic dollar/rupee price detection & categorization',
        'Universal #tag indexing across your entire sanctuary',
      ],
      icon: LucideIcons.zap,
      actionLabel: 'Launch Omni-Capture',
    ),

    // Step 4: Tactile Notes & 3D Moodboards
    WalkthroughStep(
      title: '04 · CREATIVE CANVAS',
      headline: 'Notes, Vault & 3D Moodboards',
      badge: 'LOCAL ENCRYPTION',
      description:
          'Organize thoughts with markdown spaces, lock sensitive records inside your AES-256 encrypted Private Vault, and curate aesthetic moodboards with 3D flippable photo cards and micro-haptics.',
      proTip:
          'Double-tap any photo in Moodboards or Wardrobe to 3D flip it and view handwritten reflections on the back.',
      highlights: [
        'Zero-knowledge AES-256 GCM encrypted Private Vault',
        '3D rotating Polaroid cards with mid-flip haptics',
        'Wardrobe outfit capsule curation with outer thumbnails',
      ],
      icon: LucideIcons.image,
      actionLabel: 'View Notes & Moodboards',
      targetModuleIndex: 1,
    ),

    // Step 5: Powerful Expense Tracking
    WalkthroughStep(
      title: '05 · FINANCIAL LEDGER',
      headline: 'Powerful Expense Tracking & Split Bills',
      badge: 'TREASURY & AUDIT',
      description:
          'Master personal finances with monthly envelope budgets, recurring subscription tracking, 7-day spend velocity pacing, clean CSV audit report exports, and an interactive group bill & tip splitter.',
      proTip:
          'Use the bill splitter to calculate tips and automatically record what friends owe you into Settlements.',
      highlights: [
        'Monthly commitments & recurring subscription overview',
        'Interactive bill splitter with tip % & friend settlements',
        '1-Tap CSV audit export & daily burn velocity graph',
      ],
      icon: LucideIcons.wallet,
      actionLabel: 'Open Financial Ledger',
      targetModuleIndex: 5,
    ),

    // Step 6: Nodo AI Companion & Audio Studio
    WalkthroughStep(
      title: '06 · INTELLIGENT ASSISTANT',
      headline: 'Nodo Companion & Native Audio Studio',
      badge: 'ON-DEVICE AUDIO',
      description:
          'Meet Nodo, your animated floating companion that brainstorms ideas, summarizes long notes, and rephrases drafts. Paired with native Android hardware AAC voice recording and popup-free speech-to-text.',
      proTip:
          'Tap the microphone dock to dictate voice memos; recordings are saved locally as high-fidelity .m4a audio.',
      highlights: [
        'Floating circular mascot with context-aware suggestions',
        'Hardware AAC audio recording with live waveform player',
        'Zero-popup background speech-to-text transcription',
      ],
      icon: LucideIcons.sparkles,
      actionLabel: 'Meet Nodo Assistant',
    ),

    // Step 7: Android System Integration & Widgets
    WalkthroughStep(
      title: '07 · SYSTEM INTEGRATION',
      headline: 'Android Shortcuts & Aesthetic Widgets',
      badge: 'MATERIAL YOU',
      description:
          'Engineered as a first-class Android citizen: pin Pinterest-style homescreen widgets to check habits at a glance, enjoy Android 13+ wallpaper-adaptive Material You icons, and timely streak nudges.',
      proTip:
          'Long-press the NOTtEodo app icon on your phone home screen to jump straight to Quick Capture or Focus Timer.',
      highlights: [
        'Android launcher shortcuts for 1-tap capture & voice memo',
        'Wallpaper-adaptive Material You themed icon',
        'Pinterest aesthetic homescreen widgets with real-time sync',
      ],
      icon: LucideIcons.smartphone,
      actionLabel: 'Open Settings & Widgets',
      targetModuleIndex: 11,
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

  void _jumpToStep(int index) {
    if (index >= 0 && index < _steps.length && index != _currentStep) {
      SanctuaryHapticEngine.selection();
      setState(() => _currentStep = index);
    }
  }

  void _executeStepAction(WalkthroughStep step) {
    SanctuaryHapticEngine.dialDetent();
    if (step.actionLabel.contains('Omni-Capture')) {
      widget.onTriggerOmniCapture?.call();
      widget.onDismiss();
    } else if (step.actionLabel.contains('Editorial') || step.actionLabel.contains('Toggle')) {
      widget.onToggleEditorial?.call();
      widget.onDismiss();
    } else if (step.headline.contains('Nodo') || step.actionLabel.contains('Nodo')) {
      widget.onTriggerNodo?.call();
      widget.onDismiss();
    } else if (step.headline.contains('Voice') || step.actionLabel.contains('Voice')) {
      widget.onTriggerVoice?.call();
      widget.onDismiss();
    } else if (step.targetModuleIndex != null) {
      widget.onNavigateModule?.call(step.targetModuleIndex!);
      widget.onDismiss();
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final cardBg = isDark ? const Color(0xFF12100E) : const Color(0xFFFAF7F2);
    final borderColor = isDark ? const Color(0xFF282420) : const Color(0xFFE4DCCE);

    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: edBox(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.75 : 0.25),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: edBox(
                  color: cardBg.withValues(alpha: isDark ? 0.96 : 0.98),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor, width: 1.3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: Step Badge + Interactive Jump Dots + Skip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: edBox(
                            color: accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                step.title,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: edBox(
                                  color: accentColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  step.badge,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onDismiss,
                          style: TextButton.styleFrom(
                            foregroundColor: subtextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Skip Tour',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Interactive Step Indicators (Clickable to jump)
                    Row(
                      children: List.generate(_steps.length, (idx) {
                        final isActive = idx == _currentStep;
                        final isPassed = idx < _currentStep;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _jumpToStep(idx),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.only(right: idx < _steps.length - 1 ? 5 : 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: isActive ? 5.0 : 3.5,
                                decoration: edBox(
                                  borderRadius: BorderRadius.circular(3),
                                  color: isActive
                                      ? accentColor
                                      : (isPassed
                                          ? accentColor.withValues(alpha: 0.45)
                                          : (isDark ? const Color(0xFF282420) : const Color(0xFFE2DACC))),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Main Slide Content with smooth transition
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Hero Icon & Headline
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: edBox(
                                    shape: BoxShape.circle,
                                    color: accentColor.withValues(alpha: 0.14),
                                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Icon(step.icon, size: 20, color: accentColor),
                                ),
                                const SizedBox(width: 12),
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
                                        'Step ${_currentStep + 1} of ${_steps.length} • Tap dots above to jump',
                                        style: GoogleFonts.spaceGrotesk(
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
                            const SizedBox(height: 14),

                            // Description
                            Text(
                              step.description,
                              style: GoogleFonts.dmSans(
                                fontSize: 13.5,
                                height: 1.45,
                                color: primaryTextColor.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 3 Key Feature Highlights
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: edBox(
                                color: isDark ? const Color(0xFF181512) : const Color(0xFFF2ECE1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2C2620) : const Color(0xFFDDD3C4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final h in step.highlights) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(LucideIcons.check, size: 13, color: accentColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              h,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: primaryTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Pro-Tip Banner
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: edBox(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(LucideIcons.lightbulb, size: 15, color: accentColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.proTip,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF2ECE1) : const Color(0xFF2B2520),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Interactive Feature Action Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accentColor,
                                  side: BorderSide(color: accentColor.withValues(alpha: 0.55), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                                onPressed: () => _executeStepAction(step),
                                icon: Icon(step.icon, size: 15, color: accentColor),
                                label: Text(
                                  step.actionLabel,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bottom Navigation: Back & Next
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          TextButton.icon(
                            onPressed: _prev,
                            icon: const Icon(LucideIcons.chevronLeft, size: 16),
                            label: Text('Back', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              foregroundColor: subtextColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
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
                            isLast ? 'Complete Sanctuary Tour' : 'Next Feature',
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
    );
  }
}
