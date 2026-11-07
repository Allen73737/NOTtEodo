import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_feedback_item.dart';
import 'local_store.dart';
import 'sanctuary_supabase_service.dart';

class FeedbackNotifier extends StateNotifier<List<UserFeedbackItem>> {
  static const String _storageKey = 'user_feedback_submissions';

  FeedbackNotifier() : super([]) {
    _loadFeedback();
  }

  void _loadFeedback() {
    try {
      final stored = LocalStore().readList<UserFeedbackItem>(
        _storageKey,
        (json) => UserFeedbackItem.fromJson(json),
      );

      if (stored != null && stored.isNotEmpty) {
        state = stored;
      } else {
        // Initial curated seed submissions so admin dashboard has immediate diagnostic clarity
        final seedData = _getCuratedSeedFeedback();
        state = seedData;
        _saveToStorage(seedData);
      }

      // If connected to cloud, attempt background fetch
      _syncFromCloud();
    } catch (e) {
      debugPrint('[FeedbackService] Error loading feedback: $e');
    }
  }

  List<UserFeedbackItem> _getCuratedSeedFeedback() {
    final now = DateTime.now();
    return [
      UserFeedbackItem(
        id: 'seed-feedback-01',
        type: 'feature_suggestion',
        title: 'Smart recurring habits by time of day slotting',
        description:
            'It would be wonderful if habits could be grouped automatically into Morning, Afternoon, and Evening slots similar to how tasks are categorized, with smart prompts from the companion.',
        impact: 'important',
        category: 'Habits & Routine',
        userIdentifier: 'Curator Genevieve',
        userEmail: 'genevieve.c@sanctuary.internal',
        submittedAt: now.subtract(const Duration(hours: 3, minutes: 20)),
        status: 'planned',
        adminNotes: 'Scheduled for Next Minor Release with AI Morning Digest integration.',
        deviceInfo: 'Android 16 · Mobile',
      ),
      UserFeedbackItem(
        id: 'seed-feedback-02',
        type: 'feature_suggestion',
        title: 'WearOS watch tile and quick complications for note recording',
        description:
            'A WearOS smartwatch companion tile allowing one-tap voice note capture straight into the encrypted vault without opening the phone.',
        impact: 'critical',
        category: 'Audio & Hardware',
        userIdentifier: 'Executive Voyager',
        userEmail: 'marcus.v@sovereign.org',
        submittedAt: now.subtract(const Duration(hours: 14)),
        status: 'reviewed',
        adminNotes: 'Architectural evaluation in progress under BLE Companion service.',
        deviceInfo: 'WearOS 5.0 / Android 16',
      ),
      UserFeedbackItem(
        id: 'seed-feedback-03',
        type: 'general_feedback',
        title: 'Focus timer loop soundtrack quality is magnificent',
        description:
            'The rainfall and hearth soundscape loops during focus sessions have drastically improved my deep work productivity. Would love an option to blend two sounds together.',
        impact: 'nice_to_have',
        category: 'Focus & Audio',
        userIdentifier: 'Anonymous Curator',
        submittedAt: now.subtract(const Duration(days: 1, hours: 2)),
        status: 'pending',
        deviceInfo: 'Android 16 · Tablet',
      ),
      UserFeedbackItem(
        id: 'seed-feedback-04',
        type: 'ui_enhancement',
        title: 'Bento card micro-haptic feedback intensity customization',
        description:
            'Provide a soft / crisp / disabled selector for the mechanical gear tick haptics across the dashboard cards.',
        impact: 'nice_to_have',
        category: 'Design & UI',
        userIdentifier: 'Curator Kaelen',
        userEmail: 'kaelen.design@sanctuary.internal',
        submittedAt: now.subtract(const Duration(days: 2, hours: 5)),
        status: 'resolved',
        adminNotes: 'Integrated into Settings > Haptic & Vibration Profile.',
        deviceInfo: 'Android 16 · Mobile',
      ),
    ];
  }

  void _saveToStorage(List<UserFeedbackItem> items) {
    try {
      LocalStore().writeList(
        _storageKey,
        items.map((item) => item.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('[FeedbackService] Save error: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final client = SanctuarySupabaseService().client;
      if (client == null) return;

      final res = await client
          .from('user_feedback')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (res.isNotEmpty) {
        final cloudItems = res
            .map((r) => UserFeedbackItem.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();

        // Merge: keep local items not yet in cloud, and cloud items
        final Map<String, UserFeedbackItem> merged = {};
        for (final item in cloudItems) {
          merged[item.id] = item;
        }
        for (final local in state) {
          if (!merged.containsKey(local.id)) {
            merged[local.id] = local;
          }
        }

        final combined = merged.values.toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        state = combined;
        _saveToStorage(combined);
      }
    } catch (e) {
      debugPrint('[FeedbackService] Cloud sync note (running offline): $e');
    }
  }

  /// Submits new user feedback or feature suggestion
  Future<UserFeedbackItem> submitFeedback({
    required String type,
    required String title,
    required String description,
    required String impact,
    required String category,
    required String userIdentifier,
    String? userEmail,
  }) async {
    final deviceDesc = kIsWeb
        ? 'Web Application'
        : (Platform.isAndroid ? 'Android 16 · Mobile' : (Platform.isIOS ? 'iOS · Mobile' : 'Desktop OS'));

    final newItem = UserFeedbackItem(
      id: 'fb-${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecond % 9000))}',
      type: type,
      title: title.trim(),
      description: description.trim(),
      impact: impact,
      category: category,
      userIdentifier: userIdentifier.trim().isEmpty ? 'Sanctuary Curator' : userIdentifier.trim(),
      userEmail: userEmail?.trim().isEmpty == true ? null : userEmail?.trim(),
      submittedAt: DateTime.now(),
      status: 'pending',
      deviceInfo: deviceDesc,
    );

    final updated = [newItem, ...state];
    state = updated;
    _saveToStorage(updated);

    // Asynchronously push to Supabase if connected
    _pushToCloud(newItem);

    return newItem;
  }

  Future<void> _pushToCloud(UserFeedbackItem item) async {
    try {
      final client = SanctuarySupabaseService().client;
      if (client != null) {
        await client.from('user_feedback').insert({
          'type': item.type,
          'title': item.title,
          'description': item.description,
          'impact': item.impact,
          'category': item.category,
          'user_identifier': item.userIdentifier,
          'user_email': item.userEmail,
          'status': item.status,
          'device_info': item.deviceInfo,
        });
      }
    } catch (e) {
      debugPrint('[FeedbackService] Supabase upload background note: $e');
    }
  }

  /// Admin updates status or notes
  Future<void> updateFeedbackStatus(
    String id,
    String newStatus, {
    String? adminNotes,
  }) async {
    final updated = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          status: newStatus,
          adminNotes: adminNotes ?? item.adminNotes,
        );
      }
      return item;
    }).toList();

    state = updated;
    _saveToStorage(updated);

    // Sync status to cloud
    try {
      final client = SanctuarySupabaseService().client;
      if (client != null) {
        await client.from('user_feedback').update({
          'status': newStatus,
          if (adminNotes != null) 'admin_notes': adminNotes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id);
      }
    } catch (e) {
      debugPrint('[FeedbackService] Cloud status update note: $e');
    }
  }

  /// Admin deletes feedback
  Future<void> deleteFeedback(String id) async {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    _saveToStorage(updated);

    try {
      final client = SanctuarySupabaseService().client;
      if (client != null) {
        await client.from('user_feedback').delete().eq('id', id);
      }
    } catch (e) {
      debugPrint('[FeedbackService] Cloud delete note: $e');
    }
  }
}

final feedbackListProvider =
    StateNotifierProvider<FeedbackNotifier, List<UserFeedbackItem>>((ref) {
  return FeedbackNotifier();
});
