import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_settings.dart';
import 'local_store.dart';

/// Persistent long-term memory engine for AI Companion "Nodo".
///
/// Stores learned user facts, preferences, goals, and multi-turn conversation history
/// in on-device encrypted storage so Nodo genuinely remembers the user across sessions.
class CompanionMemoryService {
  static final CompanionMemoryService _instance = CompanionMemoryService._internal();
  factory CompanionMemoryService() => _instance;
  CompanionMemoryService._internal();

  static const String _memoriesKey = 'companion_memories';
  static const String _historyKey = 'companion_chat_history';

  /// List of persistent memories learned about the user
  List<String> get memories {
    final raw = LocalStore().readMap(_memoriesKey);
    if (raw == null || raw['facts'] is! List) return [];
    return (raw['facts'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }

  void saveMemories(List<String> list) {
    LocalStore().writeMap(_memoriesKey, {'facts': list});
  }

  void addMemory(String fact) {
    final clean = fact.trim();
    if (clean.isEmpty) return;
    final current = memories;
    if (!current.any((m) => m.toLowerCase() == clean.toLowerCase())) {
      final updated = [...current, clean];
      saveMemories(updated);
    }
  }

  void removeMemory(int index) {
    final current = memories;
    if (index >= 0 && index < current.length) {
      final updated = List<String>.from(current)..removeAt(index);
      saveMemories(updated);
    }
  }

  void clearMemories() {
    LocalStore().removeKey(_memoriesKey);
  }

  /// Extracts user identity, names, preferences, and explicit "remember that" instructions
  /// from the user's message in real time, updating memory and profile settings.
  String? extractAndLearnFromMessage(String message, WidgetRef ref) {
    final text = message.trim();
    if (text.isEmpty) return null;

    String? learnedFact;

    // 1. Name statements: "My name is Allen", "Call me Allen", "I am Allen", "I'm Allen"
    final nameRegex = RegExp(
      r'''\b(?:my name is|call me|i am called|you can call me|i am|i'm)\s+([A-Z][a-zA-Z\s]{1,24})\b''',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(text);
    if (nameMatch != null) {
      final extracted = nameMatch.group(1)?.trim();
      // Filter out non-names like "happy", "tired", "fine", "busy"
      final nonNames = {'tired', 'happy', 'sad', 'busy', 'here', 'back', 'done', 'fine', 'good', 'okay', 'ready', 'curator', 'user'};
      if (extracted != null && extracted.isNotEmpty && !nonNames.contains(extracted.toLowerCase())) {
        final properName = extracted[0].toUpperCase() + extracted.substring(1);
        ref.read(appSettingsProvider.notifier).setDisplayName(properName);
        addMemory("User's name is $properName.");
        learnedFact = "Remembered user's name: $properName";
      }
    }

    // 2. Explicit "Remember that..." or "Keep in mind that..."
    final rememberRegex = RegExp(
      r'''\b(?:remember that|don'?t forget that|keep in mind that|please remember|note that)\s+(.+)''',
      caseSensitive: false,
    );
    final rememberMatch = rememberRegex.firstMatch(text);
    if (rememberMatch != null) {
      final fact = rememberMatch.group(1)?.trim();
      if (fact != null && fact.length >= 3) {
        addMemory("User note: $fact");
        learnedFact = "Saved note: $fact";
      }
    }

    // 3. Location statements: "I live in Tokyo", "I am from London", "I'm based in Berlin"
    final locRegex = RegExp(
      r'''\b(?:i live in|i am from|i'm from|i stay in|i am based in|i'm based in)\s+([A-Z][a-zA-Z\s,]{2,30})\b''',
      caseSensitive: false,
    );
    final locMatch = locRegex.firstMatch(text);
    if (locMatch != null) {
      final loc = locMatch.group(1)?.trim();
      if (loc != null && loc.isNotEmpty) {
        ref.read(appSettingsProvider.notifier).setUserLocation(loc);
        addMemory("User lives in $loc.");
        learnedFact = "Recorded location: $loc";
      }
    }

    // 4. Profession / Work: "I work as a software engineer", "I am an architect"
    final workRegex = RegExp(
      r'''\b(?:i work as an?|i am an?|i'm an?)\s+([a-zA-Z\s]{3,35})\b''',
      caseSensitive: false,
    );
    final workMatch = workRegex.firstMatch(text);
    if (workMatch != null) {
      final role = workMatch.group(1)?.trim();
      final nonRoles = {'human', 'user', 'person', 'fan', 'guy', 'girl'};
      if (role != null && !nonRoles.contains(role.toLowerCase())) {
        addMemory("User works as/is: $role.");
        learnedFact = "Noted role: $role";
      }
    }

    // 5. Personal goals & priorities: "My goal is to...", "I am focusing on..."
    final goalRegex = RegExp(
      r'''\b(?:my goal is to|i am focusing on|i'm focusing on|my main priority is)\s+(.+)''',
      caseSensitive: false,
    );
    final goalMatch = goalRegex.firstMatch(text);
    if (goalMatch != null) {
      final goal = goalMatch.group(1)?.trim();
      if (goal != null && goal.length >= 4) {
        addMemory("User goal/focus: $goal");
        learnedFact = "Noted priority: $goal";
      }
    }

    return learnedFact;
  }

  /// Multi-turn conversation buffer (last 10 messages)
  List<Map<String, String>> getHistory() {
    final raw = LocalStore().readMap(_historyKey);
    if (raw == null || raw['exchanges'] is! List) return [];
    return (raw['exchanges'] as List)
        .whereType<Map>()
        .map((m) => {
              'role': m['role']?.toString() ?? 'user',
              'content': m['content']?.toString() ?? '',
            })
        .where((m) => m['content']!.isNotEmpty)
        .toList();
  }

  void appendExchange(String userQuery, String assistantReply) {
    final history = getHistory();
    final updated = [
      ...history,
      {'role': 'user', 'content': userQuery.trim()},
      {'role': 'assistant', 'content': assistantReply.trim()},
    ];
    // Keep last 10 messages (5 exchanges) for optimal token balance
    final trimmed = updated.length > 10 ? updated.sublist(updated.length - 10) : updated;
    LocalStore().writeMap(_historyKey, {'exchanges': trimmed});
  }

  void clearHistory() {
    LocalStore().removeKey(_historyKey);
  }

  /// Formatted prompt block for LLM system prompt
  String getMemoryPromptSnippet() {
    final list = memories;
    if (list.isEmpty) return 'No prior personal trivia recorded yet.';
    final buffer = StringBuffer();
    for (final fact in list) {
      buffer.writeln('• $fact');
    }
    return buffer.toString().trim();
  }
}

