import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/kinetic_ambient_canvas.dart';

class LogoRevealScreen extends StatefulWidget {
  final VoidCallback onRevealComplete;

  const LogoRevealScreen({super.key, required this.onRevealComplete});

  @override
  State<LogoRevealScreen> createState() => _LogoRevealScreenState();
}

class _LogoRevealScreenState extends State<LogoRevealScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _textController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 40.0, end: 110.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack)),
    );

    _textController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          widget.onRevealComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          // Kinetic Floating Particles Background
          const KineticAmbientCanvas(
            child: SizedBox.expand(),
          ),

          // Background Multi-Layer Ambient Radial Glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        blurRadius: _pulseAnimation.value,
                        spreadRadius: _pulseAnimation.value / 2.5,
                      ),
                      BoxShadow(
                        color: const Color(0xFFE8927C).withValues(alpha: 0.2),
                        blurRadius: _pulseAnimation.value * 1.4,
                        spreadRadius: _pulseAnimation.value / 4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Main Uploaded Logo Reveal with Floating Motion
          Center(
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, _) {
                        final floatY = math.sin(_floatController.value * math.pi) * 8;

                        return Transform.translate(
                          offset: Offset(0, floatY),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/notteodo_logo.png',
                                width: 230,
                                height: 230,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'NOTES. TASKS. LIFE.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  letterSpacing: 4.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFB8C5C8) : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}
