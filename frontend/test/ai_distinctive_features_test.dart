import 'package:flutter_test/flutter_test.dart';
import 'package:notteodo/core/services/ai_briefing_service.dart';
import 'package:notteodo/core/services/ai_dossier_service.dart';
import 'package:notteodo/core/services/ai_pressure_test_service.dart';
import 'package:notteodo/core/services/ai_workflow_evolution_service.dart';
import 'package:notteodo/core/state/sanctuary_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NOTtEodo 4 Distinctive AI Features Verification', () {
    test('Feature 1: Autonomous Note-to-Workflow Evolution parses tasks and disbursements', () async {
      const noteContent = '''
Discussed Q3 strategy with team:
- [ ] Finalize enterprise architecture presentation
todo: Submit design review by tomorrow
Catering deposit: \$450
Conference passes: ₹12000
      ''';

      final bundle = await AiWorkflowEvolutionService().extractWorkflowsFromNote(noteContent);

      expect(bundle, isNotNull);
      expect(bundle.tasks.length, greaterThanOrEqualTo(1));
      expect(bundle.expenses.length, greaterThanOrEqualTo(1));
      expect(bundle.totalItems, greaterThan(0));
    });

    test('Feature 2: Weekly Executive Sanctuary Dossier synthesizes cross-module velocity', () async {
      final List<TaskItem> sampleTasks = [
        TaskItem(id: 't1', title: 'Deploy microservices', completed: true, priority: 'High Priority', space: 'Tech', timeOfDay: 'Morning'),
        TaskItem(id: 't2', title: 'Audit database performance', completed: false, priority: 'Medium Priority', space: 'Tech', timeOfDay: 'Afternoon'),
      ];
      final List<ExpenseItem> sampleExpenses = [
        ExpenseItem(id: 'e1', title: 'Cloud server hosting', amount: 80.0, category: 'Bills', spentAt: DateTime.now()),
      ];
      final List<NoteItem> sampleNotes = [
        NoteItem(
          id: 'n1',
          title: 'Architecture decisions',
          space: 'Tech',
          tag: 'System',
          excerpt: 'Immutable ledger...',
          content: 'Immutable ledger design',
          updatedAt: DateTime.now(),
        ),
      ];
      final List<HabitItem> sampleHabits = [
        HabitItem(id: 'h1', title: 'Deep work sprint', time: '08:00 AM', completedDays: {'2026-11-01', '2026-11-02'}),
      ];

      final dossier = await AiDossierService().generateWeeklyDossier(
        tasks: sampleTasks,
        expenses: sampleExpenses,
        notes: sampleNotes,
        habits: sampleHabits,
        forceRefresh: true,
      );

      expect(dossier, isNotNull);
      expect(dossier.velocityScore, isNotEmpty);
      expect(dossier.executiveSummary, isNotEmpty);
      expect(dossier.highlights, isNotEmpty);
      expect(dossier.capitalReport, isNotEmpty);
      expect(dossier.strategicNextSteps, isNotEmpty);
    });

    test('Feature 3: Strategic Sparring Partner Mode / Pressure Test uncovers blind spots', () async {
      const ideaTitle = 'Autonomous AI Agent Marketplace';
      const ideaBody = 'We will charge 30% take rate and build 100 connectors manually in 2 weeks.';

      final result = await AiPressureTestService().pressureTest(ideaTitle, ideaBody);

      expect(result, isNotNull);
      expect(result.ideaTitle, equals(ideaTitle));
      expect(result.verdict, isNotEmpty);
      expect(result.blindSpots, isNotEmpty);
      expect(result.capitalRisks, isNotEmpty);
      expect(result.counterPerspective, isNotEmpty);
      expect(result.hardeningRecommendation, isNotEmpty);
    });

    test('Feature 4: Forgotten Wisdom resurfaces archived note insights in Daily Briefing', () async {
      final List<NoteItem> sampleNotes = [
        NoteItem(
          id: 'ancient-1',
          title: 'The Power of Compounding Rest',
          space: 'Philosophy',
          tag: 'Health',
          excerpt: 'Sustained peak cognitive performance requires scheduled recovery...',
          content: 'Sustained peak cognitive performance requires scheduled recovery rituals.',
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];

      final briefing = await AiBriefingService().getOrGenerateBriefing(
        tasks: [],
        expenses: [],
        habits: [],
        notes: sampleNotes,
        monthlyBudget: 50000.0,
        forceRefresh: true,
      );

      expect(briefing, isNotNull);
      expect(briefing.forgottenWisdom, isNotEmpty);
      expect(briefing.forgottenWisdom.toLowerCase(), contains('compounding'));
    });
  });
}
