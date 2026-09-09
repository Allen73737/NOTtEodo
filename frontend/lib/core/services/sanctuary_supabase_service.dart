import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/sanctuary_state.dart';

/// Production-Grade Hardened Cloud Synchronization & Authentication Service
class SanctuarySupabaseService {
  static final SanctuarySupabaseService _instance = SanctuarySupabaseService._internal();
  factory SanctuarySupabaseService() => _instance;
  SanctuarySupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

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
    final url = supabaseUrl.isNotEmpty ? supabaseUrl : const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final anonKey = supabaseAnonKey.isNotEmpty ? supabaseAnonKey : const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    if (url.isNotEmpty && anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
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
      await logSecurityEvent('USER_SIGNED_IN', {'email': email});
      return res;
    } catch (e) {
      await logSecurityEvent('LOGIN_FAILED', {'email': email, 'error': e.toString()}, severity: 'WARNING');
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
      await logSecurityEvent('USER_REGISTERED', {'email': email});
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
  // Notes Synchronization (RLS Protected)
  // ============================================================================

  Future<List<NoteItem>?> fetchNotesCloud() async {
    if (!isConnectedToCloud) return null;
    try {
      final data = await _client!.from('notes').select().order('created_at', ascending: false);
      return (data as List).map((row) => NoteItem(
        id: row['id'],
        title: row['title'] ?? 'Untitled Note',
        space: row['space_label'] ?? 'General Space',
        tag: row['tag'] ?? 'Note',
        date: row['created_at'] != null ? row['created_at'].toString().substring(0, 10) : 'Today',
        excerpt: row['excerpt'] ?? (row['content'] ?? ''),
        isPinned: row['is_pinned'] ?? false,
      )).toList();
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Notes fetch error: $e');
      return null;
    }
  }

  Future<void> insertNoteCloud(NoteItem note) async {
    if (!isConnectedToCloud) return;
    try {
      await _client!.from('notes').insert({
        'title': note.title,
        'tag': note.tag,
        'excerpt': note.excerpt,
        'is_pinned': note.isPinned,
      });
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Note insert error: $e');
    }
  }

  Future<void> deleteNoteCloud(String noteId) async {
    if (!isConnectedToCloud) return;
    try {
      await _client!.from('notes').delete().eq('id', noteId);
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Note delete error: $e');
    }
  }

  // ============================================================================
  // Tasks Synchronization (RLS Protected)
  // ============================================================================

  Future<List<TaskItem>?> fetchTasksCloud() async {
    if (!isConnectedToCloud) return null;
    try {
      final data = await _client!.from('tasks').select().order('created_at', ascending: false);
      return (data as List).map((row) => TaskItem(
        id: row['id'],
        title: row['title'] ?? 'Priority',
        priority: row['priority'] ?? 'High',
        space: row['space_label'] ?? 'General Space',
        timeOfDay: row['time_slot'] ?? 'Morning',
        completed: row['is_completed'] ?? false,
      )).toList();
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Tasks fetch error: $e');
      return null;
    }
  }

  Future<void> insertTaskCloud(TaskItem task) async {
    if (!isConnectedToCloud) return;
    try {
      await _client!.from('tasks').insert({
        'title': task.title,
        'priority': task.priority,
        'space_label': task.space,
        'time_slot': task.timeOfDay,
        'is_completed': task.completed,
      });
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Task insert error: $e');
    }
  }

  Future<void> toggleTaskCloud(String taskId, bool isCompleted) async {
    if (!isConnectedToCloud) return;
    try {
      await _client!.from('tasks').update({
        'is_completed': isCompleted,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      }).eq('id', taskId);
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Task toggle error: $e');
    }
  }

  // ============================================================================
  // Expenses Synchronization (RLS Protected)
  // ============================================================================

  Future<void> insertExpenseCloud(ExpenseItem expense) async {
    if (!isConnectedToCloud) return;
    try {
      await _client!.from('expenses').insert({
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
      });
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Expense insert error: $e');
    }
  }

  // ============================================================================
  // Universal Search via Server Function
  // ============================================================================

  Future<List<Map<String, dynamic>>?> searchUniversalCloud(String query) async {
    if (!isConnectedToCloud) return null;
    try {
      final res = await _client!.rpc('search_sanctuary_universal', params: {
        'search_query': query,
        'max_results': 20,
      });
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[SanctuarySupabaseService] Server search error: $e');
      return null;
    }
  }
}
