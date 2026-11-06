import '../services/companion_memory_service.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';

/// Aggregates user identity, habits, tasks, finances, wardrobe, journal, and notes
/// into an active ground-truth context so AI Companion "Nodo" is deeply aware of the user.
class UserMemoryProfile {
  final String curatorName;
  final String bioMotto;
  final String? userLocation;
  final int activeStreak;
  final int longestStreak;
  final int streakFreezesCount;
  final String currencySymbol;

  final int totalNotes;
  final List<String> recentNoteSummaries;

  final int pendingTasks;
  final int overdueTasks;
  final int completedTasks;
  final List<String> priorityTasksDetail;
  final List<String> overdueTasksDetail;

  final int upcomingEventsCount;
  final List<String> upcomingEventsDetail;

  final double monthlyBudget;
  final double currentExpenses;
  final List<String> recentExpensesDetail;

  final int totalHabits;
  final List<String> habitsDetail;

  final String? recentMood;
  final String? recentJournalExcerpt;
  final String? activeStyle;
  final String persona;
  final List<String> learnedMemories;

  const UserMemoryProfile({
    required this.curatorName,
    required this.bioMotto,
    this.userLocation,
    required this.activeStreak,
    required this.longestStreak,
    required this.streakFreezesCount,
    required this.currencySymbol,
    required this.totalNotes,
    required this.recentNoteSummaries,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completedTasks,
    required this.priorityTasksDetail,
    required this.overdueTasksDetail,
    required this.upcomingEventsCount,
    required this.upcomingEventsDetail,
    required this.monthlyBudget,
    required this.currentExpenses,
    required this.recentExpensesDetail,
    required this.totalHabits,
    required this.habitsDetail,
    this.recentMood,
    this.recentJournalExcerpt,
    this.activeStyle,
    required this.persona,
    required this.learnedMemories,
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
    final name = settings.displayName.trim().isNotEmpty ? settings.displayName.trim() : 'Curator';

    final pending = tasks.where((t) => !t.completed).toList();
    final overdue = tasks.where((t) => t.isOverdue(now)).toList();
    final completed = tasks.where((t) => t.completed).length;

    // Top priority tasks detail
    final priorityDetails = pending
        .where((t) => t.priority.toLowerCase() == 'urgent' || t.priority.toLowerCase() == 'high')
        .take(5)
        .map((t) => '${t.title}${t.timeOfDay.isNotEmpty ? " (${t.timeOfDay})" : ""}')
        .toList();

    // Overdue tasks detail
    final overdueDetails = overdue.take(4).map((t) => t.title).toList();

    // Notes summaries
    final noteSummaries = notes.take(5).map((n) {
      final tagStr = n.tag.isNotEmpty ? ' #${n.tag}' : '';
      final snippet = n.excerpt.isNotEmpty ? ' — "${n.excerpt.replaceAll("\n", " ").take(60)}"' : '';
      return '${n.title} [${n.space}$tagStr]$snippet';
    }).toList();

    // Expenses calculation
    final thisMonthExpenses = expenses
        .where((e) => e.spentAt.month == now.month && e.spentAt.year == now.year)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final recentExp = expenses.take(4).map((e) {
      return '${e.title}: ${settings.currencySymbol}${e.amount.toStringAsFixed(0)} (${e.category})';
    }).toList();

    // Habits detail with streak & completed today
    final habitDetails = habits.take(6).map((h) {
      final status = h.completedToday ? 'Completed today' : 'Pending';
      return '${h.title} ($status, ${h.streak}d streak)';
    }).toList();

    // Upcoming events
    final upcoming = events
        .where((e) => e.startsAt.isAfter(now.subtract(const Duration(hours: 1))))
        .take(4)
        .map((e) => '${e.title} at ${e.startsAt.hour.toString().padLeft(2, "0")}:${e.startsAt.minute.toString().padLeft(2, "0")}')
        .toList();

    // Journal excerpt
    String? journalExcerpt;
    if (journal.isNotEmpty) {
      final j = journal.first;
      journalExcerpt = '"${j.excerpt.replaceAll("\n", " ").take(80)}"';
    }

    return UserMemoryProfile(
      curatorName: name,
      bioMotto: settings.bioMotto,
      userLocation: settings.userLocation,
      activeStreak: settings.activeStreak > 0 ? settings.activeStreak : 1,
      longestStreak: settings.longestStreak,
      streakFreezesCount: settings.streakFreezesCount,
      currencySymbol: settings.currencySymbol,
      totalNotes: notes.length,
      recentNoteSummaries: noteSummaries,
      pendingTasks: pending.length,
      overdueTasks: overdue.length,
      completedTasks: completed,
      priorityTasksDetail: priorityDetails,
      overdueTasksDetail: overdueDetails,
      upcomingEventsCount: upcoming.length,
      upcomingEventsDetail: upcoming,
      monthlyBudget: settings.monthlyBudget ?? 15000.0,
      currentExpenses: thisMonthExpenses,
      recentExpensesDetail: recentExp,
      totalHabits: habits.length,
      habitsDetail: habitDetails,
      recentMood: journal.isNotEmpty ? journal.first.mood : null,
      recentJournalExcerpt: journalExcerpt,
      activeStyle: wardrobe.isNotEmpty ? wardrobe.first.tag : null,
      persona: settings.aiPersona,
      learnedMemories: CompanionMemoryService().memories,
    );
  }

  /// System memory prompt grounding the assistant in the user's sanctuary
  String toSystemMemoryPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('YOU ARE "NODO", the deeply perceptive, warm, articulate, and intelligent AI companion inside NOTtEodo.');
    buffer.writeln();

    buffer.writeln('ABOUT YOUR CURATOR:');
    buffer.writeln('- Name: $curatorName');
    if (userLocation != null && userLocation!.isNotEmpty) {
      buffer.writeln('- Location: $userLocation');
    }
    buffer.writeln('- Motto: "$bioMotto"');
    buffer.writeln('- Active Live Streak: ${activeStreak}d unbroken (Longest: ${longestStreak}d | Streak Freezes: $streakFreezesCount)');
    buffer.writeln();

    if (learnedMemories.isNotEmpty) {
      buffer.writeln('KNOWN USER MEMORIES & PERSONAL FACTS:');
      for (final mem in learnedMemories) {
        buffer.writeln('• $mem');
      }
      buffer.writeln();
    }

    buffer.writeln('LIVE GROUND-TRUTH SANCTUARY STATE:');
    buffer.writeln('- Tasks: $pendingTasks open ($overdueTasks overdue), $completedTasks completed overall.');
    if (priorityTasksDetail.isNotEmpty) {
      buffer.writeln('  Urgent priorities: ${priorityTasksDetail.join("; ")}');
    }
    if (overdueTasksDetail.isNotEmpty) {
      buffer.writeln('  Overdue tasks: ${overdueTasksDetail.join("; ")}');
    }

    if (habitsDetail.isNotEmpty) {
      buffer.writeln('- Habits: ${habitsDetail.join("; ")}');
    }

    buffer.writeln('- Finances: $currencySymbol${currentExpenses.toStringAsFixed(0)} spent out of $currencySymbol${monthlyBudget.toStringAsFixed(0)} monthly budget.');
    if (recentExpensesDetail.isNotEmpty) {
      buffer.writeln('  Recent expenses: ${recentExpensesDetail.join("; ")}');
    }

    buffer.writeln('- Notes ($totalNotes total): ${recentNoteSummaries.join(" | ")}');

    if (upcomingEventsDetail.isNotEmpty) {
      buffer.writeln('- Scheduled Events: ${upcomingEventsDetail.join("; ")}');
    }

    if (recentMood != null || recentJournalExcerpt != null) {
      buffer.writeln('- Journal: Mood: ${recentMood ?? "reflective"}${recentJournalExcerpt != null ? " ($recentJournalExcerpt)" : ""}');
    }

    if (activeStyle != null) {
      buffer.writeln('- Curated Style: $activeStyle');
    }
    buffer.writeln();

    buffer.writeln('COMPANION PERSONALITY & INSTRUCTIONS:');
    buffer.writeln('1. Address $curatorName naturally by name when appropriate. Speak like a true personal companion who knows their rhythm, habits, and priorities—never like a detached corporate chatbot.');
    buffer.writeln('2. If $curatorName tells you their name, personal preferences, or asks you to remember something, warmly acknowledge and confirm you have committed it to your persistent companion memory.');
    buffer.writeln('3. Ground answers in $curatorName\'s live sanctuary data above. If they ask about tasks, budget, streak, or schedule, use their exact real metrics.');
    buffer.writeln('4. If $curatorName asks you to create a task, note, or expense, answer concisely and append an executable action tag:');
    buffer.writeln('   [ACTION: CREATE_TASK: {"title": "Task title", "priority": "urgent"}]');
    buffer.writeln('   [ACTION: ADD_EXPENSE: {"title": "Expense title", "amount": 200, "category": "Food"}]');
    buffer.writeln('   [ACTION: CREATE_NOTE: {"title": "Note title", "content": "Note body"}]');
    buffer.writeln();

    switch (persona) {
      case 'sarcastic':
        buffer.writeln('TONE: Witty, delightfully sarcastic, dry humor, playful banter. Tease $curatorName affectionately about any overdue tasks or temptations to procrastinate, but always deliver sharp, genuinely brilliant assistance.');
        break;
      case 'scholarly':
        buffer.writeln('TONE: Erudite, poetic, contemplative, philosophical, highly articulate and thoughtful.');
        break;
      case 'stoic':
        buffer.writeln('TONE: Stoic, concise, laconic, direct. Focus on clarity, discipline, and intentional action.');
        break;
      case 'energetic':
        buffer.writeln('TONE: Sprightly, uplifting, high-energy, encouraging and enthusiastic!');
        break;
      default:
        buffer.writeln('TONE: Perceptive, warm, loyal, articulate, and attentive companion.');
    }

    return buffer.toString();
  }

  /// Generates a rich, high-EQ on-device response when offline or before cloud returns
  String generateSmartLocalAnswer(String query) {
    final q = query.toLowerCase().trim();

    // 1. User Name & Identity Queries
    if (q.contains('my name') || q.contains('who am i') || q.contains('what is my name') || q.contains('do you know me')) {
      if (curatorName != 'Curator') {
        return 'You are $curatorName, the curator of this sanctuary! I remember your rhythm, your streak of ${activeStreak}d, and everything you are crafting here.';
      }
      return 'You are the curator of this sanctuary. If you would like me to call you by a specific name, just tell me: "My name is [your name]".';
    }

    // 2. Who is Nodo?
    if (q.contains('who are you') || q.contains('your name') || q.contains('what are you')) {
      if (persona == 'sarcastic') {
        return 'I am Nodo—your slightly sarcastic, all-seeing AI sanctuary companion. I watch over your notes, remind you of the tasks you are actively procrastinating on, and keep your workspace in pristine order.';
      }
      return 'I am Nodo, your personal sanctuary companion and intelligence engine. I keep track of your notes, tasks, habits, and finances, and help you navigate your day with clarity.';
    }

    // 3. Stored Memories / What do you know about me?
    if (q.contains('remember') || q.contains('know about me') || q.contains('memory') || q.contains('memories')) {
      final buffer = StringBuffer();
      buffer.writeln('Here is what I have committed to memory about you, $curatorName:\n');
      buffer.writeln('• Name: $curatorName');
      if (userLocation != null && userLocation!.isNotEmpty) buffer.writeln('• Location: $userLocation');
      buffer.writeln('• Motto: "$bioMotto"');
      buffer.writeln('• Current streak: ${activeStreak}d (Flame Evolution active)');

      if (learnedMemories.isNotEmpty) {
        buffer.writeln('\nPersonal trivia & learned notes:');
        for (final m in learnedMemories) {
          buffer.writeln('• $m');
        }
      }
      return buffer.toString().trim();
    }

    // 4. Agenda / Today's Briefing
    if (q.contains('agenda') || q.contains('today') || q.contains('briefing') || q.contains('summary') || q.contains('overview')) {
      final lead = persona == 'sarcastic'
          ? 'Here is your reality check for today, $curatorName:\n\n'
          : 'Good to check in, $curatorName. Here is your sanctuary status today:\n\n';

      final taskSummary = pendingTasks == 0
          ? '• Tasks: All clear! Every single priority has been conquered.\n'
          : '• Tasks: $pendingTasks pending${overdueTasks > 0 ? " ($overdueTasks overdue!)" : ""}.\n'
              '${priorityTasksDetail.isNotEmpty ? "  Top priority: ${priorityTasksDetail.first}\n" : ""}';

      final habitSummary = totalHabits == 0
          ? '• Habits: No active habits configured yet.\n'
          : '• Habits: ${habitsDetail.take(3).join(", ")}.\n';

      final budgetSummary = currentExpenses > monthlyBudget
          ? '• Finances: Over budget ($currencySymbol${currentExpenses.toStringAsFixed(0)} vs $currencySymbol${monthlyBudget.toStringAsFixed(0)}).\n'
          : '• Finances: $currencySymbol${currentExpenses.toStringAsFixed(0)} spent of $currencySymbol${monthlyBudget.toStringAsFixed(0)} monthly target.\n';

      final eventSummary = upcomingEventsCount == 0
          ? '• Calendar: No immediate calendar collisions.\n'
          : '• Calendar: ${upcomingEventsDetail.join(", ")}.\n';

      return '$lead$taskSummary$habitSummary$budgetSummary$eventSummary';
    }

    // 5. Tasks & Priorities
    if (q.contains('task') || q.contains('todo') || q.contains('priority') || q.contains('urgent') || q.contains('what should i do')) {
      if (pendingTasks == 0) {
        return 'You have zero pending tasks, $curatorName! Take a breath, write a journal reflection, or enjoy your momentum.';
      }
      final urgentStr = priorityTasksDetail.isNotEmpty ? '\n\nTop focus items:\n• ${priorityTasksDetail.join("\n• ")}' : '';
      final overdueStr = overdueTasks > 0 ? '\n⚠️ You have $overdueTasks overdue tasks.' : '';
      if (persona == 'sarcastic') {
        return 'You have $pendingTasks tasks pending.$overdueStr$urgentStr\n\nMay I suggest conquering one of these rather than debating an AI?';
      }
      return 'You currently have $pendingTasks tasks in your queue.$overdueStr$urgentStr';
    }

    // 6. Finances & Budget
    if (q.contains('spend') || q.contains('expense') || q.contains('budget') || q.contains('money') || q.contains('treasury')) {
      final pct = (currentExpenses / (monthlyBudget <= 0 ? 1 : monthlyBudget) * 100).toInt();
      final recentStr = recentExpensesDetail.isNotEmpty ? '\n\nRecent disbursements:\n• ${recentExpensesDetail.join("\n• ")}' : '';
      if (persona == 'sarcastic') {
        return 'You have spent $currencySymbol${currentExpenses.toStringAsFixed(0)} out of your $currencySymbol${monthlyBudget.toStringAsFixed(0)} budget ($pct%). ${currentExpenses > monthlyBudget ? "Your wallet is currently seeking asylum." : "Surprisingly within bounds. Keep it that way."}$recentStr';
      }
      return 'Monthly Runway: $currencySymbol${currentExpenses.toStringAsFixed(0)} spent of $currencySymbol${monthlyBudget.toStringAsFixed(0)} ($pct% allocated).$recentStr';
    }

    // 7. Habits & Streak
    if (q.contains('habit') || q.contains('streak') || q.contains('routine')) {
      final habitsStr = habitsDetail.isNotEmpty ? '\n• ${habitsDetail.join("\n• ")}' : '';
      return 'Your active sanctuary streak is **$activeStreak days**! (Longest: $longestStreak days, with $streakFreezesCount streak freeze shields in reserve).\n\nToday\'s habits:$habitsStr';
    }

    // 8. General conversational greetings / check-in
    if (q.contains('hello') || q.contains('hi') || q.contains('hey') || q.contains('good morning') || q.contains('good evening') || q.contains('how are you')) {
      if (persona == 'sarcastic') {
        return 'Greetings, $curatorName. I am fully operational and observing your sanctuary. What shall we tackle, or are we just browsing?';
      }
      return 'Hello $curatorName! I\'m here and fully tuned in to your sanctuary. How can I help you conquer today?';
    }

    // 9. Notes & Knowledge
    if (q.contains('note') || q.contains('knowledge') || q.contains('idea') || q.contains('write')) {
      final notesList = recentNoteSummaries.isNotEmpty ? '\n• ${recentNoteSummaries.take(3).join("\n• ")}' : '';
      return 'You have $totalNotes notes safely stored in your knowledge vault.$notesList\n\nAsk me about any specific topic and I will surface the connections!';
    }

    // Default intelligent companion response
    return 'I am tuned in to your sanctuary, $curatorName. You currently have $pendingTasks open tasks and a ${activeStreak}d streak. You can ask me to summarize your day, check your budget, review your habits, or tell me anything you want me to remember!';
  }
}

extension _TakeHelper on String {
  String take(int n) => length <= n ? this : '${substring(0, n)}...';
}
