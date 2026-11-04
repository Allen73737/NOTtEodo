import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../services/local_store.dart';
import 'aesthetic_widget_models.dart';

/// Fast snapshots for sub-millisecond widget rendering and homescreen sync.

class WidgetNoteSnapshot {
  final String title;
  final String content;
  final String tag;
  final DateTime updatedAt;

  const WidgetNoteSnapshot({
    required this.title,
    required this.content,
    required this.tag,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'content': content,
        'tag': tag,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WidgetNoteSnapshot.fromMap(Map<String, dynamic> map) => WidgetNoteSnapshot(
        title: map['title'] as String? ?? 'Quiet Architecture',
        content: map['content'] as String? ?? 'Simplicity is the keynote of all true elegance.',
        tag: map['tag'] as String? ?? 'ESSAY',
        updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class WidgetTaskItem {
  final String title;
  final bool isCompleted;
  final String priority;

  const WidgetTaskItem({
    required this.title,
    required this.isCompleted,
    this.priority = 'normal',
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'isCompleted': isCompleted,
        'priority': priority,
      };

  factory WidgetTaskItem.fromMap(Map<String, dynamic> map) => WidgetTaskItem(
        title: map['title'] as String? ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        priority: map['priority'] as String? ?? 'normal',
      );
}

class WidgetRitualsSnapshot {
  final List<WidgetTaskItem> topTasks;
  final int habitsCompletedToday;
  final int totalHabits;
  final int streakDays;

  const WidgetRitualsSnapshot({
    required this.topTasks,
    required this.habitsCompletedToday,
    required this.totalHabits,
    required this.streakDays,
  });

  Map<String, dynamic> toMap() => {
        'topTasks': topTasks.map((t) => t.toMap()).toList(),
        'habitsCompletedToday': habitsCompletedToday,
        'totalHabits': totalHabits,
        'streakDays': streakDays,
      };

  factory WidgetRitualsSnapshot.fromMap(Map<String, dynamic> map) => WidgetRitualsSnapshot(
        topTasks: (map['topTasks'] as List?)
                ?.map((t) => WidgetTaskItem.fromMap(Map<String, dynamic>.from(t as Map)))
                .toList() ??
            const [
              WidgetTaskItem(title: 'Morning pour-over brew', isCompleted: true),
              WidgetTaskItem(title: 'Read 20 pages of architecture essay', isCompleted: false),
              WidgetTaskItem(title: 'Sunset reflection & journal entry', isCompleted: false),
            ],
        habitsCompletedToday: map['habitsCompletedToday'] as int? ?? 4,
        totalHabits: map['totalHabits'] as int? ?? 5,
        streakDays: map['streakDays'] as int? ?? 14,
      );
}

class WidgetMoodboardSnapshot {
  final String title;
  final String caption;
  final String tag;

  const WidgetMoodboardSnapshot({
    required this.title,
    required this.caption,
    required this.tag,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'caption': caption,
        'tag': tag,
      };

  factory WidgetMoodboardSnapshot.fromMap(Map<String, dynamic> map) => WidgetMoodboardSnapshot(
        title: map['title'] as String? ?? 'Warm Linen & Oak Studio',
        caption: map['caption'] as String? ?? 'Organic textures, diffused afternoon skylight.',
        tag: map['tag'] as String? ?? 'AESTHETIC',
      );
}

class WidgetWardrobeSnapshot {
  final String title;
  final String occasion;
  final String vibe;

  const WidgetWardrobeSnapshot({
    required this.title,
    required this.occasion,
    required this.vibe,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'occasion': occasion,
        'vibe': vibe,
      };

  factory WidgetWardrobeSnapshot.fromMap(Map<String, dynamic> map) => WidgetWardrobeSnapshot(
        title: map['title'] as String? ?? 'Tokyo Autumn Minimalist',
        occasion: map['occasion'] as String? ?? 'Atelier Review',
        vibe: map['vibe'] as String? ?? 'Cashmere Overcoat · Pleated Trousers',
      );
}

class WidgetTreasurySnapshot {
  final double monthlySpent;
  final double monthlyBudget;
  final String currency;
  final String latestMerchant;
  final double latestAmount;

  const WidgetTreasurySnapshot({
    required this.monthlySpent,
    required this.monthlyBudget,
    required this.currency,
    required this.latestMerchant,
    required this.latestAmount,
  });

  Map<String, dynamic> toMap() => {
        'monthlySpent': monthlySpent,
        'monthlyBudget': monthlyBudget,
        'currency': currency,
        'latestMerchant': latestMerchant,
        'latestAmount': latestAmount,
      };

  factory WidgetTreasurySnapshot.fromMap(Map<String, dynamic> map) => WidgetTreasurySnapshot(
        monthlySpent: (map['monthlySpent'] as num?)?.toDouble() ?? 1420.0,
        monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 2800.0,
        currency: map['currency'] as String? ?? '\$',
        latestMerchant: map['latestMerchant'] as String? ?? 'Kinfolk Gallery & Bookshop',
        latestAmount: (map['latestAmount'] as num?)?.toDouble() ?? 64.50,
      );
}

class WidgetVoiceMemoirSnapshot {
  final String title;
  final String duration;
  final DateTime recordedAt;

  const WidgetVoiceMemoirSnapshot({
    required this.title,
    required this.duration,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'duration': duration,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory WidgetVoiceMemoirSnapshot.fromMap(Map<String, dynamic> map) => WidgetVoiceMemoirSnapshot(
        title: map['title'] as String? ?? 'Rain in Kyoto · Courtyard Memoir',
        duration: map['duration'] as String? ?? '03:42',
        recordedAt: DateTime.tryParse(map['recordedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class WidgetTravelSnapshot {
  final String destination;
  final String status;
  final String countdown;

  const WidgetTravelSnapshot({
    required this.destination,
    required this.status,
    required this.countdown,
  });

  Map<String, dynamic> toMap() => {
        'destination': destination,
        'status': status,
        'countdown': countdown,
      };

  factory WidgetTravelSnapshot.fromMap(Map<String, dynamic> map) => WidgetTravelSnapshot(
        destination: map['destination'] as String? ?? 'Kyoto, Japan',
        status: map['status'] as String? ?? 'CONFIRMED PASS',
        countdown: map['countdown'] as String? ?? 'In 18 days',
      );
}

class WidgetHorologySnapshot {
  final String quote;
  final String author;
  final String focusSession;

  const WidgetHorologySnapshot({
    required this.quote,
    required this.author,
    required this.focusSession,
  });

  Map<String, dynamic> toMap() => {
        'quote': quote,
        'author': author,
        'focusSession': focusSession,
      };

  factory WidgetHorologySnapshot.fromMap(Map<String, dynamic> map) => WidgetHorologySnapshot(
        quote: map['quote'] as String? ?? 'Time is the substance from which I am made.',
        author: map['author'] as String? ?? 'Jorge Luis Borges',
        focusSession: map['focusSession'] as String? ?? '45m Deep Architecture Flow',
      );
}

/// Central high-speed cache manager for homescreen widgets and user preferences.
class HomescreenFastDataCache {
  static final HomescreenFastDataCache _instance = HomescreenFastDataCache._internal();
  factory HomescreenFastDataCache() => _instance;
  HomescreenFastDataCache._internal();

  static const String _storageSlot = 'nt_homescreen_fast_cache';
  static const String _prefsSlot = 'nt_homescreen_user_preferences';

  WidgetNoteSnapshot? note;
  WidgetRitualsSnapshot? rituals;
  WidgetMoodboardSnapshot? moodboard;
  WidgetWardrobeSnapshot? wardrobe;
  WidgetTreasurySnapshot? treasury;
  WidgetVoiceMemoirSnapshot? voice;
  WidgetTravelSnapshot? travel;
  WidgetHorologySnapshot? horology;

  Map<String, dynamic> _userPreferences = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Loads cached snapshots and user preferences immediately from LocalStore.
  void init() {
    if (_initialized) return;
    _initialized = true;
    loadFromStore();
  }

  void loadFromStore() {
    try {
      final publicData = LocalStore().readPublic();
      if (publicData.containsKey(_storageSlot)) {
        final cacheMap = Map<String, dynamic>.from(publicData[_storageSlot] as Map? ?? {});
        _applyMap(cacheMap);
      }
      if (publicData.containsKey(_prefsSlot)) {
        _userPreferences = Map<String, dynamic>.from(publicData[_prefsSlot] as Map? ?? {});
      }
    } catch (e) {
      debugPrint('[HomescreenFastDataCache] Error loading cache: $e');
    }
  }

  void _applyMap(Map<String, dynamic> map) {
    if (map['note'] is Map) note = WidgetNoteSnapshot.fromMap(Map<String, dynamic>.from(map['note'] as Map));
    if (map['rituals'] is Map) rituals = WidgetRitualsSnapshot.fromMap(Map<String, dynamic>.from(map['rituals'] as Map));
    if (map['moodboard'] is Map) moodboard = WidgetMoodboardSnapshot.fromMap(Map<String, dynamic>.from(map['moodboard'] as Map));
    if (map['wardrobe'] is Map) wardrobe = WidgetWardrobeSnapshot.fromMap(Map<String, dynamic>.from(map['wardrobe'] as Map));
    if (map['treasury'] is Map) treasury = WidgetTreasurySnapshot.fromMap(Map<String, dynamic>.from(map['treasury'] as Map));
    if (map['voice'] is Map) voice = WidgetVoiceMemoirSnapshot.fromMap(Map<String, dynamic>.from(map['voice'] as Map));
    if (map['travel'] is Map) travel = WidgetTravelSnapshot.fromMap(Map<String, dynamic>.from(map['travel'] as Map));
    if (map['horology'] is Map) horology = WidgetHorologySnapshot.fromMap(Map<String, dynamic>.from(map['horology'] as Map));
  }

  /// Persists the cached data snapshots.
  void saveToStore() {
    try {
      final publicData = LocalStore().readPublic();
      publicData[_storageSlot] = {
        if (note != null) 'note': note!.toMap(),
        if (rituals != null) 'rituals': rituals!.toMap(),
        if (moodboard != null) 'moodboard': moodboard!.toMap(),
        if (wardrobe != null) 'wardrobe': wardrobe!.toMap(),
        if (treasury != null) 'treasury': treasury!.toMap(),
        if (voice != null) 'voice': voice!.toMap(),
        if (travel != null) 'travel': travel!.toMap(),
        if (horology != null) 'horology': horology!.toMap(),
      };
      LocalStore().writePublic(publicData);
    } catch (e) {
      debugPrint('[HomescreenFastDataCache] Error saving cache: $e');
    }
  }

  /// Saves user preferences for Widget Studio (previously used type, theme, size, tape, etc.).
  void savePreferences({
    AestheticWidgetType? selectedType,
    AestheticPaperTheme? selectedTheme,
    WashiTapeStyle? selectedTape,
    WidgetGridSize? selectedSize,
    bool? showStamp,
    String? stampLabel,
    bool? autoMatchTheme,
  }) {
    if (selectedType != null) _userPreferences['selectedType'] = selectedType.name;
    if (selectedTheme != null) _userPreferences['selectedTheme'] = selectedTheme.name;
    if (selectedTape != null) _userPreferences['selectedTape'] = selectedTape.name;
    if (selectedSize != null) _userPreferences['selectedSize'] = selectedSize.name;
    if (showStamp != null) _userPreferences['showStamp'] = showStamp;
    if (stampLabel != null) _userPreferences['stampLabel'] = stampLabel;
    if (autoMatchTheme != null) _userPreferences['autoMatchTheme'] = autoMatchTheme;

    try {
      final publicData = LocalStore().readPublic();
      publicData[_prefsSlot] = _userPreferences;
      LocalStore().writePublic(publicData);
    } catch (e) {
      debugPrint('[HomescreenFastDataCache] Error saving preferences: $e');
    }
  }

  Map<String, dynamic> getPreferences() => Map.unmodifiable(_userPreferences);

  AestheticWidgetType get savedType => AestheticWidgetType.values.firstWhere(
        (e) => e.name == _userPreferences['selectedType'],
        orElse: () => AestheticWidgetType.stickyNote,
      );

  AestheticPaperTheme get savedTheme => AestheticPaperTheme.values.firstWhere(
        (e) => e.name == _userPreferences['selectedTheme'],
        orElse: () => AestheticPaperTheme.warmCream,
      );

  WashiTapeStyle get savedTape => WashiTapeStyle.values.firstWhere(
        (e) => e.name == _userPreferences['selectedTape'],
        orElse: () => WashiTapeStyle.terracotta,
      );

  WidgetGridSize get savedSize => WidgetGridSize.values.firstWhere(
        (e) => e.name == _userPreferences['selectedSize'],
        orElse: () => WidgetGridSize.compact,
      );

  bool get savedShowStamp => _userPreferences['showStamp'] as bool? ?? true;
  String get savedStampLabel => _userPreferences['stampLabel'] as String? ?? 'CURATED';
  bool get savedAutoMatchTheme => _userPreferences['autoMatchTheme'] as bool? ?? true;

  /// Syncs essential widget strings to HomeWidget native storage for Android/iOS widgets.
  Future<void> syncToHomeWidget() async {
    if (kIsWeb) return;
    try {
      if (note != null) {
        await HomeWidget.saveWidgetData<String>('note_title', note!.title);
        await HomeWidget.saveWidgetData<String>('note_content', note!.content);
        await HomeWidget.saveWidgetData<String>('note_tag', note!.tag);
      }
      if (rituals != null) {
        await HomeWidget.saveWidgetData<int>('habits_completed', rituals!.habitsCompletedToday);
        await HomeWidget.saveWidgetData<int>('habits_total', rituals!.totalHabits);
        await HomeWidget.saveWidgetData<int>('habits_streak', rituals!.streakDays);
        if (rituals!.topTasks.isNotEmpty) {
          await HomeWidget.saveWidgetData<String>('task_1_title', rituals!.topTasks[0].title);
          await HomeWidget.saveWidgetData<bool>('task_1_done', rituals!.topTasks[0].isCompleted);
        }
      }
      if (treasury != null) {
        await HomeWidget.saveWidgetData<String>(
          'treasury_summary',
          '${treasury!.currency}${treasury!.monthlySpent.toStringAsFixed(0)} / ${treasury!.currency}${treasury!.monthlyBudget.toStringAsFixed(0)}',
        );
      }
    } catch (_) {}
  }
}

