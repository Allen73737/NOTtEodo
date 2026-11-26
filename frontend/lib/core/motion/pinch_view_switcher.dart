import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editorial/editorial_mode.dart';
import '../state/app_settings.dart';
import '../widgets/app_toast_engine.dart';

/// Pinch-to-Flatten / Spread-to-Card Gesture Wrapper
///
/// Enables natural two-finger physical gesture navigation:
/// - Pinch Inward (< 0.85 scale with 2 fingers) on Cards View:
///   Fluidly dissolves bento containers and shadows into pure Editorial paper hairlines.
/// - Spread Outward (> 1.22 scale with 2 fingers) on Editorial View:
///   Expands the typographic lines back into tactile Cards.
///
/// Can be toggled on/off in Settings ([UiPrefs.pinchToSwitchView], enabled by default).
class PinchViewSwitcher extends ConsumerStatefulWidget {
  final Widget child;

  const PinchViewSwitcher({super.key, required this.child});

  @override
  ConsumerState<PinchViewSwitcher> createState() => _PinchViewSwitcherState();
}

class _PinchViewSwitcherState extends ConsumerState<PinchViewSwitcher> {
  DateTime _lastToggle = DateTime.fromMillisecondsSinceEpoch(0);
  int _pointerCount = 0;

  void _onScaleStart(ScaleStartDetails details) {
    _pointerCount = details.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _pointerCount = details.pointerCount;
    if (_pointerCount < 2) return;

    final now = DateTime.now();
    if (now.difference(_lastToggle).inMilliseconds < 800) return;

    final s = ref.read(appSettingsProvider);
    final p = UiPrefs.of(s);
    if (!p.pinchToSwitchView) return;

    final currentStyle = s.cardStyle;
    final scale = details.scale;

    // Pinch inward: Cards -> Editorial
    if (currentStyle == 'bento' && scale < 0.84) {
      _lastToggle = now;
      HapticFeedback.mediumImpact();
      toggleViewStyle(context, ref, to: 'editorial');
      if (mounted) {
        AppToastEngine().showToast(
          context,
          title: 'Editorial View',
          message: 'Words on paper · Minimalist typography',
        );
      }
    }
    // Spread outward: Editorial -> Cards
    else if (currentStyle == 'editorial' && scale > 1.22) {
      _lastToggle = now;
      HapticFeedback.mediumImpact();
      toggleViewStyle(context, ref, to: 'bento');
      if (mounted) {
        AppToastEngine().showToast(
          context,
          title: 'Cards View',
          message: 'Tactile bento pods with depth',
        );
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _pointerCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: widget.child,
    );
  }
}
