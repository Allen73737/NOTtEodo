import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/state/app_settings.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/entry_editor.dart';

/// The shopping list grouped by store. Type "eggs ×6 @ market" to add, tap to tick off,
/// hold to change the quantity, then move everything ticked into Expenses in one go.
class ShoppingEditorialView extends ConsumerWidget {
  const ShoppingEditorialView({super.key});

  /// "Eggs x6 @ Market 40" → name Eggs, quantity 6, store Market, price 40.
  static ({String name, int quantity, String store, int price}) parseLine(String line) {
    var text = line.trim();
    var quantity = 1, price = 0, store = '';
    final qty = RegExp(r'\s*[x×*]\s*(\d{1,3})\b', caseSensitive: false).firstMatch(text);
    if (qty != null) {
      quantity = int.parse(qty.group(1)!);
      text = text.replaceRange(qty.start, qty.end, '');
    }
    final at = RegExp(r'\s@\s*([^\d]+?)(?=\s+\d|$)').firstMatch(' $text');
    if (at != null) {
      store = at.group(1)!.trim();
      text = ' $text'.replaceRange(at.start, at.end, '').trim();
    }
    final cost = RegExp(r'\s(\d+(?:\.\d+)?)\s*$').firstMatch(' $text');
    if (cost != null) {
      price = double.parse(cost.group(1)!).round();
      text = ' $text'.replaceRange(cost.start, cost.end, '').trim();
    }
    return (name: text.isEmpty ? line.trim() : text, quantity: quantity, store: store, price: price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final items = ref.watch(shoppingProvider);
    final n = ref.read(shoppingProvider.notifier);
    final symbol = ref.watch(appSettingsProvider.select((s) => s.currencySymbol));
    final fmt = NumberFormat.decimalPatternDigits(decimalDigits: 0);
    String money(num v) => '$symbol${fmt.format(v)}';

    final open = items.where((i) => !i.checked).toList();
    final ticked = items.where((i) => i.checked).toList();
    final byStore = <String, List<ShoppingItem>>{};
    for (final i in open) {
      byStore.putIfAbsent(i.store.trim().isEmpty ? 'Anywhere' : i.store.trim(), () => []).add(i);
    }
    final openTotal = open.fold<int>(0, (s, i) => s + i.lineTotal);

    void add(String line) {
      final p = parseLine(line);
      final item = n.addItem(name: p.name, store: p.store, price: p.price);
      if (p.quantity > 1) n.setQuantity(item.id, p.quantity);
    }

    Future<void> quantity(ShoppingItem i) async {
      final raw = await showEditorialPrompt(context, title: 'How many?', initial: '${i.quantity}', keyboard: TextInputType.number);
      final v = int.tryParse(raw ?? '');
      if (v != null && v > 0) n.setQuantity(i.id, v);
    }

    void checkout() {
      final moved = n.convertCheckedToExpenses(ref);
      HapticFeedback.mediumImpact();
      AppToastEngine().notify(
        title: 'Added to Expenses',
        message: '${moved.length} ${moved.length == 1 ? 'item' : 'items'}, ${money(moved.fold<int>(0, (s, i) => s + i.lineTotal))}.',
        type: ToastType.success,
      );
    }

    Widget entry(ShoppingItem i) => EditorialEntry(
          key: ValueKey(i.id),
          id: i.id,
          title: i.quantity > 1 ? '${i.name}  ×${i.quantity}' : i.name,
          meta: [if (i.price > 0 && i.quantity > 1) '${money(i.price)} each', if (i.url != null && i.url!.isNotEmpty) 'link'].join('  ·  '),
          trailing: i.price > 0 ? money(i.lineTotal) : null,
          leading: i.checked ? '●' : '○',
          leadingColor: i.checked ? ed.faint : ed.muted,
          done: i.checked,
          onLeadingTap: () => n.toggleItem(i.id),
          onTap: () => n.toggleItem(i.id),
          onLongPress: () => showEditorialMenu(context, title: i.name, items: [
            EditorialMenuItem('Change quantity (${i.quantity})', () => quantity(i)),
            EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.shopping, editing: i)),
            if (i.url != null && i.url!.isNotEmpty)
              EditorialMenuItem('Open link', () => launchUrl(Uri.parse(i.url!), mode: LaunchMode.externalApplication)),
            EditorialMenuItem('Delete', () => n.deleteItem(i.id), destructive: true),
          ]),
          onSwipeRight: EditorialSwipe(label: i.checked ? 'Undo' : 'Got it', onSwipe: () => n.toggleItem(i.id)),
          onSwipeLeft: EditorialSwipe(label: 'Delete', removes: true, onSwipe: () => n.deleteItem(i.id)),
        );

    return EditorialPage(
      kicker: 'Shopping',
      title: 'The list',
      standfirst: items.isEmpty
          ? 'Write what you need; group it by shop with "@".'
          : '${open.length} to get${openTotal > 0 ? ', about ${money(openTotal)}' : ''}.',
      slivers: [
        SliverToBoxAdapter(child: EditorialAddLine(hint: 'Add — "eggs ×6 @ market 40"', onAdd: add)),
        if (items.isEmpty)
          const SliverToBoxAdapter(
            child: EditorialEmpty(title: 'Nothing to buy.', message: 'Add a line above. "×3" sets the quantity, "@ store" groups it, a number at the end is the price.'),
          ),
        for (final store in byStore.entries) ...[
          SliverToBoxAdapter(child: EditorialSectionLabel(store.key, count: store.value.length)),
          SliverList.builder(itemCount: store.value.length, itemBuilder: (_, i) => entry(store.value[i])),
        ],
        if (ticked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: EditorialSectionLabel('In the basket', count: ticked.length, actionLabel: 'Add to Expenses', onAction: checkout),
          ),
          SliverList.builder(itemCount: ticked.length, itemBuilder: (_, i) => entry(ticked[i])),
        ],
      ],
    );
  }
}
