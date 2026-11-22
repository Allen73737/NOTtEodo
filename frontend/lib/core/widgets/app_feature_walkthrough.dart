import 'package:flutter/material.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../tour/app_tour_script.dart';
import '../tour/spotlight_tour.dart';

/// What a step's "Try it" button does.
enum WalkthroughAction { none, openModule, quickCapture, nodo, voice, switchView }

class WalkthroughStep {
  /// Short name used in the progress bar and the "Next:" button.
  final String chapter;
  final String headline;
  final String description;
  final List<String> howTo;
  final String tip;
  final IconData icon;
  final String? actionLabel;
  final WalkthroughAction action;
  final int? targetModuleIndex; // 0 Home, 1 Notes, 2 Tasks, 3 Planner, 5 Expenses, 9 Habits, 11 Settings, 13 Vault

  const WalkthroughStep({
    required this.chapter,
    required this.headline,
    required this.description,
    required this.howTo,
    required this.tip,
    required this.icon,
    this.actionLabel,
    this.action = WalkthroughAction.none,
    this.targetModuleIndex,
  });
}

/// A guided tour of the app: one idea per step, how to use it in plain steps,
/// and a button that takes you straight there.
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
    // Inside the app, walk the real pages and light up each control. This card tour
    // is the fallback where there is no app shell to walk (the admin console).
    if (TourHost.attached) return SpotlightTour.start(context, AppTourScript.stops);
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Walkthrough',
      barrierColor: overlayScrim(context),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (ctx, _, __) => AppFeatureWalkthroughModal(
        onDismiss: () => Navigator.of(ctx).pop(),
        onNavigateModule: onNavigateModule,
        onTriggerNodo: onTriggerNodo,
        onTriggerVoice: onTriggerVoice,
        onTriggerOmniCapture: onTriggerOmniCapture,
        onToggleEditorial: onToggleEditorial,
      ),
      // The card rises and settles into place.
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Motion.settle, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
            child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
          ),
        );
      },
    );
  }

  static const List<WalkthroughStep> steps = [
    WalkthroughStep(
      chapter: 'Welcome',
      headline: 'Welcome to NOTtEodo',
      description:
          'One quiet place for your notes, tasks, plans, money and habits. This tour takes about two minutes and shows you where everything lives and how to use it.',
      howTo: [
        'Tap Next, or swipe the card left, to move on.',
        'Tap any bar at the top to jump straight to that part.',
        'Most steps have a Try it button that takes you there.',
        'You can replay this tour any time from Settings, Help.',
      ],
      tip: 'Everything you add stays on your device first and syncs when you sign in.',
      icon: LucideIcons.sparkles,
    ),
    WalkthroughStep(
      chapter: 'Home',
      headline: 'Your day at a glance',
      description:
          'Home gathers what matters today: your top tasks, recent notes, your streak and how your spending is going this month.',
      howTo: [
        'Tick a task right on Home to complete it.',
        'Tap any card to open the full section behind it.',
        'Use the filters at the top to focus on tasks, money or lifestyle.',
        'In the evening, open Zen review to look back on the day and keep your streak.',
      ],
      tip: 'Home only shows today. Everything else is one tap away in the dock or the menu.',
      icon: LucideIcons.home,
      actionLabel: 'Open Home',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 0,
    ),
    WalkthroughStep(
      chapter: 'Capture',
      headline: 'Write anything down in seconds',
      description:
          'Quick capture understands plain language. Type "Dinner with Sam ₹900 tomorrow 7pm #food" and it becomes an expense, a reminder and a tag, sorted for you.',
      howTo: [
        'Tap the + button in the dock to open quick capture.',
        'Type naturally. Dates, times, prices and #tags are picked up automatically.',
        'Check the preview, then save. It lands in the right section.',
      ],
      tip: 'On Android, long-press the NOTtEodo icon for a capture shortcut.',
      icon: LucideIcons.zap,
      actionLabel: 'Try quick capture',
      action: WalkthroughAction.quickCapture,
    ),
    WalkthroughStep(
      chapter: 'Notes',
      headline: 'Notes that stay organised',
      description:
          'Write with headings, lists and checkboxes. Tag notes, pin the important ones, and find any of them again with search.',
      howTo: [
        'Open Notes and tap + to start a new note.',
        'Add #tags while you write to group related notes.',
        'Use search to find any note by a word or a tag.',
        'Keep private records in the Vault, locked with your PIN.',
      ],
      tip: 'Deleted notes wait in the Bin for 30 days, so nothing is lost by accident.',
      icon: LucideIcons.fileText,
      actionLabel: 'Open Notes',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 1,
    ),
    WalkthroughStep(
      chapter: 'Tasks',
      headline: 'Tasks and reminders',
      description:
          'Keep a list of what to do, give tasks a date and a reminder, and tick them off as you go.',
      howTo: [
        'Open Tasks and tap + to add one.',
        'Set a due date and time to get a reminder.',
        'Tap the circle to complete a task. Swipe it away to delete it.',
      ],
      tip: 'Tasks with a date also appear in the Planner, so your day lines up in one view.',
      icon: LucideIcons.checkSquare,
      actionLabel: 'Open Tasks',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 2,
    ),
    WalkthroughStep(
      chapter: 'Planner',
      headline: 'Plan the week ahead',
      description:
          'The Planner lays your tasks and events out on a calendar so you can see a busy day coming and move things around.',
      howTo: [
        'Open Planner and pick a day.',
        'Tap New event to add something to that day.',
        'Set a reminder so it nudges you in time.',
        'Tap Today to jump back to the current day.',
      ],
      tip: 'Plan tomorrow tonight. It takes a minute and makes mornings calmer.',
      icon: LucideIcons.calendar,
      actionLabel: 'Open Planner',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 3,
    ),
    WalkthroughStep(
      chapter: 'Habits',
      headline: 'Habits and streaks',
      description:
          'Build routines one day at a time. Each day you show up adds to your streak, and streak freezes protect it on a day off.',
      howTo: [
        'Open Habits and add something you want to do regularly.',
        'Tap a habit each day you do it.',
        'Watch your streak grow and collect rewards along the way.',
      ],
      tip: 'Start with one small habit. A short streak you keep beats a long list you skip.',
      icon: LucideIcons.target,
      actionLabel: 'Open Habits',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 9,
    ),
    WalkthroughStep(
      chapter: 'Money',
      headline: 'Track spending and budgets',
      description:
          'Log what you spend, set a monthly budget, keep an eye on subscriptions, and split a bill with friends without the maths.',
      howTo: [
        'Open Expenses and tap + to log a payment.',
        'Set a monthly budget to see how much is left.',
        'Use the bill splitter to share a bill and track who owes you.',
        'Export a CSV whenever you need a record.',
      ],
      tip: 'Logging right after you pay takes five seconds and keeps the month honest.',
      icon: LucideIcons.wallet,
      actionLabel: 'Open Expenses',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 5,
    ),
    WalkthroughStep(
      chapter: 'Nodo',
      headline: 'Nodo, your assistant',
      description:
          'Nodo can summarise a long note, brainstorm ideas, rewrite a draft or answer questions about what you have saved. You can also speak instead of typing.',
      howTo: [
        'Tap the Nodo bubble or the sparkle button to ask something.',
        'Pick a suggestion or type your own question.',
        'Tap the microphone in the dock to record a voice memo. It is transcribed for you.',
      ],
      tip: 'Ask Nodo "what did I plan for this week?" to get a quick summary.',
      icon: LucideIcons.bot,
      actionLabel: 'Ask Nodo',
      action: WalkthroughAction.nodo,
    ),
    WalkthroughStep(
      chapter: 'Looks',
      headline: 'Two ways to see the app',
      description:
          'Cards puts every item on its own card with depth and motion. Editorial sets everything as clean type on paper, with no boxes. Your data is the same in both.',
      howTo: [
        'Tap the view icon in the top bar (stacked cards or lines of type) to switch between Cards and Editorial.',
        'The moon or sun icon next to it switches dark and light.',
        'Fine-tune the accent colour, text size and spacing in Settings, Look and feel.',
      ],
      tip: 'Try Editorial in the evening for a calmer screen.',
      icon: LucideIcons.columns2,
      actionLabel: 'Switch the view now',
      action: WalkthroughAction.switchView,
    ),
    WalkthroughStep(
      chapter: 'Private',
      headline: 'Your private Vault',
      description:
          'The Vault keeps sensitive notes and records encrypted on your device, behind a PIN only you know. You can also lock the whole app.',
      howTo: [
        'Open the Vault from the menu and set a PIN.',
        'Add a record and tap Lock in Vault to encrypt it.',
        'Turn on app lock in Settings, Privacy and data to ask for the PIN on opening.',
      ],
      tip: 'Save your emergency recovery kit when you set the PIN, in case you forget it.',
      icon: LucideIcons.lock,
      actionLabel: 'Open the Vault',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 13,
    ),
    WalkthroughStep(
      chapter: 'Widgets',
      headline: 'Widgets and shortcuts',
      description:
          'Put your tasks and streak on your phone home screen, and jump into the app straight from its icon.',
      howTo: [
        'Long-press an empty spot on your home screen and choose Widgets.',
        'Find NOTtEodo and drag the widget onto your home screen.',
        'Design your own widget with Homescreen Widget Studio in Settings.',
        'Long-press the app icon for quick capture and voice memo shortcuts.',
      ],
      tip: 'The widget updates itself whenever you add or finish a task.',
      icon: LucideIcons.smartphone,
      actionLabel: 'Open Settings',
      action: WalkthroughAction.openModule,
      targetModuleIndex: 11,
    ),
    WalkthroughStep(
      chapter: 'Done',
      headline: 'You are all set',
      description: 'That is the whole app. A good first day looks like this:',
      howTo: [
        'Capture three things on your mind.',
        'Pick one task to finish today.',
        'Start one small habit.',
        'Come back tonight for Zen review.',
      ],
      tip: 'Replay this tour any time from Settings, Help.',
      icon: LucideIcons.partyPopper,
    ),
  ];

  @override
  State<AppFeatureWalkthroughModal> createState() => _AppFeatureWalkthroughModalState();
}

class _AppFeatureWalkthroughModalState extends State<AppFeatureWalkthroughModal> {
  static const _steps = AppFeatureWalkthroughModal.steps;
  int _current = 0;
  int _direction = 1; // 1 forward, -1 back: which way the content slides

  bool get _isLast => _current == _steps.length - 1;

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length || index == _current) return;
    SanctuaryHapticEngine.selection();
    setState(() {
      _direction = index > _current ? 1 : -1;
      _current = index;
    });
  }

  void _next() {
    SanctuaryHapticEngine.dialDetent();
    if (_isLast) {
      widget.onDismiss();
    } else {
      _goTo(_current + 1);
    }
  }

  void _prev() => _goTo(_current - 1);

  void _runAction(WalkthroughStep step) {
    SanctuaryHapticEngine.dialDetent();
    switch (step.action) {
      case WalkthroughAction.quickCapture:
        widget.onTriggerOmniCapture?.call();
      case WalkthroughAction.nodo:
        widget.onTriggerNodo?.call();
      case WalkthroughAction.voice:
        widget.onTriggerVoice?.call();
      case WalkthroughAction.switchView:
        widget.onToggleEditorial?.call();
      case WalkthroughAction.openModule:
        if (step.targetModuleIndex != null) widget.onNavigateModule?.call(step.targetModuleIndex!);
      case WalkthroughAction.none:
        break;
    }
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF0F0D0D) : Colors.white;
    final ink = dark ? const Color(0xFFF6F3ED) : const Color(0xFF1A1614);
    final muted = dark ? const Color(0xFFA89C9C) : const Color(0xFF6B605A);
    final accent = dark ? const Color(0xFFD0485A) : const Color(0xFF7A1F2B);
    final fill = dark ? const Color(0xFF8E2433) : const Color(0xFF7A1F2B);
    final track = dark ? const Color(0xFF2A1F21) : const Color(0xFFEADFD9);
    final soft = dark ? const Color(0xFF181414) : const Color(0xFFF4EFE9);
    final step = _steps[_current];
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _prev,
        const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
      },
      child: Focus(
        autofocus: true,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              // Swipe the card to move through the tour.
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -250) _next();
                if (v > 250) _prev();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.6 : 0.18), blurRadius: 40, offset: const Offset(0, 18)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: where you are, and a way out.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 10, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: 'Tour  ', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                                TextSpan(
                                  text: '${_current + 1} of ${_steps.length}',
                                  style: GoogleFonts.dmSans(fontSize: 13, color: muted, fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              ]),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onDismiss,
                            style: TextButton.styleFrom(foregroundColor: muted, visualDensity: VisualDensity.compact),
                            child: Text(_isLast ? 'Close' : 'Skip tour', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    // Progress: one bar per step, tap to jump.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                      child: Row(
                        children: [
                          for (var i = 0; i < _steps.length; i++)
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: 'Go to ${_steps[i].chapter}',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _goTo(i),
                                  child: Padding(
                                    padding: EdgeInsets.only(right: i < _steps.length - 1 ? 4 : 0, top: 8, bottom: 8),
                                    child: AnimatedContainer(
                                      duration: Motion.standard,
                                      curve: Motion.silk,
                                      height: i == _current ? 5 : 3,
                                      decoration: BoxDecoration(
                                        color: i <= _current ? accent.withValues(alpha: i == _current ? 1 : 0.45) : track,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Body: slides in from the side you are heading to.
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: Motion.settle,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topLeft,
                          children: [...previous, if (current != null) current],
                        ),
                        transitionBuilder: (child, anim) {
                          final incoming = child.key == ValueKey(_current);
                          final from = Offset(0.08 * _direction * (incoming ? 1 : -1), 0);
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(begin: from, end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: SingleChildScrollView(
                          key: ValueKey(_current),
                          padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                          child: _StepBody(
                            step: step,
                            ink: ink,
                            muted: muted,
                            accent: accent,
                            soft: soft,
                            onAction: step.actionLabel == null ? null : () => _runAction(step),
                          ),
                        ),
                      ),
                    ),
                    // Bottom: back and next, naming where next goes.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 18, 18),
                      child: Row(
                        children: [
                          AnimatedOpacity(
                            duration: Motion.standard,
                            opacity: _current > 0 ? 1 : 0,
                            child: TextButton.icon(
                              onPressed: _current > 0 ? _prev : null,
                              icon: const Icon(LucideIcons.chevronLeft, size: 16),
                              label: Text('Back', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(foregroundColor: muted),
                            ),
                          ),
                          const Spacer(),
                          Pressable(
                            onTap: _next,
                            pressedScale: 0.95,
                            hoverLift: 0,
                            child: AnimatedContainer(
                              duration: Motion.standard,
                              curve: Motion.silk,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(99)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isLast
                                        ? 'Start using NOTtEodo'
                                        : (_current == 0 ? 'Start the tour' : 'Next: ${_steps[_current + 1].chapter}'),
                                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFF6F3ED)),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(_isLast ? LucideIcons.check : LucideIcons.arrowRight, size: 16, color: const Color(0xFFF6F3ED)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _StepBody extends StatelessWidget {
  final WalkthroughStep step;
  final Color ink, muted, accent, soft;
  final VoidCallback? onAction;

  const _StepBody({required this.step, required this.ink, required this.muted, required this.accent, required this.soft, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The step's mark: an icon in a soft disc that breathes in on arrival.
        Reveal(
          style: RevealStyle.rise,
          distance: 8,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
            child: Icon(step.icon, size: 22, color: accent),
          ),
        ),
        const SizedBox(height: 14),
        Text(step.chapter, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        const SizedBox(height: 4),
        Text(step.headline, style: GoogleFonts.bodoniModa(fontSize: 27, fontWeight: FontWeight.bold, color: ink, height: 1.12)),
        const SizedBox(height: 10),
        Text(step.description, style: GoogleFonts.dmSans(fontSize: 15, height: 1.5, color: ink.withValues(alpha: 0.88))),
        const SizedBox(height: 18),
        Text(step.action == WalkthroughAction.none && step.chapter == 'Done' ? 'Your first day' : 'How to use it',
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: muted)),
        const SizedBox(height: 8),
        // Numbered steps arrive one after another.
        ...[
          for (var i = 0; i < step.howTo.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(step.howTo[i], style: GoogleFonts.dmSans(fontSize: 14.5, height: 1.45, color: ink)),
                    ),
                  ),
                ],
              ),
            ),
        ].revealed(style: RevealStyle.slideIn, distance: 12),
        const SizedBox(height: 6),
        // A tip, set off by a thin accent rule.
        Container(
          padding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: accent, width: 2))),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Tip  ', style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: accent)),
              TextSpan(text: step.tip, style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.45, color: muted)),
            ]),
          ),
        ),
        if (onAction != null) ...[
          const SizedBox(height: 18),
          Pressable(
            onTap: onAction,
            pressedScale: 0.97,
            hoverLift: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Try it: ${step.actionLabel}', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.arrowUpRight, size: 15, color: accent),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
