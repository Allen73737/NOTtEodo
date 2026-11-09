import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/state/bin_state.dart';
import '../../../core/widgets/app_toast_engine.dart';

/// The Bin as a plain list: swipe right to put something back where it was, left to
/// delete it for good. Everything leaves on its own after 30 days.
class BinEditorialView extends ConsumerStatefulWidget {
  final ValueChanged<int> onOpenModule;

  const BinEditorialView({super.key, required this.onOpenModule});

  @override
  ConsumerState<BinEditorialView> createState() => _BinEditorialViewState();
}

class _BinEditorialViewState extends ConsumerState<BinEditorialView> {
  String _kind = 'All';

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(binProvider);
    final bin = ref.read(binProvider.notifier);
    final now = DateTime.now();
    final kinds = {for (final e in entries) e.kind.plural}.toList()..sort();
    if (!kinds.contains(_kind)) _kind = 'All';
    final shown = entries.where((e) => _kind == 'All' || e.kind.plural == _kind).toList();

    void restore(BinEntry e) {
      bin.restore(e.id);
      AppToastEngine().notify(
        title: 'Put back',
        message: '"${e.title}" is back in ${e.kind.plural}.',
        actionLabel: 'Open',
        onAction: () => widget.onOpenModule(e.kind.moduleIndex),
      );
    }

    return EditorialPage(
      kicker: 'Bin',
      title: 'Recently deleted',
      standfirst: entries.isEmpty ? 'Nothing here. Deleted things wait 30 days before they go.' : '${entries.length} items. Each leaves after 30 days.',
      slivers: [
        if (kinds.length > 1) SliverToBoxAdapter(child: EditorialTabs(options: ['All', ...kinds], selected: _kind, onSelected: (k) => setState(() => _kind = k))),
        if (entries.isNotEmpty)
          SliverToBoxAdapter(
            child: Wrap(
              spacing: 20,
              children: [
                EditorialAction(label: 'Restore all', muted: true, onTap: bin.restoreAll),
                EditorialAction(
                  label: 'Empty the bin',
                  muted: true,
                  onTap: () => showEditorialMenu(context, title: 'Delete ${entries.length} items for good?', subtitle: 'This cannot be undone.', items: [
                    EditorialMenuItem('Empty the bin', bin.empty, destructive: true),
                  ]),
                ),
              ],
            ),
          ),
        SliverList.builder(
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final e = shown[i];
            return EditorialEntry(
              key: ValueKey(e.id),
              id: 'bin-${e.id}',
              title: e.title,
              meta: [e.kind.label, if (e.detail.isNotEmpty) e.detail, '${e.daysLeft(now)} days left'].join('  ·  '),
              onTap: () => showEditorialMenu(context, title: e.title, subtitle: e.kind.label, items: [
                EditorialMenuItem('Put it back', () => restore(e)),
                EditorialMenuItem('Delete for good', () => bin.purge(e.id), destructive: true),
              ]),
              onSwipeRight: EditorialSwipe(label: 'Put back', removes: true, onSwipe: () => restore(e)),
              onSwipeLeft: EditorialSwipe(label: 'Delete for good', removes: true, onSwipe: () => bin.purge(e.id)),
            );
          },
        ),
      ],
    );
  }
}
