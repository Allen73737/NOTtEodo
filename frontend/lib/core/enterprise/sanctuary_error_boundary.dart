import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sanctuary_logger.dart';
import '../motion/motion.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

/// Enterprise Error Boundary & Graceful Recovery Widget
/// Intercepts widget build errors, logs structured diagnostics,
/// and presents a dignified Haute Horlogerie recovery card.
class SanctuaryErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails details)? errorBuilder;

  const SanctuaryErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  static SanctuaryErrorBoundaryState? of(BuildContext context) {
    return context.findAncestorStateOfType<SanctuaryErrorBoundaryState>();
  }

  @override
  State<SanctuaryErrorBoundary> createState() => SanctuaryErrorBoundaryState();
}

class SanctuaryErrorBoundaryState extends State<SanctuaryErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  late final Widget Function(FlutterErrorDetails) _originalErrorWidgetBuilder;

  @override
  void initState() {
    super.initState();
    _originalErrorWidgetBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _errorDetails == null) {
            setState(() {
              _errorDetails = details;
            });
          }
        });
      }
      return _buildEnterpriseFallback(context, details);
    };
  }

  @override
  void dispose() {
    ErrorWidget.builder = _originalErrorWidgetBuilder;
    super.dispose();
  }

  void reportError(FlutterErrorDetails details) {
    if (mounted) {
      setState(() {
        _errorDetails = details;
      });
    }
  }

  void resetError() {
    if (mounted) {
      setState(() {
        _errorDetails = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }
      return _buildEnterpriseFallback(context, _errorDetails!);
    }

    return widget.child;
  }

  Widget _buildEnterpriseFallback(BuildContext context, FlutterErrorDetails details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SanctuaryLogger().error(
      'ErrorBoundary',
      'UI Rendering Exception Intercepted',
      error: details.exception,
      stackTrace: details.stack,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAF7F0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: edBox(
            color: isDark ? const Color(0xFF141416) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9725B), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 48, color: Color(0xFFD9725B)),
              const SizedBox(height: 16),
              Text(
                'SANCTUARY EQUILIBRIUM PRESERVED',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFFD9725B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'An unexpected rendering aberration was intercepted by the Enterprise Error Boundary. Your encrypted state remains pristine and undisturbed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spectral(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Pressable(pressedScale: 0.95, hoverLift: 0, child: ElevatedButton.icon(
                onPressed: resetError,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'RESTORE EQUILIBRIUM',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9725B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
