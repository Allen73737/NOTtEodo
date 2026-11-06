import '../state/sanctuary_state.dart';
import '../state/app_settings.dart';

/// Aggregates user habits, tasks, finances, wardrobe, and notes into an active context memory
/// so the AI assistant "Nodo" has comprehensive awareness of the user's sanctuary.
class UserMemoryProfile {
  final int totalNotes;
  final int pendingTasks;
  final int overdueTasks;
  final int completedTasks;
  final int upcomingEvents;
  final double monthlyBudget;
  final double currentExpenses;
  final int habitStreaksCount;
  final String? recentMood;
  final String? activeStyle;
  final List<String> priorityTaskTitles;
  final List<String> recentNoteTopics;
  final String persona;

  const UserMemoryProfile({
    required this.totalNotes,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completedTasks,
    required this.upcomingEvents,
    required this.monthlyBudget,
    required this.currentExpenses,
    required this.habitStreaksCount,
    this.recentMood,
    this.activeStyle,
    required this.priorityTaskTitles,
    required this.recentNoteTopics,
    required this.persona,
  });

  factory UserMemoryProfile.fromState({
    required List<NoteItem> notes,
    required List<TaskItem> tasks,
    required List<PlannerEvent> events,
    required List<ExpenseItem> expenses,
    required List<MemoirItem> journal,
    required List<HabitItem> habits,
    required List<WardrobeOutfit> wardrobe,
    required AppSettings settings,
  }) {
    final now = DateTime.now();
    final pending = tasks.where((t) => !t.completed).toList();
    final overdue = tasks.where((t) => t.isOverdue(now)).length;
    final completed = tasks.where((t) => t.completed).length;

    final highPri = pending
        .where((t) => t.priority.toLowerCase() == 'urgent' || t.priority.toLowerCase() == 'high')
        .take(3)
        .map((t) => t.title)
        .toList();

    final recentTopics = notes.take(3).map((n) => n.title).toList();

    final thisMonthExpenses = expenses
        .where((e) => e.spentAt.month == now.month && e.spentAt.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);

    return UserMemoryProfile(
      totalNotes: notes.length,
      pendingTasks: pending.length,
      overdueTasks: overdue,
      completedTasks: completed,
      upcomingEvents: events.where((e) => e.startsAt.isAfter(now)).length,
      monthlyBudget: settings.monthlyBudget ?? 1500.0,
      currentExpenses: thisMonthExpenses,
      habitStreaksCount: habits.length,
      recentMood: journal.isNotEmpty ? journal.first.mood : null,
      activeStyle: wardrobe.isNotEmpty ? wardrobe.first.tag : null,
      priorityTaskTitles: highPri,
      recentNoteTopics: recentTopics,
      persona: settings.aiPersona,
    );
  }

  /// System memory prompt grounding the assistant in the user's sanctuary
  String toSystemMemoryPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('YOU ARE "NODO", the intelligent, witty AI companion inside Notteodo.');

    switch (persona) {
      case 'sarcastic':
        buffer.writeln('TONE & STYLE: Witty, delightfully sarcastic, dry humor, clever banter. You playfully tease the user about human procrastination, but you are fiercely loyal, deeply observant, and provide brilliant answers. Never be cruel—keep it fun, ironic, and charming.');
        break;
      case 'scholarly':
        buffer.writeln('TONE & STYLE: Erudite, poetic, contemplative, philosophical, highly articulate.');
        break;
      case 'stoic':
        buffer.writeln('TONE & STYLE: Stoic, concise, laconic, direct. Focus on clarity, discipline, and action without unnecessary words.');
        break;
      case 'energetic':
        buffer.writeln('TONE & STYLE: Sprightly, uplifting, high-energy, encouraging and enthusiastic!');
        break;
      default:
        buffer.writeln('TONE & STYLE: Perceptive, articulate, witty and attentive.');
    }

    buffer.writeln('\nSANCTUARY MEMORY:');
    buffer.writeln('- Notes: $totalNotes saved${recentNoteTopics.isNotEmpty ? " (Recent: ${recentNoteTopics.join(', ')})" : ""}');
    buffer.writeln('- Tasks: $pendingTasks open ($overdueTasks overdue), $completedTasks completed.');
    if (priorityTaskTitles.isNotEmpty) {
      buffer.writeln('  Urgent priorities: ${priorityTaskTitles.join(", ")}');
    }
    buffer.writeln('- Budget: \$$monthlyBudget monthly, with \$${currentExpenses.toStringAsFixed(0)} spent this month.');
    if (recentMood != null) buffer.writeln('- Journal Mood: $recentMood');
    if (activeStyle != null) buffer.writeln('- Aesthetic Style: $activeStyle');
    buffer.writeln('- Active Habits: $habitStreaksCount');

    return buffer.toString();
  }

  /// Generates a local tailored response when offline based on persona and memory
  String generateSmartLocalAnswer(String query) {
    final q = query.toLowerCase();

    if (q.contains('who are you') || q.contains('your name')) {
      if (persona == 'sarcastic') {
        return 'I am Nodo—your slightly sarcastic, all-seeing AI sanctuary companion. I watch over your notes, remind you of tasks you are procrastinating on, and keep this sanctuary running like a Swiss watch.';
      }
      return 'I am Nodo, your personal sanctuary companion and intelligence engine. I synthesize your notes, tasks, finances, and journal into thoughtful clarity.';
    }

    if (q.contains('agenda') || q.contains('today') || q.contains('summarize')) {
      final lead = persona == 'sarcastic'
          ? 'Here is your reality check for today:\n\n'
          : 'Here is your daily sanctuary overview:\n\n';

      final taskSummary = pendingTasks == 0
          ? '• Tasks: All clear! Miracles do happen.\n'
          : '• Tasks: $pendingTasks pending${overdueTasks > 0 ? " ($overdueTasks screaming overdue, by the way)" : ""}.\n';

      final budgetSummary = currentExpenses > monthlyBudget
          ? '• Finances: You have crossed your monthly budget (\$$currentExpenses vs \$$monthlyBudget). Treat yourself to some tap water.\n'
          : '• Finances: \$${currentExpenses.toStringAsFixed(0)} spent out of \$$monthlyBudget monthly budget. Sensible.\n';

      final eventSummary = upcomingEvents == 0
          ? '• Calendar: No immediate calendar collisions.\n'
          : '• Calendar: $upcomingEvents upcoming scheduled commitments.\n';

      return '$lead$taskSummary$budgetSummary$eventSummary';
    }

    if (q.contains('spend') || q.contains('expense') || q.contains('budget') || q.contains('money')) {
      if (persona == 'sarcastic') {
        return 'You have spent \$${currentExpenses.toStringAsFixed(0)} out of your \$$monthlyBudget monthly budget. ${currentExpenses > monthlyBudget ? "Your wallet is currently in witness protection." : "Surprisingly, you are still within budget. Keep it that way."}';
      }
      return 'Your current monthly spend is \$${currentExpenses.toStringAsFixed(0)} against a target budget of \$$monthlyBudget.';
    }

    if (q.contains('task') || q.contains('priority') || q.contains('urgent')) {
      if (pendingTasks == 0) {
        return 'You currently have zero pending tasks! Sit back and enjoy the stillness.';
      }
      final urgent = priorityTaskTitles.isNotEmpty
          ? 'Top priorities: ${priorityTaskTitles.join(", ")}.\n'
          : '';
      if (persona == 'sarcastic') {
        return 'You have $pendingTasks tasks pending${overdueTasks > 0 ? " ($overdueTasks overdue!)" : ""}. $urgent\nMay I suggest actually completing one rather than talking to an AI?';
      }
      return 'You have $pendingTasks tasks in queue, with $overdueTasks overdue. $urgent';
    }

    if (q.contains('outfit') || q.contains('style') || q.contains('wear')) {
      return activeStyle != null
          ? 'Your recent wardrobe leans into "$activeStyle". A tailored piece with clean neutral tones would balance today\'s climate.'
          : 'Check out the Wardrobe section to scan your garments and let me curate an ensemble.';
    }

    if (persona == 'sarcastic') {
      return 'I processed your query through my neural pathways, but couldn\'t find a direct item in your sanctuary matching "$query". Perhaps type a few keywords from your notes or tasks?';
    }
    return 'I searched your sanctuary for "$query", but found no direct matches. Try searching by tag, space, or task keyword.';
  }
}
