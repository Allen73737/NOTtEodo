import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/security/password_policy.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/widgets/fluid_ui_effects.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import 'mfa_dialogs.dart';
import '../../../core/services/local_store.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback? onAdminAuthenticated;

  const SignInScreen({super.key, required this.onAuthenticated, this.onAdminAuthenticated});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
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
  late AnimationController _logoPulseController;

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

    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _auraController.dispose();
    _rotationController.dispose();
    _logoPulseController.dispose();
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
    final name = _nameCtrl.text.trim();

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
      if (name.isNotEmpty) {
        final current = LocalStore().readMap('settings') ?? {};
        LocalStore().writeMap('settings', {...current, 'displayName': name});
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
      // Admin rights come only from the server's admin list, never from the app.
      if (!_isSignUp && await SanctuarySupabaseService().isAppAdmin()) {
        LocalStore().writeBool('is_admin_session', true);
        if (mounted && widget.onAdminAuthenticated != null) {
          widget.onAdminAuthenticated!();
          return;
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
    const terracotta = Color(0xFFD9725B);
    const warmSage = Color(0xFF8FA878);
    const goldColor = Color(0xFFEAB368);

    final modeAccent = _isSignUp ? warmSage : terracotta;

    final cardBg = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.94)
        : const Color(0xFFFAF8F5).withValues(alpha: 0.95);

    final inputBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0EBE3);
    final inputBorder = isDark ? const Color(0xFF242424) : const Color(0xFFE0D8CC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF9F7F4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final isCompact = availableHeight < 760;

          return Stack(
            children: [
              // 1. Atmospheric Celestial Geometry Canvas
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
                        accentColor: modeAccent,
                      ),
                    );
                  },
                ),
              ),

              // 2. Main Content Viewport (Compact & Zero-Scroll by default)
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isCompact ? 8 : 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Haute Horlogerie Emblem Header
                          _buildAnimatedHeader(isDark, modeAccent, isCompact),
                          SizedBox(height: isCompact ? 10 : 16),

                          // Sculpted Vault Sanctuary Card
                          AnimatedBuilder(
                            animation: _auraController,
                            builder: (context, child) {
                              final auraGlow = _auraController.value;
                              return Container(
                                decoration: edBox(
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: modeAccent.withValues(alpha: isDark ? 0.2 + auraGlow * 0.12 : 0.07),
                                      blurRadius: 32 + auraGlow * 8,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: isCompact ? 14 : 20,
                                  ),
                                  decoration: edBox(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: isDark
                                          ? Color.lerp(
                                              const Color(0xFF262626),
                                              modeAccent.withValues(alpha: 0.65),
                                              auraGlow,
                                            )!
                                          : Color.lerp(
                                              const Color(0xFFE2D9CC),
                                              modeAccent.withValues(alpha: 0.55),
                                              auraGlow,
                                            )!,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Sliding Dual-Mode Segmented Capsule
                                      _buildSlidingModeSelector(isDark, terracotta, warmSage, primaryTextColor),
                                      SizedBox(height: isCompact ? 10 : 14),

                                      // Distinct Visual Identity Header
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        transitionBuilder: (child, anim) => FadeTransition(
                                          opacity: anim,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.04, 0),
                                              end: Offset.zero,
                                            ).animate(anim),
                                            child: child,
                                          ),
                                        ),
                                        child: _isSignUp
                                            ? _buildCreateAccountHeader(warmSage, primaryTextColor, subtextColor)
                                            : _buildSignInHeader(terracotta, primaryTextColor, subtextColor),
                                      ),
                                      SizedBox(height: isCompact ? 10 : 14),

                                      // Google Authentication Quick Capsule
                                      _buildGoogleAuthButton(isDark, modeAccent, primaryTextColor, isCompact),
                                      SizedBox(height: isCompact ? 8 : 12),

                                      // Divider with Wax Seal
                                      _buildWaxSealDivider(isDark, subtextColor, goldColor),
                                      SizedBox(height: isCompact ? 8 : 12),

                                      // Input Fields (with Name in Create Account mode)
                                      if (_isSignUp) ...[
                                        _buildSculptedInputField(
                                          controller: _nameCtrl,
                                          label: 'CURATOR NAME',
                                          hint: 'Preferred display name',
                                          icon: LucideIcons.user,
                                          isDark: isDark,
                                          inputBg: inputBg,
                                          inputBorder: inputBorder,
                                          primaryTextColor: primaryTextColor,
                                          accentColor: warmSage,
                                          isCompact: isCompact,
                                        ),
                                        SizedBox(height: isCompact ? 8 : 10),
                                      ],

                                      // Email Field
                                      _buildSculptedInputField(
                                        controller: _emailCtrl,
                                        label: 'EMAIL ADDRESS',
                                        hint: 'curator@sanctuary.app',
                                        icon: LucideIcons.mail,
                                        isDark: isDark,
                                        inputBg: inputBg,
                                        inputBorder: inputBorder,
                                        primaryTextColor: primaryTextColor,
                                        accentColor: modeAccent,
                                        isCompact: isCompact,
                                      ),
                                      SizedBox(height: isCompact ? 8 : 10),

                                      // Password Field
                                      _buildSculptedInputField(
                                        controller: _passCtrl,
                                        label: _isSignUp ? 'CREATE PASSWORD' : 'PASSWORD',
                                        hint: '••••••••',
                                        icon: LucideIcons.lock,
                                        isDark: isDark,
                                        inputBg: inputBg,
                                        inputBorder: inputBorder,
                                        primaryTextColor: primaryTextColor,
                                        accentColor: modeAccent,
                                        isPassword: true,
                                        obscure: _obscurePassword,
                                        isCompact: isCompact,
                                        onToggleObscure: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                      ),

                                      if (_isSignUp && _strength != null) ...[
                                        _buildStrengthMeter(_strength!, isDark),
                                      ],

                                      if (!_isSignUp) ...[
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: _busy ? null : _handleForgotPassword,
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 6, bottom: 4),
                                              child: Text(
                                                'Forgot password?',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: terracotta,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      if (_error != null || _notice != null) ...[
                                        SizedBox(height: isCompact ? 6 : 8),
                                        _buildMessage(_error ?? _notice!, isError: _error != null, isDark: isDark),
                                      ],
                                      SizedBox(height: isCompact ? 10 : 14),

                                      // Primary Submit Button
                                      _buildMasterUnsealButton(isDark, modeAccent, isCompact),
                                      SizedBox(height: isCompact ? 6 : 8),

                                      // Secondary Inline Action Links
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: _busy ? null : _continueWithoutAccount,
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'Explore offline without account',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isCompact ? 8 : 14),

                          // Local Sovereignty Guarantee
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.shieldCheck, size: 12, color: Color(0xFF8FA878)),
                              const SizedBox(width: 5),
                              Text(
                                'Saved on device • Synced only when you sign in',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF8FA878) : const Color(0xFF4C613D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Animated Header with breathing emblem
  Widget _buildAnimatedHeader(bool isDark, Color accentColor, bool isCompact) {
    return AnimatedBuilder(
      animation: _logoPulseController,
      builder: (context, child) {
        final pulse = _logoPulseController.value;
        return Column(
          children: [
            Container(
              decoration: edBox(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2 + pulse * 0.15),
                    blurRadius: 18 + pulse * 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: StitchMonogramNWidget(size: isCompact ? 36 : 42),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              'NOTtEodo',
              style: GoogleFonts.bodoniModa(
                fontSize: isCompact ? 19 : 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1B1917),
              ),
            ),
            Text(
              'AESTHETIC LIFE ARCHITECTURE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Sliding Dual-Mode Segmented Capsule
  Widget _buildSlidingModeSelector(bool isDark, Color terracotta, Color warmSage, Color textColor) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: edBox(
        color: isDark ? const Color(0xFF0F0E0C) : const Color(0xFFECE6DD),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isDark ? const Color(0xFF26221E) : const Color(0xFFDBD3C7),
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
                duration: const Duration(milliseconds: 220),
                decoration: edBox(
                  color: !_isSignUp
                      ? (isDark ? const Color(0xFF1E1A17) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: !_isSignUp ? Border.all(color: terracotta.withValues(alpha: 0.6)) : null,
                  boxShadow: !_isSignUp
                      ? [
                          BoxShadow(
                            color: terracotta.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.keyRound,
                      size: 11,
                      color: !_isSignUp ? terracotta : textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SIGN IN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: !_isSignUp ? terracotta : textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
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
                duration: const Duration(milliseconds: 220),
                decoration: edBox(
                  color: _isSignUp
                      ? (isDark ? const Color(0xFF181C16) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: _isSignUp ? Border.all(color: warmSage.withValues(alpha: 0.6)) : null,
                  boxShadow: _isSignUp
                      ? [
                          BoxShadow(
                            color: warmSage.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 11,
                      color: _isSignUp ? warmSage : textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'CREATE ACCOUNT',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: _isSignUp ? warmSage : textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header in Sign In mode
  Widget _buildSignInHeader(Color terracotta, Color primaryText, Color subText) {
    return Column(
      key: const ValueKey('header_signin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: edBox(
                color: terracotta.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: terracotta.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.lock, size: 10, color: terracotta),
                  const SizedBox(width: 4),
                  Text(
                    'SANCTUARY VAULT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: terracotta,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Welcome Back',
          style: GoogleFonts.bodoniModa(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        Text(
          'Unlock your synchronized workspace and active streak.',
          style: GoogleFonts.dmSans(fontSize: 11.5, color: subText),
        ),
      ],
    );
  }

  /// Header in Create Account mode
  Widget _buildCreateAccountHeader(Color warmSage, Color primaryText, Color subText) {
    return Column(
      key: const ValueKey('header_signup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: edBox(
                color: warmSage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: warmSage.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.sparkles, size: 10, color: warmSage),
                  const SizedBox(width: 4),
                  Text(
                    'GENESIS ENROLLMENT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: warmSage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Create Your Workspace',
          style: GoogleFonts.bodoniModa(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        Text(
          'Establish your private, encrypted cloud sanctuary across devices.',
          style: GoogleFonts.dmSans(fontSize: 11.5, color: subText),
        ),
      ],
    );
  }

  /// Google Workspace Authentication Capsule
  Widget _buildGoogleAuthButton(bool isDark, Color accentColor, Color textColor, bool isCompact) {
    return BouncyTouchEffect(
      pressedScale: 0.96,
      onTap: _handleGoogleSignIn,
      child: Container(
        height: isCompact ? 40 : 44,
        decoration: edBox(
          color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF282828) : const Color(0xFFDDD5C8),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: edBox(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  'G',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isSignUp ? 'Sign up with Google' : 'Continue with Google',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wax Seal Divider
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: edBox(
              color: isDark ? const Color(0xFF141414) : const Color(0xFFEFE8DE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: goldColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.keyRound, size: 9, color: goldColor),
                const SizedBox(width: 4),
                Text(
                  'OR EMAIL',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
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

  /// Sculpted Inset Input Field
  Widget _buildSculptedInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color inputBg,
    required Color inputBorder,
    required Color primaryTextColor,
    required Color accentColor,
    required bool isCompact,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: edBox(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inputBorder, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.9,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword ? obscure : false,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: primaryTextColor.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (isPassword)
                GestureDetector(
                  onTap: onToggleObscure,
                  child: Icon(
                    obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 15,
                    color: primaryTextColor.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Live Password Strength Meter
  Widget _buildStrengthMeter(PasswordCheck check, bool isDark) {
    const colors = [Color(0xFFC0392B), Color(0xFFD35400), Color(0xFFC9A227), Color(0xFF5E9E6E), Color(0xFF2E8B57)];
    final color = colors[check.score];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 3),
                    decoration: edBox(
                      color: i < check.score ? color : (isDark ? const Color(0xFF242424) : const Color(0xFFE0D8CC)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            check.problem ?? '${check.label} password',
            style: GoogleFonts.dmSans(fontSize: 11.5, color: check.acceptable ? color : const Color(0xFFC0392B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, {required bool isError, required bool isDark}) {
    final tone = isError ? const Color(0xFFD9725B) : const Color(0xFF8FA878);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: edBox(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? LucideIcons.alertCircle : LucideIcons.checkCircle2, size: 14, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                height: 1.3,
                color: isDark ? Colors.white : const Color(0xFF1B1917),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Master Action Button
  Widget _buildMasterUnsealButton(bool isDark, Color accentColor, bool isCompact) {
    return BouncyTouchEffect(
      pressedScale: 0.96,
      onTap: _busy ? null : _handleEmailSubmit,
      child: Container(
        height: isCompact ? 44 : 48,
        width: double.infinity,
        decoration: edBox(
          color: isDark ? const Color(0xFF1C1815) : const Color(0xFF1A1715),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.85), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _busy ? 'PLEASE WAIT…' : (_isSignUp ? 'BEGIN YOUR JOURNEY' : 'UNLOCK SANCTUARY'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _isSignUp ? LucideIcons.sparkles : LucideIcons.keyRound,
              size: 15,
              color: accentColor,
            ),
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
  final Color accentColor;

  _VaultAtmospherePainter({
    required this.isDark,
    required this.aura,
    required this.rotation,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.04 + aura * 0.03 : 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.25);

    // Concentric Celestial Vault Circles
    canvas.drawCircle(center, 80 + aura * 8, linePaint);
    canvas.drawCircle(center, 150, linePaint);
    canvas.drawCircle(center, 230 + aura * 10, linePaint);

    // Axis Lines
    canvas.drawLine(
      Offset(center.dx - 200, center.dy),
      Offset(center.dx + 200, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VaultAtmospherePainter oldDelegate) {
    return oldDelegate.aura != aura ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}
