import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../brand/notteodo_monogram.dart';
import '../editorial/editorial_mode.dart';
import '../motion/motion.dart';

/// Monogrammed Wax Seal Stamp & Ritual
///
/// An archival stationery ritual for Vault PIN unlock and sealing private notes:
/// - Stamping animation with downward mechanical press and spring rebound.
/// - Distinct haptic thud confirmation.
///
/// Differentiated:
/// - Cards View: Tactile 3D wax seal with molten rim, depth shadow and brass monogram.
/// - Editorial View: Minimalist debossed monogram impression on paper (zero drop shadow).
class MonogrammedWaxSeal extends StatefulWidget {
  final double size;
  final VoidCallback? onComplete;
  final bool autoTrigger;
  final bool isEditorial;
  final String label;

  const MonogrammedWaxSeal({
    super.key,
    this.size = 84,
    this.onComplete,
    this.autoTrigger = true,
    this.isEditorial = false,
    this.label = 'SEALED',
  });

  /// Displays the Monogrammed Wax Seal sealing confirmation as a modal dialog.
  static Future<void> showSealedDialog(
    BuildContext context, {
    String title = 'Archived to Private Vault',
    String subtitle = 'This entry is encrypted and secured behind your PIN.',
    VoidCallback? onDone,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditorial = EditorialMode.active;

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.75 : 0.5),
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAF7F2),
          elevation: isEditorial ? 0 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isEditorial ? 16 : 24),
            side: BorderSide(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDE6DF),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MonogrammedWaxSeal(
                  size: 88,
                  isEditorial: isEditorial,
                  onComplete: () {
                    Future.delayed(const Duration(milliseconds: 650), () {
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        onDone?.call();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  State<MonogrammedWaxSeal> createState() => _MonogrammedWaxSealState();
}

class _MonogrammedWaxSealState extends State<MonogrammedWaxSeal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _stampAnimation;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.90).chain(CurveTween(curve: Curves.easeIn)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 55),
    ]).animate(_controller);

    _stampAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.44 && !_hapticFired) {
        _hapticFired = true;
        HapticFeedback.heavyImpact();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoTrigger) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oxbloodDark = const Color(0xFF8E2433);
    final oxbloodRim = isDark ? const Color(0xFFD0485A) : const Color(0xFFB5505E);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: widget.isEditorial
                ? _buildEditorialSeal(oxbloodDark, oxbloodRim, isDark)
                : _buildCardsSeal(oxbloodDark, oxbloodRim, isDark),
          ),
        );
      },
    );
  }

  /// Editorial View: Minimalist stationery deboss mark on paper
  Widget _buildEditorialSeal(Color oxblood, Color rim, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: oxblood.withValues(alpha: 0.85),
          width: 1.6,
        ),
      ),
      child: Center(
        child: Container(
          width: widget.size * 0.76,
          height: widget.size * 0.76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: rim.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              'N',
              style: GoogleFonts.bodoniModa(
                fontSize: widget.size * 0.38,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: oxblood,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Cards View: Tactile 3D wax seal with molten pool and depth shadow
  Widget _buildCardsSeal(Color oxblood, Color rim, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: oxblood,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A1620).withValues(alpha: isDark ? 0.65 : 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: rim.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Molten Rim
          Container(
            width: widget.size * 0.88,
            height: widget.size * 0.88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rim.withValues(alpha: 0.7),
                width: 1.8,
              ),
            ),
          ),
          // Inner Stamped Monogram
          Opacity(
            opacity: _stampAnimation.value,
            child: Text(
              'N',
              style: GoogleFonts.bodoniModa(
                fontSize: widget.size * 0.44,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF6F3ED),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
