import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/stitch_logo_widget.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinishOnboarding;

  const OnboardingScreen({super.key, required this.onFinishOnboarding});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

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
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    } else {
      HapticFeedback.mediumImpact();
      widget.onFinishOnboarding();
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                'SKIP',
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
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    children: [
                      _buildSacredStudioSlide(isDark, primaryTextColor, subtextColor, accentColor, goldColor),
                      _buildAestheticSanctuarySlide(isDark, primaryTextColor, subtextColor, accentColor, goldColor),
                      _buildTemporalVaultSlide(isDark, primaryTextColor, subtextColor, accentColor, goldColor),
                    ],
                  ),
                ),

                // Bottom Controls: Morphing Pagination & Grand Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Morphing Astronomical Pagination Dots
                      Row(
                        children: List.generate(3, (idx) {
                          final isCurrent = _currentIndex == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 8),
                            width: isCurrent ? 36 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? accentColor
                                  : (isDark ? const Color(0xFF282828) : const Color(0xFFD6CEC2)),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: isCurrent
                                      ? accentColor.withValues(alpha: 0.6)
                                      : Colors.transparent,
                                  blurRadius: isCurrent ? 10 : 0,
                                  spreadRadius: isCurrent ? 1 : 0,
                                ),
                              ],
                            ),
                            child: isCurrent
                                ? Center(
                                    child: Container(
                                      width: 14,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        }),
                      ),

                      // Grand Sculpted Action Button
                      BouncyTouchEffect(
                        pressedScale: 0.94,
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF000000) : const Color(0xFF1E1A17),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentIndex == 2 ? 'ENTER SANCTUARY' : 'CONTINUE',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentIndex == 2 ? LucideIcons.sparkles : LucideIcons.arrowRight,
                                size: 16,
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

  /// Slide 1: The Sacred Studio (Intelligent Knowledge & Tactile Paper)
  Widget _buildSacredStudioSlide(
    bool isDark,
    Color primaryColor,
    Color subColor,
    Color accentColor,
    Color goldColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // 3D Layered Physical Artifact Visual
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Background Shadow Card
                Transform.rotate(
                  angle: -0.06,
                  child: Container(
                    width: 250,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFEAE3D8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF222222) : const Color(0xFFD6CDC0),
                      ),
                    ),
                  ),
                ),

                // Main Floating Frosted Note Artifact
                Transform.rotate(
                  angle: 0.02,
                  child: Container(
                    width: 270,
                    // Grows with large text instead of overflowing.
                    constraints: const BoxConstraints(minHeight: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF000000).withValues(alpha: 0.94)
                          : const Color(0xFFFFFFFF).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.55),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? accentColor : Colors.black).withValues(alpha: isDark ? 0.25 : 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
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
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(LucideIcons.fileText, size: 16, color: accentColor),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'UNIT 1 â€¢ ARCHITECTURE',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Golden Paperclip / Wax Seal Glyphs
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: goldColor.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                'SEALED',
                                style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: goldColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Computer Networks Subnetting',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.bodoniModa(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'â€¢ CIDR notation & variable-length subnet masks\nâ€¢ 4 PDFs, 2 DOCX distilled into neural memory',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            height: 1.4,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(LucideIcons.sparkles, size: 12, color: goldColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Deep Scoped Neural AI Indexed',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: goldColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Levitating Fountain Pen Badge (Top Right)
                Positioned(
                  top: 14,
                  right: 18,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF000000) : const Color(0xFF1E1A17),
                      border: Border.all(color: goldColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: goldColor.withValues(alpha: 0.4), blurRadius: 14),
                      ],
                    ),
                    child: const Icon(LucideIcons.penTool, size: 20, color: Color(0xFFEAB368)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // High-Art Typography
          Text(
            'The Sacred Studio',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture Every Spark.',
            textAlign: TextAlign.center,
            style: GoogleFonts.bodoniModa(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tactile paper aesthetics synthesized with local neural intelligence. Transform scattered thoughts, documents, and research into timeless curated sanctuaries.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14.5,
              height: 1.6,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 2: The Curated Sanctuary (Wardrobe, Expenses, Split, Memoirs)
  Widget _buildAestheticSanctuarySlide(
    bool isDark,
    Color primaryColor,
    Color subColor,
    Color accentColor,
    Color goldColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // 3D Physical Polaroid & Color Swatch Visual
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Floating Vintage Polaroid Card
                Transform.rotate(
                  angle: -0.04,
                  child: Container(
                    width: 230,
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE4DCD0),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Photo Area
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF16282C),
                                  Color(0xFF2C3E42),
                                  Color(0xFF86CBB0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.shirt,
                                size: 38,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tuscan Linen Casual â€¢ Autumn',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Expense Settlement Chip (Bottom Right)
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF86CBB0), width: 1.3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF86CBB0).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.split, size: 14, color: Color(0xFF86CBB0)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goa Villa Split â€¢ Rahul',
                              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                            Text(
                              'INR 4,850 Â· Settled & Sealed',
                              style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF86CBB0)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Palette Swatches (Top Left)
                Positioned(
                  top: 18,
                  left: 14,
                  child: Row(
                    children: [
                      _buildSwatchPill(const Color(0xFFE8927C)),
                      const SizedBox(width: 4),
                      _buildSwatchPill(const Color(0xFFEAB368)),
                      const SizedBox(width: 4),
                      _buildSwatchPill(const Color(0xFF86CBB0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Aesthetic Sanctuary',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Curate Your Life.',
            textAlign: TextAlign.center,
            style: GoogleFonts.bodoniModa(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Curate capsule wardrobes, record acoustic memoirs, balance group expense splits, and craft moodboards without noise or clutter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14.5,
              height: 1.6,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 3: The Temporal Vault (Chronometer, Focus Rhythms, AES Vault)
  Widget _buildTemporalVaultSlide(
    bool isDark,
    Color primaryColor,
    Color subColor,
    Color accentColor,
    Color goldColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Astronomical Chronometer & Vault Visual
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Rotating Tick Ring
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: goldColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Central Focus Flip-Clock Capsule
                Container(
                  width: 230,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF000000).withValues(alpha: 0.95)
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.timer, size: 16, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'POMODORO RHYTHM',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '25:00',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF86CBB0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86CBB0).withValues(alpha: 0.5)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.lock, size: 12, color: Color(0xFF86CBB0)),
                              const SizedBox(width: 6),
                              Text(
                                'AES-256 ENCRYPTED VAULT',
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF86CBB0),
                                ),
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
          const SizedBox(height: 18),

          Text(
            'Temporal Rhythm',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Master Your Flow.',
            textAlign: TextAlign.center,
            style: GoogleFonts.bodoniModa(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Calm task flows, daily temporal rhythms, and a cryptographically secured local vault. Zero surveillance, zero cloud hostage.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14.5,
              height: 1.6,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchPill(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
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
    return oldDelegate.pulse != pulse || oldDelegate.rotationTurns != rotationTurns || oldDelegate.isDark != isDark;
  }
}
