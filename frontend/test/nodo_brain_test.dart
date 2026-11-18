import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/ai/nodo_app_guide.dart';
import 'package:notteodo/core/ai/user_memory_profile.dart';

UserMemoryProfile _profile() => const UserMemoryProfile(
      curatorName: 'Ana',
      bioMotto: 'Make today deliberate',
      activeStreak: 4,
      longestStreak: 9,
      streakFreezesCount: 1,
      currencySymbol: '€',
      totalNotes: 2,
      recentNoteSummaries: ['Trip ideas'],
      pendingTasks: 3,
      overdueTasks: 1,
      completedTasks: 10,
      priorityTasksDetail: ['File taxes'],
      overdueTasksDetail: ['Call landlord'],
      upcomingEventsCount: 0,
      upcomingEventsDetail: [],
      monthlyBudget: 900,
      currentExpenses: 420,
      recentExpensesDetail: [],
      totalHabits: 0,
      habitsDetail: [],
      persona: 'stoic',
      learnedMemories: ['Prefers short answers.'],
    );

void main() {
  final raw = File('assets/nodo/app_guide.json').readAsStringSync();
  final sections = NodoAppGuide.parse(raw);

  test('the server reads the same app guide as the app', () {
    final server = File('../backend/supabase/functions/_shared/app_guide.json');
    expect(server.existsSync(), isTrue);
    expect(server.readAsStringSync().replaceAll('\r\n', '\n'), raw.replaceAll('\r\n', '\n'));
  });

  test('the user guide never mentions admin tools or the model behind Nodo', () {
    final all = sections.map((s) => '${s.title} ${s.body} ${s.keywords.join(' ')}').join(' ').toLowerCase();
    for (final word in ['admin', 'supabase', 'groq', 'llama', 'gpt', 'edge function', 'service role']) {
      expect(all.contains(word), isFalse, reason: word);
    }
  });

  test('finds where things live in the app', () {
    expect(NodoAppGuide.search('I forgot my vault pin', from: sections).first.id, 'vault');
    expect(NodoAppGuide.search('how do I add a home screen widget', from: sections).first.id, 'widgets');
    expect(NodoAppGuide.search('restore something I deleted', from: sections).first.id, 'bin');
    expect(NodoAppGuide.answer('where do I set my monthly budget', from: sections), contains('Settings → Money'));
    expect(NodoAppGuide.answer('zzzz qqqq', from: sections), isNull);
  });

  test('tells how-to questions from questions about their own things', () {
    expect(NodoAppGuide.looksLikeHowTo('How do I switch to editorial view?'), isTrue);
    expect(NodoAppGuide.looksLikeHowTo('Where is the bin'), isTrue);
    expect(NodoAppGuide.looksLikeHowTo('Summarize my week'), isFalse);
  });

  test('the profile sent to Nodo is data about the person, not instructions', () {
    final digest = _profile().toProfileDigest();
    expect(digest, contains('Ana'));
    expect(digest, contains('Prefers short answers.'));
    expect(digest, contains('File taxes'));
    expect(digest.contains('YOU ARE'), isFalse);
    expect(digest.contains('ACTION:'), isFalse);
    expect(digest.contains('TONE:'), isFalse);
  });

  test('on the device, Nodo answers app questions from the guide', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await NodoAppGuide.load();
    final p = _profile();
    expect(p.generateSmartLocalAnswer('How do I restore a deleted note?'), contains('Bin'));
    // Questions about their own things still get their own numbers.
    expect(p.generateSmartLocalAnswer('what is my streak'), contains('4 days'));
    expect(p.generateSmartLocalAnswer('who are you'), startsWith("I'm Nodo"));
  });
}
