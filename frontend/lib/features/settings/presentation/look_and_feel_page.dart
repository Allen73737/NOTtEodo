import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/editorial/editorial_chrome.dart' show editorialModuleNames;
import '../../../core/editorial/editorial_kit.dart';
import '../../../core/editorial/editorial_mode.dart';
import '../../../core/editorial/view_style_chooser.dart';
import '../../../core/motion/motion.dart';
import '../../../core/state/app_settings.dart';

/// Every look-and-feel choice on one page: view, colour, type, size, spacing, motion,
/// gestures, the dock and which sections show. Changes apply as you tap them.
class LookAndFeelPage extends ConsumerWidget {
  const LookAndFeelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final s = ref.watch(appSettingsProvider);
    final n = ref.read(appSettingsProvider.notifier);
    final p = UiPrefs.of(s);

    void setUi(String key, Object? value) {
      HapticFeedback.selectionClick();
      n.setUi(key, value);
      // Plain helpers (edBox, type) read statics: rebuild everything so the change shows at once.
      rebuildAllWidgets(context);
    }

    Widget choice(String label, bool selected, VoidCallback onTap, {String? note, TextStyle? style}) => Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, child: Text(selected ? '●' : '○', style: ed.entry.copyWith(color: selected ? ed.accent : ed.faint))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: Motion.standard,
                          style: (style ?? ed.entry).copyWith(color: selected ? ed.ink : ed.muted),
                          child: Text(label),
                        ),
                        if (note != null) Text(note, style: ed.meta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    Widget toggle(String label, String note, bool value, ValueChanged<bool> onChanged) => MergeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(label, style: ed.entry), Text(note, style: ed.meta)],
                  ),
                ),
                Switch.adaptive(value: value, activeTrackColor: ed.accent, onChanged: onChanged),
              ],
            ),
          ),
        );

    const modules = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    return EditorialDetail(
      kicker: 'Settings',
      title: 'Look & feel',
      standfirst: 'Make the pages yours. Every change applies straight away and follows your account.',
      children: [
        const EditorialSectionLabel('View'),
        for (final style in const ['editorial', 'bento'])
          choice(viewStyleName(style), s.cardStyle == style, () => toggleViewStyle(context, ref, to: style), note: viewStyleDescription(style)),
        EditorialAction(
          label: 'Compare them side by side  →',
          muted: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewStyleChooser())),
        ),

        const EditorialSectionLabel('Accent colour'),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final a in UiPrefs.accents)
              Semantics(
                button: true,
                selected: p.accent == a,
                label: a,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => setUi('accent', a),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Motion.standard,
                        curve: Motion.settle,
                        width: p.accent == a ? 34 : 26,
                        height: p.accent == a ? 34 : 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ed.dark ? accentColors[a]!.$2 : accentColors[a]!.$1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${a[0].toUpperCase()}${a.substring(1)}', style: ed.meta.copyWith(fontSize: 12, color: p.accent == a ? ed.ink : ed.muted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Used for marks, links and highlights in the Editorial view.', style: ed.meta),
        ),

        const EditorialSectionLabel('Text size'),
        EditorialTabs(
          options: const ['Smaller', 'Regular', 'Larger', 'Largest', 'Sovereign'],
          selected: switch (p.textScale.toLowerCase()) {
            'sovereign' => 'Sovereign',
            'largest' => 'Largest',
            'larger' => 'Larger',
            'smaller' || 'compact' => 'Smaller',
            _ => 'Regular',
          },
          onSelected: (v) => setUi('textScale', v.toLowerCase()),
        ),
        Text('The quick brown fox writes today’s plan.', style: ed.body),
        Text('Added on top of your phone’s own text size.', style: ed.meta),

        const EditorialSectionLabel('Headlines'),
        for (final h in UiPrefs.headlines.entries)
          choice(
            '${h.key[0].toUpperCase()}${h.key.substring(1)}',
            p.headline == h.key,
            () => setUi('headline', h.key),
            note: h.value,
            style: GoogleFonts.getFont(h.value, fontSize: 22, fontWeight: FontWeight.w600),
          ),

        const EditorialSectionLabel('Spacing'),
        EditorialTabs(
          options: const ['Compact', 'Comfortable', 'Airy'],
          selected: '${p.density[0].toUpperCase()}${p.density.substring(1)}',
          onSelected: (v) => setUi('density', v.toLowerCase()),
        ),

        const EditorialSectionLabel('Light and dark'),
        EditorialTabs(
          options: const ['System', 'Light', 'Dark'],
          selected: switch (s.themeMode) { ThemeMode.light => 'Light', ThemeMode.dark => 'Dark', _ => 'System' },
          onSelected: (v) => n.setThemeMode(switch (v) { 'Light' => ThemeMode.light, 'Dark' => ThemeMode.dark, _ => ThemeMode.system }),
        ),

        const EditorialSectionLabel('Feel'),
        toggle('Calm motion', 'Fewer and shorter animations.', s.reducedMotion, n.setReducedMotion),
        toggle('Swipe actions', 'Swipe right to finish, left to delete.', p.swipeActions, (v) => setUi('swipeActions', v)),
        toggle('Ask before deleting', 'Confirm a swipe that deletes.', p.confirmDeletes, (v) => setUi('confirmDeletes', v)),
        toggle('Celebrate wins', 'A small moment when you finish a habit or a day.', p.celebrate, (v) => setUi('celebrate', v)),

        const EditorialSectionLabel('Start on'),
        EditorialTabs(
          options: const ['Today', 'Notes', 'Tasks', 'Planner'],
          selected: const ['Today', 'Notes', 'Tasks', 'Planner'][s.defaultStartScreen.clamp(0, 3)],
          onSelected: (v) => n.setDefaultStartScreen(const ['Today', 'Notes', 'Tasks', 'Planner'].indexOf(v)),
        ),

        EditorialSectionLabel('Dock', count: p.dock.length),
        Text('Pick four places for the Editorial dock, in the order you tap them.', style: ed.meta),
        Wrap(
          spacing: 18,
          children: [
            for (final m in [0, ...modules])
              EditorialAction(
                label: p.dock.contains(m) ? '${p.dock.indexOf(m) + 1}  ${editorialModuleNames[m]}' : editorialModuleNames[m]!,
                muted: !p.dock.contains(m),
                onTap: () {
                  final dock = [...p.dock];
                  if (!dock.remove(m)) {
                    if (dock.length >= 4) dock.removeAt(0);
                    dock.add(m);
                  }
                  setUi('dock', dock.isEmpty ? null : dock);
                },
              ),
          ],
        ),

        const EditorialSectionLabel('Show in the menu'),
        for (final m in modules)
          toggle(editorialModuleNames[m]!, p.hiddenModules.contains(m) ? 'Hidden' : 'Shown', !p.hiddenModules.contains(m), (show) {
            final hidden = {...p.hiddenModules};
            show ? hidden.remove(m) : hidden.add(m);
            setUi('hidden', hidden.isEmpty ? null : hidden.toList());
          }),

        const SizedBox(height: 24),
        EditorialAction(
          label: 'Reset look & feel',
          muted: true,
          onTap: () {
            for (final k in ['accent', 'textScale', 'headline', 'density', 'swipeActions', 'confirmDeletes', 'celebrate', 'dock', 'hidden']) {
              n.setUi(k, null);
            }
            rebuildAllWidgets(context);
          },
        ),
      ],
    );
  }
}
