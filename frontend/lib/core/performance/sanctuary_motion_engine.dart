import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_store.dart';

/// Haute Horlogerie Motion & Performance Engine
/// Delivers buttery 60-120 FPS frame rates, momentum physics, and tactile micro-haptics.
class SanctuaryMotionEngine {
  /// Universal momentum-preserved spring scroll physics
  static const ScrollPhysics fluidPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  /// Ultra-smooth animation duration tokens
  static const Duration durationInstant = Duration(milliseconds: 120);
  static const Duration durationSnappy = Duration(milliseconds: 240);
  static const Duration durationSilky = Duration(milliseconds: 400);
  static const Duration durationLooming = Duration(milliseconds: 700);

  /// Haute Horlogerie custom easing curves
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveSilky = Curves.easeOutCubic;
  static const Curve curveFluid = Curves.easeInOutCubicEmphasized;
}

/// Workstation Scroll Behavior enabling smooth drag scrolling across Desktop, Web, & Mobile
class SanctuaryScrollBehavior extends MaterialScrollBehavior {
  const SanctuaryScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return SanctuaryMotionEngine.fluidPhysics;
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Eliminate harsh Android glow overscroll, rely on silky iOS-style spring bounce
  }
}

/// Haute Horlogerie Swiss Escapement Tactile Haptic Engine with User Intensity Awareness
class SanctuaryHapticEngine {
  static DateTime _lastTick = DateTime.now();

  static String _intensity() {
    try {
      final s = LocalStore().readMap('settings');
      return (s?['hapticIntensity'] as String?) ?? 'crisp';
    } catch (_) {
      return 'crisp';
    }
  }

  /// Mechanical watch escapement click (subtle tick)
  static void escapementTick() {
    final mode = _intensity();
    if (mode == 'off') return;
    final now = DateTime.now();
    if (now.difference(_lastTick).inMilliseconds > 40) {
      _lastTick = now;
      HapticFeedback.selectionClick();
    }
  }

  /// Dial detent click (for toggles, sliders, radial dials)
  static void dialDetent() {
    final mode = _intensity();
    if (mode == 'off') return;
    if (mode == 'light') {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Seal impression feedback (for sealing notes, completing tasks, vault locking)
  static void sealImpression() {
    final mode = _intensity();
    if (mode == 'off') return;
    if (mode == 'light') {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Security warning or boundary lockout
  static void securityAlert() {
    final mode = _intensity();
    if (mode == 'off') return;
    if (mode == 'light') {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void buttonPress() {
    final mode = _intensity();
    if (mode == 'off') return;
    HapticFeedback.selectionClick();
  }

  static void cardTap() {
    final mode = _intensity();
    if (mode == 'off') return;
    if (mode == 'light') {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void tabSwitch() {
    final mode = _intensity();
    if (mode == 'off') return;
    HapticFeedback.selectionClick();
  }

  static void taskComplete() {
    final mode = _intensity();
    if (mode == 'off') return;
    if (mode == 'crisp') {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void toggleSwitch() => dialDetent();
  static void destructive() => securityAlert();
  static void selection() => buttonPress();
}

/// Ultra-Creative Ambient Specular Light Tracer (Web & Desktop)
/// Casts an ultra-subtle champagne gold specular pool following the cursor without triggering widget tree rebuilds.
class SanctuaryCursorTracer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const SanctuaryCursorTracer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<SanctuaryCursorTracer> createState() => _SanctuaryCursorTracerState();
}

class _SanctuaryCursorTracerState extends State<SanctuaryCursorTracer> {
  final ValueNotifier<Offset?> _cursorPosition = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _cursorPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onHover: (event) {
        _cursorPosition.value = event.localPosition;
      },
      onExit: (_) {
        _cursorPosition.value = null;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SpecularLightTracerPainter(
                  cursorPosition: _cursorPosition,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecularLightTracerPainter extends CustomPainter {
  final ValueNotifier<Offset?> cursorPosition;
  final bool isDark;

  _SpecularLightTracerPainter({
    required this.cursorPosition,
    required this.isDark,
  }) : super(repaint: cursorPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final pos = cursorPosition.value;
    if (pos == null) return;

    // Warm terracotta specular light pool
    final glowColor = isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);
    final paint = Paint()..color = glowColor.withValues(alpha: 0.12);

    canvas.drawCircle(pos, 240, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularLightTracerPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.cursorPosition != cursorPosition;
  }
}
