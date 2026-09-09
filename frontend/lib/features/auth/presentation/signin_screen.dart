import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/stitch_logo_widget.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const SignInScreen({super.key, required this.onAuthenticated});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'curator.allen@notteodo.sanctuary');
  final _passCtrl = TextEditingController(text: '••••••••••••');
  bool _isSignUp = false;
  bool _obscurePassword = true;

  late AnimationController _auraController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _auraController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E1A17),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(LucideIcons.sparkles, color: Color(0xFFE8927C), size: 18),
            SizedBox(width: 10),
            Text('✨ Google Workspace Key Verified. Welcome, Curator.'),
          ],
        ),
      ),
    );
    widget.onAuthenticated();
  }

  void _handleBiometricSignIn() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E1A17),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(LucideIcons.fingerprint, color: Color(0xFF86CBB0), size: 18),
            SizedBox(width: 10),
            Text('🔒 Biometric Key Recognized. Unsealing Sanctuary Vault...'),
          ],
        ),
      ),
    );
    widget.onAuthenticated();
  }

  void _handleEmailSubmit() {
    HapticFeedback.mediumImpact();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFF9E9A92) : const Color(0xFF635F59);
    final accentColor = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    const goldColor = Color(0xFFEAB368);

    final cardBg = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.94)
        : const Color(0xFFFAF8F5).withValues(alpha: 0.94);

    final inputBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0EBE3);
    final inputBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE0D8CC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF9F7F4),
      body: Stack(
        children: [
          // 1. Atmospheric Celestial Sacred Geometry Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auraController,
              builder: (context, child) {
                final aura = _auraController.value;
                return CustomPaint(
                  painter: _VaultAtmospherePainter(
                    isDark: isDark,
                    aura: aura,
                    rotation: _rotationController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Haute Horlogerie Emblem Header
                      _buildHauteHorlogerieHeader(isDark, accentColor, goldColor),
                      const SizedBox(height: 28),

                      // Sculpted "Curator's Keyhole" Vault Card
                      AnimatedBuilder(
                        animation: _auraController,
                        builder: (context, child) {
                          final auraGlow = _auraController.value;
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? accentColor : AppColors.primary)
                                      .withValues(alpha: isDark ? 0.22 + auraGlow * 0.14 : 0.08),
                                  blurRadius: 40 + auraGlow * 12,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.85 : 0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: Container(
                                  padding: const EdgeInsets.all(26),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: isDark
                                          ? Color.lerp(
                                              const Color(0xFF282828),
                                              accentColor.withValues(alpha: 0.7),
                                              auraGlow,
                                            )!
                                          : Color.lerp(
                                              const Color(0xFFE2D9CC),
                                              accentColor.withValues(alpha: 0.6),
                                              auraGlow,
                                            )!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Sliding Dual-Mode Pill Selector
                                      _buildSlidingModeSelector(isDark, accentColor, primaryTextColor),
                                      const SizedBox(height: 22),

                                      // Header Typography
                                      Text(
                                        _isSignUp ? 'Initiate Sanctuary' : 'Unseal Your Sanctuary',
                                        style: GoogleFonts.bodoniModa(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isSignUp
                                            ? 'Create a cryptographic profile to sync your curated modules.'
                                            : 'Enter your curator credentials or biometric key to unseal local vault.',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: subtextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 22),

                                      // Google Workspace Authentication Capsule
                                      _buildGoogleAuthButton(isDark, accentColor, primaryTextColor),
                                      const SizedBox(height: 18),

                                      // Laser Divider with Wax Seal
                                      _buildWaxSealDivider(isDark, subtextColor, goldColor),
                                      const SizedBox(height: 18),

                                      // Inset Email Well
                                      _buildSculptedInputField(
                                        controller: _emailCtrl,
                                        label: 'CURATOR EMAIL',
                                        icon: LucideIcons.mail,
                                        isDark: isDark,
                                        inputBg: inputBg,
                                        inputBorder: inputBorder,
                                        primaryTextColor: primaryTextColor,
                                        accentColor: accentColor,
                                      ),
                                      const SizedBox(height: 14),

                                      // Inset Password Well
                                      _buildSculptedInputField(
                                        controller: _passCtrl,
                                        label: 'SANCTUARY CIPHER KEY',
                                        icon: LucideIcons.lock,
                                        isDark: isDark,
                                        inputBg: inputBg,
                                        inputBorder: inputBorder,
                                        primaryTextColor: primaryTextColor,
                                        accentColor: accentColor,
                                        isPassword: true,
                                        obscure: _obscurePassword,
                                        onToggleObscure: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                      ),
                                      const SizedBox(height: 22),

                                      // Biometric Fast Entry Chip
                                      _buildBiometricAccessChip(isDark, accentColor, primaryTextColor),
                                      const SizedBox(height: 18),

                                      // Grand Unseal Button
                                      _buildMasterUnsealButton(isDark, accentColor),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Local-First Encrypted Sovereignty Assurance
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF86CBB0)),
                            const SizedBox(width: 6),
                            Text(
                              'AES-256 Encrypted • Zero Surveillance Offline Vault',
                              style: GoogleFonts.dmSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark ? const Color(0xFF86CBB0) : const Color(0xFF2C6B56),
                              ),
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
        ],
      ),
    );
  }

  /// Haute Horlogerie Astronomical Monogram Emblem Header
  Widget _buildHauteHorlogerieHeader(bool isDark, Color accentColor, Color goldColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Astronomical Tick Bezel
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: goldColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Center Monogram Logo
            const StitchLogoWidget(fontSize: 26, showMonogramN: true, showTagline: false),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'NOTTeodo Sanctuary',
          style: GoogleFonts.bodoniModa(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'AESTHETIC LIFE ARCHITECTURE',
          style: GoogleFonts.dmSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  /// Sliding Dual-Mode Selector (Sign In vs Initiate)
  Widget _buildSlidingModeSelector(bool isDark, Color accentColor, Color textColor) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFEDE6DC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFDDD4C8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isSignUp = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: !_isSignUp
                      ? (isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFFFFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: !_isSignUp
                      ? Border.all(color: accentColor.withValues(alpha: 0.6))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'CURATOR SIGN IN',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: !_isSignUp ? accentColor : textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isSignUp = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: _isSignUp
                      ? (isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFFFFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: _isSignUp
                      ? Border.all(color: accentColor.withValues(alpha: 0.6))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'INITIATE SANCTUARY',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _isSignUp ? accentColor : textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Google Workspace Authentication Capsule
  Widget _buildGoogleAuthButton(bool isDark, Color accentColor, Color textColor) {
    return BouncyTouchEffect(
      pressedScale: 0.95,
      onTap: _handleGoogleSignIn,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF282828) : const Color(0xFFDDD5C8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  'G',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isSignUp ? 'Initiate with Google Key' : 'Continue with Google Workspace',
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Laser Divider Interrupted by Golden Wax Seal
  Widget _buildWaxSealDivider(bool isDark, Color subColor, Color goldColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF222222) : const Color(0xFFE2D9CD),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : const Color(0xFFEFE8DE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: goldColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.keyRound, size: 11, color: goldColor),
                const SizedBox(width: 5),
                Text(
                  'OR VAULT KEY',
                  style: GoogleFonts.dmSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: goldColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF222222) : const Color(0xFFE2D9CD),
          ),
        ),
      ],
    );
  }

  /// Bespoke Sculpted Inset Input Field
  Widget _buildSculptedInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color inputBg,
    required Color inputBorder,
    required Color primaryTextColor,
    required Color accentColor,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: inputBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 17, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword ? obscure : false,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (isPassword)
                GestureDetector(
                  onTap: onToggleObscure,
                  child: Icon(
                    obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 16,
                    color: primaryTextColor.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Biometric Fast Entry Chip
  Widget _buildBiometricAccessChip(bool isDark, Color accentColor, Color textColor) {
    return BouncyTouchEffect(
      pressedScale: 0.94,
      onTap: _handleBiometricSignIn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF86CBB0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF86CBB0).withValues(alpha: 0.6), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.fingerprint, size: 20, color: Color(0xFF86CBB0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric Quick Unseal',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Curator Allen • Touch ID / Face Recognition Active',
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      color: const Color(0xFF86CBB0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF86CBB0)),
          ],
        ),
      ),
    );
  }

  /// Grand Master Unseal Button
  Widget _buildMasterUnsealButton(bool isDark, Color accentColor) {
    return BouncyTouchEffect(
      pressedScale: 0.95,
      onTap: _handleEmailSubmit,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A17) : const Color(0xFF1C1917),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withValues(alpha: 0.85), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSignUp ? 'SEAL & INITIATE SANCTUARY' : 'UNSEAL SANCTUARY VAULT',
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Icon(LucideIcons.sparkles, size: 17, color: accentColor),
          ],
        ),
      ),
    );
  }
}

/// Atmospheric Sacred Geometry Canvas Painter for Vault
class _VaultAtmospherePainter extends CustomPainter {
  final bool isDark;
  final double aura;
  final double rotation;

  _VaultAtmospherePainter({
    required this.isDark,
    required this.aura,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark
          ? const Color(0xFFE8927C).withValues(alpha: 0.03 + aura * 0.02)
          : const Color(0xFF7E301B).withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.28);

    // Concentric Celestial Vault Circles
    canvas.drawCircle(center, 90 + aura * 10, linePaint);
    canvas.drawCircle(center, 160, linePaint);
    canvas.drawCircle(center, 240 + aura * 12, linePaint);

    // Axis Lines
    canvas.drawLine(
      Offset(center.dx - 220, center.dy),
      Offset(center.dx + 220, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VaultAtmospherePainter oldDelegate) {
    return oldDelegate.aura != aura || oldDelegate.rotation != rotation || oldDelegate.isDark != isDark;
  }
}
