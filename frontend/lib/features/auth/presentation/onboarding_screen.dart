import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinishOnboarding;

  const OnboardingScreen({super.key, required this.onFinishOnboarding});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  static const int _totalSlides = 5;

  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    } else {
      HapticFeedback.mediumImpact();
      widget.onFinishOnboarding();
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFF9E9A92) : const Color(0xFF635F59);
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    const goldColor = Color(0xFFEAB368);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF9F7F4),
      body: Stack(
        children: [
          // 1. Ambient Celestial Blueprint Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                return CustomPaint(
                  painter: _CelestialConstellationPainter(
                    isDark: isDark,
                    pulse: pulse,
                    rotationTurns: _rotationController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Main Content Stack
          SafeArea(
            child: Column(
              children: [
                // Top Header: Stitch Monogram & Skip Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StitchLogoWidget(fontSize: 22, showMonogramN: true),
                      BouncyTouchEffect(
                        pressedScale: 0.90,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onFinishOnboarding();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DDD2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SKIP TOUR',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.chevronRight, size: 13, color: accentColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive 3D Visual Hero Slides
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: SanctuaryMotionEngine.fluidPhysics,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    children: [
                      // Slide 1: Welcome to NOTtEodo
                      _buildFeatureSlide(
                        isDark: isDark,
                        primaryColor: primaryTextColor,
                        subColor: subtextColor,
                        accentColor: accentColor,
                        goldColor: goldColor,
                        category: 'WELCOME',
                        title: 'Your Daily Notes &\nPersonal Planner',
                        tagline: 'Simple · Private · Easy to Use',
                        description:
                            'Keep your notes, to-do lists, calendar, and daily spending organized in one peaceful place. Your data stays safe and private on your phone.',
                        heroIcon: LucideIcons.compass,
                        badgeColor: accentColor,
                        features: [
                          'One clean home screen for your daily routine',
                          'Private on-device storage with fingerprint or PIN lock',
                          'Clean design with no annoying distractions',
                          'Works completely offline with instant search',
                        ],
                      ),

                      // Slide 2: Notes & Folders
                      _buildFeatureSlide(
                        isDark: isDark,
                        primaryColor: primaryTextColor,
                        subColor: subtextColor,
                        accentColor: accentColor,
                        goldColor: goldColor,
                        category: 'NOTES',
                        title: 'Write Notes &\nOrganize Thoughts',
                        tagline: 'Format Text · Add Photos · Clean Folders',
                        description:
                            'Type or dictate your ideas freely. Format with markdown, attach photos and documents, and sort into folders like Personal, Work, or Travel.',
                        heroIcon: LucideIcons.fileText,
                        badgeColor: const Color(0xFFD9725B),
                        features: [
                          'Clean notepad with easy formatting',
                          'Folders for Personal, Work, Study, and Travel',
                          'Attach pictures, documents, and scan text',
                          'Quick search to find any note in seconds',
                        ],
                      ),

                      // Slide 3: Focus Tasks & Daily Schedule
                      _buildFeatureSlide(
                        isDark: isDark,
                        primaryColor: primaryTextColor,
                        subColor: subtextColor,
                        accentColor: accentColor,
                        goldColor: goldColor,
                        category: 'TASKS & SCHEDULE',
                        title: 'Daily To-Do Lists &\nCalendar Reminders',
                        tagline: 'Morning, Day, Evening · Reminders · Alarms',
                        description:
                            'Organize what you need to do today by priority. Schedule reminders that alert you even when the app is closed.',
                        heroIcon: LucideIcons.calendar,
                        badgeColor: accentColor,
                        features: [
                          'High and low priority tags to stay focused',
                          'Plan your morning, afternoon, and evening',
                          'Sync events with Google Calendar',
                          'Helpful notifications so you never miss a deadline',
                        ],
                      ),

                      // Slide 4: Expenses & Budgets
                      _buildFeatureSlide(
                        isDark: isDark,
                        primaryColor: primaryTextColor,
                        subColor: subtextColor,
                        accentColor: accentColor,
                        goldColor: goldColor,
                        category: 'EXPENSES',
                        title: 'Track Expenses &\nMonthly Spending',
                        tagline: 'Any Currency · Simple Categories · Clear Charts',
                        description:
                            'Know exactly where your money goes. Set a monthly spending goal and view easy charts of your daily expenses.',
                        heroIcon: LucideIcons.wallet,
                        badgeColor: const Color(0xFFD9725B),
                        features: [
                          'Supports Rupees, Dollars, Euros, and custom currencies',
                          'Set a monthly budget to keep spending on track',
                          'Categories for Food, Shopping, Bills, and Travel',
                          'Clear graphs showing your spending habits',
                        ],
                      ),

                      // Slide 5: Meet Nodo AI & Voice Notes
                      _buildFeatureSlide(
                        isDark: isDark,
                        primaryColor: primaryTextColor,
                        subColor: subtextColor,
                        accentColor: accentColor,
                        goldColor: goldColor,
                        category: 'NODO ASSISTANT',
                        title: 'Meet Nodo &\nVoice Notes',
                        tagline: 'Helpful AI · Real-time Voice · Quick Answers',
                        description:
                            'Nodo is your friendly assistant. Speak aloud to record voice notes with live text dictation, get helpful task suggestions, and summarize your notes.',
                        heroIcon: LucideIcons.sparkles,
                        badgeColor: accentColor,
                        features: [
                          'Speak to record voice notes with live text on screen',
                          'Helpful reminders to keep your streak going',
                          'Ask questions and summarize long notes with AI',
                          'Easily turn Nodo on or off anytime in Settings',
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Controls: Back, Step Indicators, Next/Enter
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (hidden on first slide)
                      if (_currentIndex > 0)
                        BouncyTouchEffect(
                          pressedScale: 0.92,
                          onTap: _previousPage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141210) : const Color(0xFFEFE9DE),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF282522) : const Color(0xFFDDD5C4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.chevronLeft, size: 15, color: subtextColor),
                                const SizedBox(width: 4),
                                Text(
                                  'BACK',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80),

                      // Morphing Progress Indicator Pills
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_totalSlides, (idx) {
                          final isCurrent = _currentIndex == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isCurrent ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? accentColor
                                  : (isDark ? const Color(0xFF282828) : const Color(0xFFD6CEC2)),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                if (isCurrent)
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),

                      // Grand Sculpted Next / Enter Action Button
                      BouncyTouchEffect(
                        pressedScale: 0.94,
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF000000) : const Color(0xFF1E1A17),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.8),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentIndex == _totalSlides - 1 ? 'GET STARTED' : 'NEXT',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _currentIndex == _totalSlides - 1
                                    ? LucideIcons.sparkles
                                    : LucideIcons.arrowRight,
                                size: 14,
                                color: accentColor,
                              ),
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
        ],
      ),
    );
  }

  /// Unified feature presentation slide
  Widget _buildFeatureSlide({
    required bool isDark,
    required Color primaryColor,
    required Color subColor,
    required Color accentColor,
    required Color goldColor,
    required String category,
    required String title,
    required String tagline,
    required String description,
    required IconData heroIcon,
    required Color badgeColor,
    required List<String> features,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Illustration / Compliment Capsule
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E0C0A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF221F1C) : const Color(0xFFE4DDD2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Icon Orb
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withValues(alpha: 0.16),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(heroIcon, size: 26, color: badgeColor),
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tagline.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Feature Checklist Bullets
                Column(
                  children: features.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(LucideIcons.checkCircle2, size: 14, color: badgeColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                height: 1.35,
                                color: isDark ? const Color(0xFFD6D0C4) : const Color(0xFF3C3834),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Slide Title & Category
          Text(
            category,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.bodoniModa(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.spectral(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: subColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sacred Geometry Blueprint Background Painter
class _CelestialConstellationPainter extends CustomPainter {
  final bool isDark;
  final double pulse;
  final double rotationTurns;

  _CelestialConstellationPainter({
    required this.isDark,
    required this.pulse,
    required this.rotationTurns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark
          ? const Color(0xFFE8927C).withValues(alpha: 0.04 + pulse * 0.03)
          : const Color(0xFF7E301B).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.38);

    // Concentric Blueprint Circles
    canvas.drawCircle(center, 120 + pulse * 10, linePaint);
    canvas.drawCircle(center, 190, linePaint);
    canvas.drawCircle(center, 260 + pulse * 8, linePaint);

    // Crosshair Lines
    canvas.drawLine(
      Offset(center.dx - 280, center.dy),
      Offset(center.dx + 280, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 280),
      Offset(center.dx, center.dy + 280),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CelestialConstellationPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.rotationTurns != rotationTurns ||
        oldDelegate.isDark != isDark;
  }
}
