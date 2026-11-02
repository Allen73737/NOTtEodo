import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../brand/notteodo_monogram.dart';
import '../motion/motion.dart';

enum ToastType { success, info, alert }

class AppToastItem {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;

  /// Optional inline action, e.g. "Undo" after a deletion.
  final String? actionLabel;
  final VoidCallback? onAction;

  AppToastItem({
    required this.title,
    required this.message,
    this.type = ToastType.success,
    this.duration = const Duration(seconds: 3),
    this.actionLabel,
    this.onAction,
  });
}

class AppToastEngine {
  static final AppToastEngine _instance = AppToastEngine._internal();
  factory AppToastEngine() => _instance;
  AppToastEngine._internal();

  final _toastStreamController = StreamController<AppToastItem>.broadcast();
  Stream<AppToastItem> get toastStream => _toastStreamController.stream;

  void showToast(BuildContext context,
      {required String title, required String message, ToastType type = ToastType.success}) {
    notify(title: title, message: message, type: type);
  }

  /// Shows a toast from anywhere, including state notifiers that have no BuildContext.
  /// Toasts with an action stay up longer so there is time to use it.
  void notify({
    required String title,
    required String message,
    ToastType type = ToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _toastStreamController.add(AppToastItem(
      title: title,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: Duration(seconds: actionLabel == null ? 3 : 6),
    ));
  }
}

class AppToastOverlay extends StatefulWidget {
  final Widget child;

  const AppToastOverlay({super.key, required this.child});

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay> with TickerProviderStateMixin {
  late AnimationController _animController;

  /// Remaining life of the current toast; drives the countdown hairline and pauses on hover.
  late AnimationController _life;
  late StreamSubscription<AppToastItem> _subscription;
  AppToastItem? _currentToast;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _life = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dismiss();
      });
    _subscription = AppToastEngine().toastStream.listen(_handleNewToast);
  }

  void _handleNewToast(AppToastItem toast) {
    setState(() {
      _currentToast = toast;
      _dragOffset = 0;
    });
    _animController.forward(from: 0.0);
    _life
      ..duration = toast.duration
      ..forward(from: 0);
  }

  void _dismiss() {
    if (!mounted || _currentToast == null) return;
    _life.stop();
    _animController.reverse().then((_) {
      if (mounted && _animController.isDismissed) setState(() => _currentToast = null);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _life.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF4F1EA) : AppColors.primary;
    final subtextColor = isDark ? const Color(0xFFB8C5C8) : AppColors.onSurfaceVariant;

    return Stack(
      children: [
        widget.child,
        if (_currentToast != null)
          Positioned(
            top: 54,
            left: 20,
            right: 20,
            child: MouseRegion(
              // Hovering holds the toast; leaving resumes its countdown.
              onEnter: (_) => _life.stop(),
              onExit: (_) {
                if (_currentToast != null && _animController.status != AnimationStatus.reverse) _life.forward();
              },
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragUpdate: (d) =>
                    setState(() => _dragOffset = (_dragOffset + d.delta.dy).clamp(-120.0, 24.0)),
                onVerticalDragEnd: (d) {
                  if (_dragOffset < -28 || d.velocity.pixelsPerSecond.dy < -300) {
                    _dismiss();
                  } else {
                    setState(() => _dragOffset = 0);
                  }
                },
                child: AnimatedSlide(
                  offset: Offset(0, _dragOffset / 80),
                  duration: const Duration(milliseconds: 180),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, -0.9), end: Offset.zero).animate(
                      CurvedAnimation(parent: _animController, curve: Motion.settle, reverseCurve: Curves.easeInCubic),
                    ),
                    child: FadeTransition(
                      opacity: _animController,
                      child: Material(
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFD9725B).withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD9725B).withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Wax Seal Emblem: the monogram inks itself as the toast lands.
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFD9725B),
                                    ),
                                    child: Center(
                                      child: AnimatedBuilder(
                                        animation: _animController,
                                        builder: (context, _) => CustomPaint(
                                          size: const Size.square(20),
                                          painter: NotteodoMonogramPainter(
                                            end: Curves.easeInOutCubic.transform(_animController.value),
                                            colors: const [Colors.white],
                                            weight: 1.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _currentToast!.title,
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _currentToast!.message,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: subtextColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        // Countdown hairline: how long until the toast leaves.
                                        AnimatedBuilder(
                                          animation: _life,
                                          builder: (context, _) => Align(
                                            alignment: Alignment.centerLeft,
                                            child: FractionallySizedBox(
                                              widthFactor: 1 - _life.value,
                                              child: Container(
                                                height: 1.5,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(1),
                                                  gradient: LinearGradient(colors: [
                                                    const Color(0xFFD9725B).withValues(alpha: 0.2),
                                                    const Color(0xFFD9725B),
                                                  ]),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_currentToast!.actionLabel != null) ...[
                                    const SizedBox(width: 10),
                                    _ToastAction(
                                      label: _currentToast!.actionLabel!,
                                      color: isDark ? const Color(0xFFE8927C) : AppColors.secondary,
                                      onTap: () {
                                        final action = _currentToast!.onAction;
                                        _dismiss();
                                        action?.call();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pill-shaped inline action inside a toast ("Undo").
class _ToastAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToastAction({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      hoverLift: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: color),
        ),
      ),
    );
  }
}
