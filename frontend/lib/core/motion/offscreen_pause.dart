import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Mutes every ticker below it (ambient loops, shimmer, gauges) while the subtree is
/// scrolled out of view, and resumes them the moment it returns. Visibility is sampled
/// on frames the app renders anyway, a few times a second at most, so idle screens
/// cost nothing and long scrolling pages stop animating what nobody can see.
class OffscreenPause extends StatefulWidget {
  final Widget child;

  const OffscreenPause({super.key, required this.child});

  @override
  State<OffscreenPause> createState() => _OffscreenPauseState();
}

class _OffscreenPauseState extends State<OffscreenPause> {
  bool _onScreen = true;

  @override
  void initState() {
    super.initState();
    _VisibilitySampler.instance.add(this);
  }

  @override
  void dispose() {
    _VisibilitySampler.instance.remove(this);
    super.dispose();
  }

  void _update(bool onScreen) {
    if (onScreen != _onScreen && mounted) setState(() => _onScreen = onScreen);
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion also stills ambient loops; functional animation elsewhere is unaffected.
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TickerMode(enabled: _onScreen && !reduced, child: widget.child);
  }
}

class _VisibilitySampler {
  _VisibilitySampler._();
  static final _VisibilitySampler instance = _VisibilitySampler._();

  static const Duration _interval = Duration(milliseconds: 250);

  final Set<_OffscreenPauseState> _states = {};
  bool _hooked = false;
  Duration _lastSample = Duration.zero;

  void add(_OffscreenPauseState s) {
    _states.add(s);
    if (!_hooked) {
      _hooked = true;
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    }
  }

  void remove(_OffscreenPauseState s) {
    _states.remove(s);
    if (_states.isEmpty) {
      _trailing?.cancel();
      _trailing = null;
    }
  }

  void _onFrame(Duration timestamp) {
    if (_states.isEmpty) return;
    final since = timestamp - _lastSample;
    if (since < _interval) {
      // Throttled: guarantee one trailing sample so content that came into view at the
      // very end of a scroll is woken even if nothing else asks for another frame.
      _trailing ??= Timer(_interval - since, () {
        _trailing = null;
        SchedulerBinding.instance.scheduleFrame();
      });
      return;
    }
    _lastSample = timestamp;
    // Defer to after layout/paint of this frame so geometry is final.
    SchedulerBinding.instance.addPostFrameCallback((_) => _sample());
  }

  Timer? _trailing;

  void _sample() {
    for (final state in _states.toList()) {
      if (!state.mounted) continue;
      final box = state.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final view = View.maybeOf(state.context);
      if (view == null) continue;
      // A generous margin wakes content just before it scrolls into view.
      final screen = (Offset.zero & (view.physicalSize / view.devicePixelRatio)).inflate(160);
      final rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
      state._update(rect.overlaps(screen));
    }
  }
}
