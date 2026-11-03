import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/password_policy.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import 'mfa_dialogs.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const SignInScreen({super.key, required this.onAuthenticated});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;
  String? _notice;

  bool get _cloudReady => SanctuarySupabaseService().isInitialized;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late AnimationController _auraController;
  late AnimationController _rotationController;

  PasswordCheck? _strength;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      if (!_isSignUp) return;
      final next = _passCtrl.text.isEmpty ? null : PasswordPolicy.evaluate(_passCtrl.text, email: _emailCtrl.text);
      if (next?.score != _strength?.score || next?.problem != _strength?.problem) setState(() => _strength = next);
    });
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

  void _showMessage({String? error, String? notice}) {
    if (!mounted) return;
    setState(() {
      _error = error;
      _notice = notice;
    });
  }

  static String _friendly(Object e) {
    if (e is AuthException) return e.message;
    final text = e.toString();
    return text.startsWith('Bad state: ') ? text.substring(11) : text;
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    if (!_cloudReady) {
      _showMessage(error: 'Cloud accounts are not set up in this build. You can continue without an account.');
      return;
    }
    setState(() => _busy = true);
    try {
      // On web this redirects to Google and back; the session is picked up on return.
      await SanctuarySupabaseService().signInWithGoogle();
      final user = SanctuarySupabaseService().currentUser;
      if (user != null && mounted) {
        widget.onAuthenticated();
      }
    } catch (e) {
      _showMessage(error: _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      _showMessage(error: 'Enter your email above first, then tap "Forgot password?".');
      return;
    }
    if (!_cloudReady) {
      _showMessage(error: 'Cloud accounts are not set up in this build.');
      return;
    }
    try {
      await SanctuarySupabaseService().sendPasswordReset(email);
      _showMessage(notice: 'If an account exists for $email, a reset link is on its way.');
    } catch (e) {
      _showMessage(error: _friendly(e));
    }
  }

  void _continueWithoutAccount() {
    HapticFeedback.selectionClick();
    widget.onAuthenticated();
  }

  Future<void> _handleEmailSubmit() async {
    HapticFeedback.mediumImpact();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (!_emailPattern.hasMatch(email)) {
      _showMessage(error: 'Enter a valid email address.');
      return;
    }
    if (_isSignUp) {
      final check = PasswordPolicy.evaluate(password, email: email);
      if (!check.acceptable) {
        _showMessage(error: check.problem);
        return;
      }
    } else if (password.isEmpty) {
      _showMessage(error: 'Enter your password.');
      return;
    }
    if (!_cloudReady) {
      _showMessage(error: 'Cloud accounts are not set up in this build. You can continue without an account.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_isSignUp) {
        // Only a 5-character hash prefix is sent (k-anonymity); offline, the check is skipped.
        final breaches = await PasswordPolicy.breachCount(password);
        if (breaches != null && breaches > 0) {
          _showMessage(
              error: 'This password has appeared in $breaches known data breaches. Please choose a different one.');
          return;
        }
        final res = await SanctuarySupabaseService().signUp(email: email, password: password);
        if (res?.session == null) {
          _showMessage(notice: 'Check $email to confirm your account, then sign in.');
          if (mounted) setState(() => _isSignUp = false);
          return;
        }
      } else {
        await SanctuarySupabaseService().signIn(email: email, password: password);
        if (await SanctuarySupabaseService().needsMfaStepUp()) {
          if (!mounted) return;
          final verified = await showMfaChallenge(context);
          if (!verified) {
            await SanctuarySupabaseService().signOut();
            _showMessage(error: 'Sign-in cancelled: the two-step code is required for this account.');
            return;
          }
        }
      }
      if (mounted) widget.onAuthenticated();
    } catch (e) {
      _showMessage(error: _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                                        _isSignUp ? 'Create your account' : 'Welcome back',
                                        style: GoogleFonts.bodoniModa(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isSignUp
                                            ? 'Create an account to back up and sync your data across devices.'
                                            : 'Sign in to sync your data. Everything also works without an account.',
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
                                        label: 'EMAIL',
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
                                        label: 'PASSWORD',
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
                                      if (_isSignUp && _strength != null) _buildStrengthMeter(_strength!, isDark),
                                      const SizedBox(height: 22),

                                      if (!_isSignUp)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: _busy ? null : _handleForgotPassword,
                                            child: Text('Forgot password?',
                                                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor)),
                                          ),
                                        ),
                                      if (_error != null || _notice != null) ...[
                                        _buildMessage(_error ?? _notice!, isError: _error != null, isDark: isDark),
                                        const SizedBox(height: 14),
                                      ],

                                      // Grand Unseal Button
                                      _buildMasterUnsealButton(isDark, accentColor),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: TextButton(
                                          onPressed: _busy ? null : _continueWithoutAccount,
                                          child: Text('Continue without an account',
                                              style: GoogleFonts.dmSans(
                                                  fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryTextColor)),
                                        ),
                                      ),
                                    ],
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
                              'Saved on this device â€¢ Synced only when you sign in',
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
                setState(() {
                  _isSignUp = false;
                  _error = null;
                  _notice = null;
                });
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
                    'SIGN IN',
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
                setState(() {
                  _isSignUp = true;
                  _error = null;
                  _notice = null;
                });
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
                    'CREATE ACCOUNT',
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
              _isSignUp ? 'Sign up with Google' : 'Continue with Google',
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
                  'OR EMAIL',
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
  Widget _buildStrengthMeter(PasswordCheck check, bool isDark) {
    const colors = [Color(0xFFC0392B), Color(0xFFD35400), Color(0xFFC9A227), Color(0xFF5E9E6E), Color(0xFF2E8B57)];
    final color = colors[check.score];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < check.score ? color : (isDark ? const Color(0xFF242424) : const Color(0xFFE0D8CC)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            check.problem ?? '${check.label} password',
            style: GoogleFonts.dmSans(fontSize: 11.5, color: check.acceptable ? color : const Color(0xFFC0392B)),
          ),
        ],
      ),
    );
  }

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

  Widget _buildMessage(String text, {required bool isError, required bool isDark}) {
    final tone = isError ? const Color(0xFFD9725B) : const Color(0xFF86CBB0);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tone.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isError ? LucideIcons.alertCircle : LucideIcons.mailCheck, size: 16, color: tone),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, height: 1.4, color: isDark ? Colors.white : const Color(0xFF1B1917))),
            ),
          ],
        ),
      ),
    );
  }

  /// Grand Master Unseal Button
  Widget _buildMasterUnsealButton(bool isDark, Color accentColor) {
    return BouncyTouchEffect(
      pressedScale: 0.95,
      onTap: _busy ? null : _handleEmailSubmit,
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
              _busy ? 'PLEASE WAITâ€¦' : (_isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN'),
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
