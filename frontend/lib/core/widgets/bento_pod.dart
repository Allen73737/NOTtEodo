import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import 'wax_seal_picker.dart';
import 'washi_tape_pin.dart';

enum PodTextureStyle { glass, paper, receipt, passport, polaroid, decklePaper }

class BentoPod extends StatefulWidget {
  final Widget child;
  final PodTextureStyle style;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showWaxSeal;
  final WaxSealType waxSealType;
  final bool showWashiTape;
  final int animationDelayMs;

  const BentoPod({
    super.key,
    required this.child,
    this.style = PodTextureStyle.glass,
    this.onTap,
    this.padding,
    this.showWaxSeal = false,
    this.waxSealType = WaxSealType.monogramN,
    this.showWashiTape = false,
    this.animationDelayMs = 0,
  });

  @override
  State<BentoPod> createState() => _BentoPodState();
}

class _BentoPodState extends State<BentoPod> with TickerProviderStateMixin {
  bool _isHovered = false;
  Offset _tiltOffset = Offset.zero;
  late AnimationController _sheenController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    if (widget.animationDelayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.animationDelayMs), () {
        if (mounted) _entranceController.forward();
      });
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _sheenController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = _isHovered ? 1.015 : 1.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovered = true);
              _sheenController.forward(from: 0);
            },
            onExit: (_) => setState(() {
              _isHovered = false;
              _tiltOffset = Offset.zero;
            }),
            onHover: (event) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final size = renderBox.size;
                final localPos = event.localPosition;
                final dx = (localPos.dx - size.width / 2) / (size.width / 2);
                final dy = (localPos.dy - size.height / 2) / (size.height / 2);
                setState(() {
                  _tiltOffset = Offset(dx * 0.04, -dy * 0.04);
                });
              }
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onTap != null) widget.onTap!();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_tiltOffset.dy)
                  ..rotateY(_tiltOffset.dx)
                  ..multiply(Matrix4.diagonal3Values(scaleFactor, scaleFactor, 1.0)),
                transformAlignment: Alignment.center,
                child: Stack(
                  children: [
                    _buildPodContainer(context, isDark),

                    // Translucent Washi Tape Pin Overlay
                    if (widget.showWashiTape)
                      const Positioned(
                        top: -6,
                        left: 24,
                        child: WashiTapePin(style: TapeStyle.translucentCream, width: 54),
                      ),

                    // Glass Reflective Sheen Sweep Overlay
                    if (widget.style == PodTextureStyle.glass)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedBuilder(
                            animation: _sheenController,
                            builder: (context, child) {
                              if (_sheenController.value == 0 || _sheenController.value == 1) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.0 + _sheenController.value * 3, -1.0),
                                    end: Alignment(0.0 + _sheenController.value * 3, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Customizable Wax Seal Corner Badge
                    if (widget.showWaxSeal)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: WaxSealWidget(type: widget.waxSealType, size: 26),
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

  Widget _buildPodContainer(BuildContext context, bool isDark) {
    final effectivePadding = widget.padding ?? const EdgeInsets.all(20);

    switch (widget.style) {
      case PodTextureStyle.glass:
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: effectivePadding,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000000).withValues(alpha: 0.95) : AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: _isHovered ? 0.15 : 0.05),
                    blurRadius: _isHovered ? 25 : 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        );

      case PodTextureStyle.paper:
        return Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5DFC9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _isHovered ? 0.12 : 0.06),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: widget.child,
        );

      case PodTextureStyle.decklePaper:
        return Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFFBF8F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDED8C4), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              widget.child,
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(4)),
                  child: Text('STAMP 1984', style: GoogleFonts.dmSans(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                ),
              ),
            ],
          ),
        );

      case PodTextureStyle.receipt:
        return Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFF7F5EE),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFDED8C4)),
          ),
          child: widget.child,
        );

      case PodTextureStyle.passport:
        return Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: const Color(0xFF1E1E1E)) : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: widget.child,
        );

      case PodTextureStyle.polaroid:
        return Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : AppColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.child,
        );
    }
  }
}
