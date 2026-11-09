import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/audio_cassette_player.dart';
import '../../../core/widgets/entry_editor.dart';
import 'encrypted_vault_view.dart';

const _prompts = [
  'What surprised you today?',
  'What would you like to remember about this week?',
  'What is taking up most of your thinking right now?',
  'Who made today better, and how?',
  'What did you learn the hard way recently?',
  'What are you looking forward to?',
  'What would make tomorrow a good day?',
];

/// Entries from the same day in earlier years, or from exactly a month ago.
List<MemoirItem> onThisDay(List<MemoirItem> entries, DateTime now) {
  bool sameDay(DateTime a, int month, int day) => a.month == month && a.day == day;
  final monthAgo = DateTime(now.year, now.month - 1, now.day);
  return entries
      .where((m) =>
          (sameDay(m.createdAt, now.month, now.day) && m.createdAt.year < now.year) ||
          DateLabels.isSameDay(m.createdAt, monthAgo))
      .toList();
}

/// The journal as a run of dated entries. Search, filter by mood, revisit what you
/// wrote on this day before, and start from a prompt when the page is blank.
class JournalEditorialView extends ConsumerStatefulWidget {
  const JournalEditorialView({super.key});

  @override
  ConsumerState<JournalEditorialView> createState() => _JournalEditorialViewState();
}

class _JournalEditorialViewState extends ConsumerState<JournalEditorialView> {
  String _query = '';
  String _mood = 'All';
  bool _vault = false;

  @override
  Widget build(BuildContext context) {
    if (_vault) return EncryptedVaultView(onClose: () => setState(() => _vault = false));

    final ed = Ed.of(context);
    final now = DateTime.now();
    final entries = ref.watch(journalProvider).where((m) => !m.isPrivate).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final moods = {for (final m in entries) m.mood}.toList()..sort();
    if (_mood != 'All' && !moods.contains(_mood)) _mood = 'All';
    final q = _query.toLowerCase();
    final shown = entries
        .where((m) => (_mood == 'All' || m.mood == _mood) && (q.isEmpty || m.title.toLowerCase().contains(q) || m.excerpt.toLowerCase().contains(q)))
        .toList();
    final memories = q.isEmpty && _mood == 'All' ? onThisDay(entries, now) : const <MemoirItem>[];
    final prompt = _prompts[now.difference(DateTime(now.year)).inDays % _prompts.length];
    final wroteToday = entries.any((m) => DateLabels.isSameDay(m.createdAt, now));

    // Group by month for a calendar-like reading order.
    final byMonth = <String, List<MemoirItem>>{};
    for (final m in shown) {
      byMonth.putIfAbsent(DateLabels.monthYear(m.createdAt), () => []).add(m);
    }

    return EditorialPage(
      kicker: 'Journal',
      title: wroteToday ? 'Today, written.' : 'Dear diary,',
      standfirst: entries.isEmpty ? 'A private place to think out loud.' : '${entries.length} entries.',
      actionLabel: 'Write',
      onAction: () => openEntryEditor(context, EntryKind.memoir),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!wroteToday)
                Semantics(
                  button: true,
                  label: 'Write about: $prompt',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => openEntryEditor(context, EntryKind.memoir),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('“$prompt”', style: ed.title.copyWith(fontSize: 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: ed.muted)),
                    ),
                  ),
                ),
              if (entries.isNotEmpty) EditorialSearch(hint: 'Search entries', onChanged: (v) => setState(() => _query = v)),
              if (moods.length > 1) EditorialTabs(options: ['All', ...moods], selected: _mood, onSelected: (m) => setState(() => _mood = m)),
            ],
          ),
        ),
        if (memories.isNotEmpty) ...[
          const SliverToBoxAdapter(child: EditorialSectionLabel('On this day')),
          SliverList.builder(itemCount: memories.length, itemBuilder: (_, i) => _entry(memories[i], now)),
        ],
        if (entries.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'Nothing written yet.',
              message: 'Type or record a few lines. Mark an entry private to keep it in the locked vault.',
              actionLabel: 'Start an entry  →',
              onAction: () => openEntryEditor(context, EntryKind.memoir),
            ),
          )
        else if (shown.isEmpty)
          const SliverToBoxAdapter(child: EditorialEmpty(title: 'No matches.', message: 'Try another word or mood.')),
        for (final e in byMonth.entries) ...[
          SliverToBoxAdapter(child: EditorialSectionLabel(e.key, count: e.value.length)),
          SliverList.builder(itemCount: e.value.length, itemBuilder: (_, i) => _entry(e.value[i], now)),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: EditorialAction(label: 'Private entries  →', muted: true, onTap: () => setState(() => _vault = true)),
          ),
        ),
      ],
    );
  }

  Widget _entry(MemoirItem m, DateTime now) {
    final journal = ref.read(journalProvider.notifier);
    return EditorialEntry(
      key: ValueKey(m.id),
      id: m.id,
      title: m.title,
      meta: [
        if (m.excerpt.isNotEmpty) m.excerpt,
        [DateLabels.relative(m.createdAt, now: now), m.mood, if (m.audioPath != null) 'voice'].join('  ·  '),
      ].join('\n'),
      leading: '${m.createdAt.day}'.padLeft(2, '0'),
      onTap: () => pushEditorial(context, MemoirReader(memoirId: m.id)),
      onLongPress: () => showEditorialMenu(context, title: m.title, subtitle: DateLabels.long(m.createdAt), items: [
        EditorialMenuItem('Read', () => pushEditorial(context, MemoirReader(memoirId: m.id))),
        EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.memoir, editing: m)),
        EditorialMenuItem('Copy text', () => copyToClipboard('${m.title}\n\n${m.excerpt}', what: 'Entry')),
        EditorialMenuItem('Move to private vault', () => journal.updateMemoir(m.id, isPrivate: true)),
        EditorialMenuItem('Delete', () => journal.deleteMemoir(m.id), destructive: true),
      ]),
      onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => journal.deleteMemoir(m.id)),
    );
  }
}

class MemoirReader extends ConsumerWidget {
  final String memoirId;

  const MemoirReader({super.key, required this.memoirId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final m = ref.watch(journalProvider).where((e) => e.id == memoirId).firstOrNull;
    if (m == null) {
      return EditorialDetail(kicker: 'Journal', title: 'Entry deleted', children: [Text('It is in the Bin for 30 days.', style: ed.standfirst)]);
    }
    return EditorialDetail(
      kicker: '${DateLabels.long(m.createdAt)}  ·  ${DateLabels.time(m.createdAt)}  ·  ${m.mood}',
      title: m.title,
      actions: [
        ('Copy', () => copyToClipboard('${m.title}\n\n${m.excerpt}', what: 'Entry')),
        ('Edit', () => openEntryEditor(context, EntryKind.memoir, editing: m)),
      ],
      children: [
        if (m.audioPath != null && m.audioPath!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AudioCassettePlayer(
              title: m.title,
              audioPath: m.audioPath,
              totalDuration: AudioCassettePlayer.parseDuration(m.duration.isNotEmpty ? m.duration : m.excerpt),
            ),
          ),
        Text(m.excerpt, style: ed.body.copyWith(fontSize: 18, height: 1.75)),
      ],
    );
  }
}
