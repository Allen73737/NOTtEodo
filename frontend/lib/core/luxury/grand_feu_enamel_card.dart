import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Grand Feu Enamel Card
/// Simulates the 800°C kiln-firing ritual: briefly heats with an incandescent
/// orange-gold firing pulse upon action before quenching into a vitreous porcelain finish.
class GrandFeuEnamelCard extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onSeal;

  const GrandFeuEnamelCard({
    super.key,
    required this.child,
    this.title = 'GRAND FEU ENAMEL SPECIFICATION',
    this.onSeal,
  });

  @override
  State<GrandFeuEnamelCard> createState() => _GrandFeuEnamelCardState();
}

class _GrandFeuEnamelCardState extends State<GrandFeuEnamelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fireController;
  late Animation<double> _heatGlow;
  bool _isSealed = false;

  @override
  void initState() {
    super.initState();
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heatGlow = CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  void _triggerKilnFiring() {
    HapticFeedback.heavyImpact();
    _fireController.forward(from: 0.0).then((_) {
      setState(() => _isSealed = true);
      widget.onSeal?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _heatGlow,
      builder: (context, child) {
        final heat = _heatGlow.value;
        // Peak heat around 0.4 - 0.6
        final heatIntensity = (1.0 - (heat - 0.5).abs() * 2.0).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFFD4AF37),
                const Color(0xFFFF6600),
                heatIntensity,
              )!,
              width: 1.5 + (heatIntensity * 1.5),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  isDark ? const Color(0xFF141416) : const Color(0xFFFAF8F5),
                  const Color(0xFF4A1A05),
                  heatIntensity * 0.7,
                )!,
                Color.lerp(
                  isDark ? const Color(0xFF0D0D0E) : const Color(0xFFEDE9E3),
                  const Color(0xFF1A0A02),
                  heatIntensity * 0.7,
                )!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(
                  const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  const Color(0xFFFF5500).withValues(alpha: 0.6),
                  heatIntensity,
                )!,
                blurRadius: 10 + (heatIntensity * 25),
                spreadRadius: heatIntensity * 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: Color.lerp(
                          const Color(0xFFD4AF37),
                          const Color(0xFFFF7A1A),
                          heatIntensity,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSealed ? Icons.local_fire_department : Icons.whatshot_outlined,
                        size: 18,
                        color: _isSealed ? const Color(0xFFFF7A1A) : const Color(0xFFD4AF37),
                      ),
                      onPressed: _triggerKilnFiring,
                      tooltip: 'Trigger 800°C Grand Feu Firing',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x22D4AF37)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}
