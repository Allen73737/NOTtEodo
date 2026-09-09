import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

enum ToastType { success, info, alert }

class AppToastItem {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;

  AppToastItem({
    required this.title,
    required this.message,
    this.type = ToastType.success,
    this.duration = const Duration(seconds: 3),
  });
}

class AppToastEngine {
  static final AppToastEngine _instance = AppToastEngine._internal();
  factory AppToastEngine() => _instance;
  AppToastEngine._internal();

  final _toastStreamController = StreamController<AppToastItem>.broadcast();
  Stream<AppToastItem> get toastStream => _toastStreamController.stream;

  void showToast(BuildContext context, {required String title, required String message, ToastType type = ToastType.success}) {
    _toastStreamController.add(AppToastItem(title: title, message: message, type: type));
  }
}

class AppToastOverlay extends StatefulWidget {
  final Widget child;

  const AppToastOverlay({super.key, required this.child});

  @override
  State<AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<AppToastOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late StreamSubscription<AppToastItem> _subscription;
  AppToastItem? _currentToast;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _subscription = AppToastEngine().toastStream.listen(_handleNewToast);
  }

  void _handleNewToast(AppToastItem toast) {
    _dismissTimer?.cancel();
    setState(() {
      _currentToast = toast;
    });
    _animController.forward(from: 0.0);
    _dismissTimer = Timer(toast.duration, () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) setState(() => _currentToast = null);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _dismissTimer?.cancel();
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
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.8), end: Offset.zero).animate(
                CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(
                opacity: _animController,
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF142428).withValues(alpha: 0.9) : const Color(0xFFFAF7F0).withValues(alpha: 0.9),
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
                                // Wax Seal Emblem Icon Badge
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFD9725B),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'N',
                                      style: GoogleFonts.bodoniModa(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                ),
              ),
            ),
          ),
      ],
    );
  }
}
