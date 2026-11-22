import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/security/password_policy.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/widgets/stitch_logo_widget.dart';
import 'mfa_dialogs.dart';
import '../../../core/services/local_store.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';
import 'package:notteodo/core/editorial/view_style_glyph.dart';
import '../../../core/state/app_settings.dart';
import '../../settings/presentation/terms_conditions_subpage.dart';
import '../../settings/presentation/privacy_safety_subpage.dart';
import 'account_recovery_dialog.dart';
import 'emergency_kit_dialog.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback? onAdminAuthenticated;

  const SignInScreen({super.key, required this.onAuthenticated, this.onAdminAuthenticated});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with TickerProviderStateMixin {
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
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _auraController.dispose();
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
    await AccountRecoveryDialog.show(
      context,
      initialEmail: email,
      onContinueOffline: _continueWithoutAccount,
      onCredentialsReset: (resetEmail, newPassword) {
        if (resetEmail.isNotEmpty) _emailCtrl.text = resetEmail;
        _passCtrl.text = newPassword;
        _showMessage(notice: 'Password updated. Tap "Sign in" to access your sanctuary.');
      },
    );
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
        if (mounted) {
          await EmergencyKitDialog.show(context, email: email);
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
    final c = CardInk.of(context);
    final isEditorial = ref.watch(appSettingsProvider.select((s) => s.cardStyle)) == 'editorial';

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CardTabs(
          options: const ['Sign in', 'Create account'],
          selected: _isSignUp ? 'Create account' : 'Sign in',
          onSelected: (o) => setState(() {
            _isSignUp = o == 'Create account';
            _error = null;
            _notice = null;
          }),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Motion.silk,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: child),
          ),
          layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
          child: Column(
            key: ValueKey(_isSignUp),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isSignUp ? 'Make your account' : 'Welcome back', style: GoogleFonts.bodoniModa(fontSize: 27, fontWeight: FontWeight.bold, color: c.ink, height: 1.1)),
              const SizedBox(height: 4),
              Text(
                _isSignUp ? 'Your notes stay encrypted on this phone. An account adds backup and sync.' : 'Sign in to sync your notes, tasks and money across devices.',
                style: c.meta.copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // The name field opens and closes with the mode instead of popping in.
        AnimatedSize(
          duration: const Duration(milliseconds: 360),
          curve: Motion.silk,
          alignment: Alignment.topCenter,
          child: _isSignUp
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _field(c, controller: _nameCtrl, label: 'Your name', hint: 'What should we call you?', icon: LucideIcons.user),
                )
              : const SizedBox(width: double.infinity),
        ),
        _field(c, controller: _emailCtrl, label: 'Email', hint: 'you@example.com', icon: LucideIcons.mail, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(
          c,
          controller: _passCtrl,
          label: _isSignUp ? 'Choose a password' : 'Password',
          hint: '••••••••',
          icon: LucideIcons.lock,
          isPassword: true,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Motion.silk,
          child: _isSignUp && _strength != null ? _buildStrengthMeter(c, _strength!) : const SizedBox(width: double.infinity),
        ),
        if (!_isSignUp)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CardLink(label: 'Forgot password?', onTap: _busy ? () {} : _handleForgotPassword),
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Motion.silk,
          child: _error != null || _notice != null
              ? Padding(padding: const EdgeInsets.only(top: 10), child: _buildMessage(c, _error ?? _notice!, isError: _error != null))
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(c),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: c.hairline)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: c.meta)),
            Expanded(child: Container(height: 1, color: c.hairline)),
          ],
        ),
        const SizedBox(height: 18),
        _buildGoogleButton(c),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _continueWithoutAccount,
            style: TextButton.styleFrom(foregroundColor: c.muted),
            child: Text('Explore offline as guest', style: c.meta.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: c.dark ? const Color(0xFF000000) : AppColors.background,
      body: Stack(
        children: [
          // One soft oxblood glow behind the monogram, breathing slowly.
          if (!isEditorial)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _auraController,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.85),
                        radius: 0.9 + _auraController.value * 0.08,
                        colors: [c.fill.withValues(alpha: c.dark ? 0.22 : 0.07), c.fill.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const StitchMonogramNWidget(size: 44),
                          const SizedBox(height: 12),
                          Text('NOTtEodo', style: GoogleFonts.bodoniModa(fontSize: 32, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                          const SizedBox(height: 4),
                          Text('Notes, tasks, money and plans in one calm place', style: c.meta.copyWith(fontSize: 13.5), textAlign: TextAlign.center),
                        ],
                      ),
                      const SizedBox(height: 26),
                      isEditorial
                          ? form
                          : BentoPod(
                              style: PodTextureStyle.glass,
                              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                              child: form,
                            ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shieldCheck, size: 13, color: c.muted),
                          const SizedBox(width: 6),
                          Flexible(child: Text('Saved on your device. Synced only when you sign in.', style: c.meta.copyWith(fontSize: 12.5))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _footerLink(c, 'Terms & Conditions', const TermsConditionsSubpage()),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('·', style: c.meta)),
                          _footerLink(c, 'Privacy Policy', const PrivacySafetySubpage()),
                        ],
                      ),
                    ].revealed(),
                  ),
                ),
              ),
            ),
          ),

          // Bento / Editorial view switch, as quiet text in the corner.
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Semantics(
                label: 'Switch to ${isEditorial ? 'Bento' : 'Editorial'} view',
                button: true,
                excludeSemantics: true,
                child: Pressable(
                  pressedScale: 0.92,
                  hoverLift: 0,
                  onTap: () => toggleViewStyle(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ViewStyleGlyph(editorial: isEditorial, size: 17, color: c.mark),
                        const SizedBox(width: 6),
                        Text(isEditorial ? 'Editorial' : 'Bento', style: c.meta.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink)),
                      ],
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

  Widget _footerLink(CardInk c, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label, style: c.meta.copyWith(fontSize: 12.5, decoration: TextDecoration.underline, decorationColor: c.muted.withValues(alpha: 0.5))),
      ),
    );
  }

  /// A label above a soft filled field. The icon warms to oxblood while the field has focus.
  Widget _field(
    CardInk c, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: c.label),
        const SizedBox(height: 6),
        Focus(
          child: Builder(builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              keyboardType: keyboard,
              style: c.body.copyWith(fontSize: 15.5),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: AnimatedSwitcher(
                  duration: Motion.standard,
                  child: Icon(icon, key: ValueKey(focused), size: 18, color: focused ? c.mark : c.muted),
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 17, color: c.muted),
                      )
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Four segments that fill in oxblood as the password gets stronger.
  Widget _buildStrengthMeter(CardInk c, PasswordCheck check) {
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
                    duration: const Duration(milliseconds: 320),
                    curve: Motion.silk,
                    height: 3,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    decoration: BoxDecoration(color: i < check.score ? c.fill : c.track, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(check.problem ?? '${check.label} password', style: c.meta.copyWith(fontSize: 12.5, color: check.acceptable ? c.muted : c.mark)),
        ],
      ),
    );
  }

  Widget _buildMessage(CardInk c, String text, {required bool isError}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(isError ? LucideIcons.alertCircle : LucideIcons.checkCircle2, size: 15, color: isError ? c.mark : c.muted),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: c.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w400, color: isError ? c.mark : c.ink))),
      ],
    );
  }

  /// The one oxblood button. Its arrow slides forward when pressed; while busy it
  /// shows a small spinner instead.
  Widget _buildSubmitButton(CardInk c) {
    return Pressable(
      pressedScale: 0.97,
      hoverLift: 0,
      enabled: !_busy,
      onTap: _handleEmailSubmit,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(27),
          boxShadow: [BoxShadow(color: c.fill.withValues(alpha: c.dark ? 0.35 : 0.22), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: AnimatedSwitcher(
          duration: Motion.standard,
          child: _busy
              ? SizedBox(key: const ValueKey('busy'), width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.8, color: c.onFill))
              : Row(
                  key: ValueKey(_isSignUp),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'Create my account' : 'Sign in to NOTtEodo',
                      style: GoogleFonts.dmSans(fontSize: 15.5, fontWeight: FontWeight.w600, color: c.onFill),
                    ),
                    const SizedBox(width: 10),
                    Icon(LucideIcons.arrowRight, size: 17, color: c.onFill),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(CardInk c) {
    return Pressable(
      pressedScale: 0.97,
      hoverLift: 0,
      enabled: !_busy,
      onTap: _handleGoogleSignIn,
      child: Container(
        height: 52,
        decoration: BoxDecoration(color: c.dark ? const Color(0xFF161313) : const Color(0xFFF4EFE9), borderRadius: BorderRadius.circular(26)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              alignment: Alignment.center,
              child: Text('G', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black)),
            ),
            const SizedBox(width: 12),
            Text(_isSignUp ? 'Sign up with Google' : 'Continue with Google', style: c.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
