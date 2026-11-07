import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../security/secure_session_storage.dart';

/// Production-Grade Hardened Cloud Synchronization & Authentication Service
class SanctuarySupabaseService {
  static final SanctuarySupabaseService _instance = SanctuarySupabaseService._internal();
  factory SanctuarySupabaseService() => _instance;
  SanctuarySupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseClient? get client => _client;
  bool get isInitialized => _isInitialized;
  bool get isConnectedToCloud => _isInitialized && _client != null && _client!.auth.currentUser != null;
  User? get currentUser => _client?.auth.currentUser;

  /// Initialize Supabase with secure fallback
  Future<void> initialize({
    String supabaseUrl = '',
    String supabaseAnonKey = '',
  }) async {
    if (_isInitialized) return;

    // Use passed URL/Key or defaults
    final url = supabaseUrl.isNotEmpty ? supabaseUrl : const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://zjmxwttdkvhiuampirwa.supabase.co');
    final anonKey = supabaseAnonKey.isNotEmpty ? supabaseAnonKey : const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_5HFXNaUjrzusoPYEtdtAQw_taum_OxL');

    if (url.isNotEmpty && anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
          authOptions: kIsWeb
              ? const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce)
              : const FlutterAuthClientOptions(
                  authFlowType: AuthFlowType.pkce,
                  localStorage: SecureSessionStorage(),
                  pkceAsyncStorage: SecurePkceStorage(),
                ),
        );
        _client = Supabase.instance.client;
        _isInitialized = true;
        debugPrint('[SanctuarySupabaseService] Cloud connection established.');
      } catch (e) {
        debugPrint('[SanctuarySupabaseService] Supabase init warning: $e. Operating in secure offline mode.');
        _isInitialized = false;
      }
    } else {
      debugPrint('[SanctuarySupabaseService] Cloud credentials not configured. Operating in high-speed local offline mode.');
      _isInitialized = false;
    }
  }

  // ============================================================================
  // Authentication & Session Security
  // ============================================================================

  Future<AuthResponse?> signIn({required String email, required String password}) async {
    if (!_isInitialized || _client == null) return null;
    try {
      final res = await _client!.auth.signInWithPassword(email: email, password: password);
      await logSecurityEvent('USER_SIGNED_IN', {'method': 'password'});
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse?> signUp({required String email, required String password, String? displayName}) async {
    if (!_isInitialized || _client == null) return null;
    try {
      final res = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName ?? 'Sanctuary Voyager'},
      );
      await logSecurityEvent('USER_REGISTERED', {'method': 'password'});
      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized || _client == null) return;
    try {
      await logSecurityEvent('USER_SIGNED_OUT', {});
      await _client!.auth.signOut();
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Sign out error: $e');
    }
  }

  // ============================================================================
  // Audit Logging
  // ============================================================================

  Future<void> logSecurityEvent(String eventType, Map<String, dynamic> metadata, {String severity = 'INFO'}) async {
    if (!_isInitialized || _client == null || _client!.auth.currentUser == null) return;
    try {
      await _client!.rpc('log_security_event', params: {
        'p_event_type': eventType,
        'p_severity': severity,
        'p_metadata': metadata,
      });
    } catch (e) {
      debugPrint('[SanctuarySecurity] Audit log recording notice: $e');
    }
  }


  // ============================================================================
  // Account Recovery & Session
  // ============================================================================

  Future<void> sendPasswordReset(String email) async {
    if (!_isInitialized || _client == null) {
      throw StateError('Cloud account is not configured for this build.');
    }
    await _client!.auth.resetPasswordForEmail(email);
  }

  /// Starts Google OAuth. On web the browser leaves the app and comes back signed in.
  Future<void> signInWithGoogle() async {
    if (!_isInitialized || _client == null) {
      throw StateError('Cloud account is not configured for this build.');
    }
    final redirectUrl = kIsWeb ? Uri.base.origin : 'io.supabase.notteodo://login-callback';
    await _client!.auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirectUrl);
  }

  /// Fires on sign-in, sign-out and token refresh.
  Stream<AuthState>? get authChanges => _client?.auth.onAuthStateChange;

  // ============================================================================
  // Collection Snapshot Sync (RLS: one row per user + collection)
  // ============================================================================

  /// The signed-in user's collection snapshots, only those changed after [since]
  /// when given (delta sync: an index range scan on (user_id, updated_at)).
  Future<List<Map<String, dynamic>>> pullCollections({DateTime? since}) async {
    if (!isConnectedToCloud) return const [];
    var query = _client!
        .from('user_collections')
        .select('collection, data, updated_at')
        .eq('user_id', _client!.auth.currentUser!.id);
    if (since != null) query = query.gt('updated_at', since.toUtc().toIso8601String());
    final rows = await query;
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> pushCollection(String collection, Object data, DateTime updatedAt) async {
    if (!isConnectedToCloud) return;
    await _client!.from('user_collections').upsert({
      'user_id': _client!.auth.currentUser!.id,
      'collection': collection,
      'data': data,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    }, onConflict: 'user_id,collection');
  }

  // ============================================================================
  // End-to-end encryption key record (RLS: owner only; holds only a wrapped key)
  // ============================================================================

  Future<Map<String, dynamic>?> fetchUserKey() async {
    if (!isConnectedToCloud) return null;
    final row = await _client!
        .from('user_keys')
        .select('kdf, wrapped_key, key_check')
        .eq('user_id', _client!.auth.currentUser!.id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> upsertUserKey(Map<String, dynamic> record) async {
    if (!isConnectedToCloud) throw StateError('Sign in first.');
    await _client!.from('user_keys').upsert({
      'user_id': _client!.auth.currentUser!.id,
      ...record,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
    await logSecurityEvent('E2EE_KEY_UPDATED', {});
  }

  Future<void> deleteUserKey() async {
    if (!isConnectedToCloud) throw StateError('Sign in first.');
    await _client!.from('user_keys').delete().eq('user_id', _client!.auth.currentUser!.id);
    await logSecurityEvent('E2EE_DISABLED', {}, severity: 'WARNING');
  }

  // ============================================================================
  // Two-step verification (TOTP)
  // ============================================================================

  /// True when the account has a verified authenticator but this session has not used it yet.
  Future<bool> needsMfaStepUp() async {
    if (!isConnectedToCloud) return false;
    try {
      final aal = _client!.auth.mfa.getAuthenticatorAssuranceLevel();
      return aal.nextLevel == AuthenticatorAssuranceLevels.aal2 && aal.currentLevel != AuthenticatorAssuranceLevels.aal2;
    } catch (_) {
      return false;
    }
  }

  /// Verified TOTP factors on the account.
  Future<List<Factor>> totpFactors() async {
    if (!isConnectedToCloud) return const [];
    final res = await _client!.auth.mfa.listFactors();
    return res.totp;
  }

  /// Starts enrolment; show the returned URI as a QR code and ask for the first code.
  Future<({String factorId, String uri, String secret})> enrollTotp() async {
    if (!isConnectedToCloud) throw StateError('Sign in first.');
    // Clear abandoned, never-verified enrolments so a retry does not fail on a duplicate name.
    final user = _client!.auth.currentUser;
    for (final f in user?.factors ?? const <Factor>[]) {
      if (f.status == FactorStatus.unverified) {
        try {
          await _client!.auth.mfa.unenroll(f.id);
        } catch (_) {}
      }
    }
    final res = await _client!.auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: 'NOTtEodo',
      friendlyName: 'Authenticator ${DateTime.now().millisecondsSinceEpoch}',
    );
    final totp = res.totp!;
    return (factorId: res.id, uri: totp.uri, secret: totp.secret);
  }

  /// Confirms a 6-digit code for [factorId] (enrolment or sign-in step-up).
  Future<void> verifyTotp(String factorId, String code) async {
    await _client!.auth.mfa.challengeAndVerify(factorId: factorId, code: code.trim());
    await logSecurityEvent('MFA_VERIFIED', {});
  }

  Future<void> removeTotp(String factorId) async {
    await _client!.auth.mfa.unenroll(factorId);
    await logSecurityEvent('MFA_REMOVED', {}, severity: 'WARNING');
  }

  // ============================================================================
  // Scoped AI (Edge Function: scoped-ai)
  // ============================================================================

  /// Calls an edge function as the signed-in user. Throws [StateError] with the
  /// server's error code/message on failure.
  Future<Map<String, dynamic>> invokeFunction(String name, Map<String, dynamic> body) async {
    if (!isConnectedToCloud) throw StateError('Sign in to use this feature.');
    try {
      final res = await _client!.functions.invoke(name, body: body);
      return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    } on FunctionException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : const <String, dynamic>{};
      throw StateError('${details['code'] ?? e.status}: ${details['error'] ?? 'request failed'}');
    }
  }

  /// Asks the server-side model. [context] is a short digest of the user's own items.
  Future<({String answer, String citation})> askAi({
    required String query,
    required String scope,
    String context = '',
  }) async {
    if (!isConnectedToCloud) {
      throw StateError('Sign in to a cloud account to use the AI assistant.');
    }
    final res = await _client!.functions.invoke('scoped-ai', body: {
      'query': query,
      'scope': scope,
      'context': context,
    });
    final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    if (res.status != 200 || data['answer'] == null) {
      throw StateError(data['error']?.toString() ?? 'The assistant is unavailable right now.');
    }
    return (answer: data['answer'].toString(), citation: data['citation']?.toString() ?? scope);
  }
}
