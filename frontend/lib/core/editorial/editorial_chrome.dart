import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';
import '../services/sanctuary_supabase_service.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import '../widgets/curator_feedback_dialog.dart';
import '../widgets/focus_dial_modal.dart';
import 'editorial_kit.dart';
import 'editorial_mode.dart';

/// Module names by shell index, as the editorial chrome writes them.
const Map<int, String> editorialModuleNames = {
  0: 'Today',
  1: 'Notes',
  2: 'Tasks',
  3: 'Planner',
  4: 'Wardrobe',
  5: 'Money',
  6: 'Travel',
  7: 'Journal',
  8: 'Moodboard',
  9: 'Habits',
  10: 'Shopping',
  11: 'Settings',
  12: 'Profile',
  13: 'Vault',
  14: 'Bin',
};

IconData editorialModuleIcon(int index) => switch (index) {
      0 => LucideIcons.house,
      1 => LucideIcons.fileText,
      2 => LucideIcons.checkSquare,
      3 => LucideIcons.calendar,
      4 => LucideIcons.shirt,
      5 => LucideIcons.receipt,
      6 => LucideIcons.plane,
      7 => LucideIcons.bookOpen,
      8 => LucideIcons.layoutGrid,
      9 => LucideIcons.flame,
      10 => LucideIcons.shoppingBag,
      11 => LucideIcons.settings,
      12 => LucideIcons.user,
      _ => LucideIcons.layoutGrid,
    };

class EditorialIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;
  final Color? color;

  const EditorialIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final iconColor = color ?? (muted ? ed.muted : ed.ink);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

/// The editorial top line: in-page back arrow, words for Menu, Ask, Search and the
/// view-mode switch, sitting right on the paper with generous breathing room.
class EditorialTopBar extends ConsumerWidget {
  final int activeIndex;
  final VoidCallback onMenu;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onAsk;
  final VoidCallback? onVoice;
  final bool isDark;
  final ValueChanged<bool> onToggleDark;

  /// Wide layouts show the menu inline, so the top line has no Menu word.
  final bool showMenu;

  const EditorialTopBar({
    super.key,
    required this.activeIndex,
    required this.onMenu,
    required this.onBack,
    required this.onSearch,
    required this.onAsk,
    this.onVoice,
    required this.isDark,
    required this.onToggleDark,
    this.showMenu = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    return ColoredBox(
      color: ed.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 12, 0),
        child: Row(
          children: [
            if (activeIndex != 0) ...[
              EditorialAction(label: '←', muted: true, onTap: onBack),
              const SizedBox(width: 16),
            ],
            if (showMenu) EditorialAction(label: 'Menu', muted: true, onTap: onMenu),
            const Spacer(),
            if (onVoice != null) ...[
              EditorialIconButton(icon: LucideIcons.mic, label: 'Voice Memo', onTap: onVoice!),
              const SizedBox(width: 6),
            ],
            EditorialIconButton(icon: LucideIcons.sparkles, label: 'Ask AI', onTap: onAsk, color: ed.accent),
            const SizedBox(width: 12),
            EditorialAction(label: 'Search', muted: true, onTap: onSearch),
            const SizedBox(width: 16),
            Semantics(
              label: 'Switch to ${viewStyleName(otherViewStyle(ref.watch(appSettingsProvider).cardStyle))} view',
              excludeSemantics: true,
              child: EditorialAction(label: 'Aa', muted: true, onTap: () => toggleViewStyle(context, ref)),
            ),
            const SizedBox(width: 16),
            Semantics(
              label: isDark ? 'Switch to light' : 'Switch to dark',
              excludeSemantics: true,
              child: EditorialAction(label: isDark ? '☀' : '☾', muted: true, onTap: () => onToggleDark(!isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The editorial dock: four words and a plus, set on the paper with a soft fade
/// above so text scrolling beneath never collides with it.
class EditorialDock extends ConsumerWidget {
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onMore;

  const EditorialDock({super.key, required this.activeIndex, required this.onSelect, required this.onAdd, required this.onMore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final open = ref.watch(tasksProvider).where((t) => !t.completed).length;
    // The four words are chosen in Settings → Look & feel.
    final items = [
      for (final i in UiPrefs.of(ref.watch(appSettingsProvider)).dock.take(4)) (i, i == 3 ? 'Plan' : editorialModuleNames[i] ?? ''),
    ];
    final inDock = items.any((i) => i.$1 == activeIndex);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ed.paper.withValues(alpha: 0), ed.paper, ed.paper],
          stops: const [0, 0.35, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 12, 6),
          child: Row(
            children: [
              for (final (index, label) in items)
                Expanded(
                  child: _DockWord(
                    icon: editorialModuleIcon(index),
                    label: label,
                    badge: index == 2 && open > 0 ? '$open' : null,
                    selected: activeIndex == index,
                    onTap: () => onSelect(index),
                  ),
                ),
              Expanded(
                child: _DockWord(
                  icon: inDock ? LucideIcons.layoutGrid : editorialModuleIcon(activeIndex),
                  label: inDock ? 'More' : editorialModuleNames[activeIndex] ?? 'More',
                  selected: !inDock,
                  onTap: onMore,
                ),
              ),
              Semantics(
                button: true,
                label: 'Add',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onAdd();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: ed.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(LucideIcons.plus, size: 22, color: ed.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockWord extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _DockWord({
    required this.icon,
    required this.label,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: badge == null ? label : '$label, $badge open',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? ed.accent : ed.muted,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: label),
                    if (badge != null) TextSpan(text: ' $badge', style: TextStyle(color: ed.accent, fontWeight: FontWeight.w600, fontSize: 11)),
                  ]),
                  style: ed.entry.copyWith(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? ed.ink : ed.muted,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedScale(
                duration: Motion.standard,
                curve: Motion.settle,
                scale: selected ? 1 : 0,
                child: SizedBox(width: 4, height: 4, child: DecoratedBox(decoration: BoxDecoration(color: ed.accent, shape: BoxShape.circle))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The editorial menu: the whole app as a contents page set in large serif type.
class EditorialDrawer extends ConsumerWidget {
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final bool isDark;
  final ValueChanged<bool> onToggleDark;
  final VoidCallback onLogout;
  final VoidCallback? onOpenAdmin;

  /// Shown inline beside the page (wide screens) rather than as a sliding drawer.
  final bool embedded;

  const EditorialDrawer({
    super.key,
    required this.activeIndex,
    required this.onSelect,
    required this.isDark,
    required this.onToggleDark,
    required this.onLogout,
    this.onOpenAdmin,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ed = Ed.of(context);
    final settings = ref.watch(appSettingsProvider);
    final signedIn = SanctuarySupabaseService().currentUser != null;
    final name = settings.displayName.trim();
    void close() {
      if (!embedded) Navigator.pop(context);
    }

    final hidden = UiPrefs.of(settings).hiddenModules;
    Widget item(int index, String label, {String? note}) {
      if (hidden.contains(index) && index != activeIndex) return const SizedBox.shrink();
      final selected = index == activeIndex;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            close();
            onSelect(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedDefaultTextStyle(
                  duration: Motion.standard,
                  style: ed.title.copyWith(fontSize: 25, color: selected ? ed.accent : ed.ink, fontStyle: selected ? FontStyle.italic : FontStyle.normal),
                  child: Text(label),
                ),
                if (note != null) ...[const SizedBox(width: 10), Text(note, style: ed.meta)],
              ],
            ),
          ),
        ),
      );
    }

    Widget action(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: EditorialAction(label: label, muted: true, onTap: onTap),
        );

    final open = ref.watch(tasksProvider).where((t) => !t.completed).length;
    final notes = ref.watch(notesProvider).length;

    return Drawer(
      backgroundColor: ed.paper,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      width: embedded ? 260 : null,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
          children: [
            Text('NOTTEODO', style: ed.label.copyWith(color: ed.accent)),
            const SizedBox(height: 6),
            Text(name.isEmpty ? 'Contents' : name, style: ed.display.copyWith(fontSize: 32)),
            const SizedBox(height: 4),
            Text(signedIn ? 'Backed up to your account.' : 'Saved on this phone only.', style: ed.meta),
            const EditorialSectionLabel('Work'),
            ...[
              item(0, 'Today'),
              item(1, 'Notes', note: notes > 0 ? '$notes' : null),
              item(2, 'Tasks', note: open > 0 ? '$open open' : null),
              item(3, 'Planner'),
            ],
            action('Focus timer', () {
              close();
              FocusDialModal.show(context);
            }),
            const EditorialSectionLabel('Life'),
            item(9, 'Habits'),
            item(7, 'Journal'),
            item(5, 'Money'),
            item(10, 'Shopping'),
            item(4, 'Wardrobe'),
            item(6, 'Travel'),
            item(8, 'Moodboard'),
            const EditorialSectionLabel('You'),
            item(12, 'Profile'),
            item(13, 'Vault'),
            item(14, 'Bin'),
            item(11, 'Settings'),
            const SizedBox(height: 20),
            action('${viewStyleName(otherViewStyle(settings.cardStyle))} view', () {
              close();
              toggleViewStyle(context, ref);
            }),
            action(isDark ? 'Light pages' : 'Dark pages', () => onToggleDark(!isDark)),
            action('Send feedback', () {
              close();
              CuratorFeedbackDialog.show(context);
            }),
            if (onOpenAdmin != null) action('Admin', () {
              close();
              onOpenAdmin!();
            }),
            action(signedIn ? 'Sign out' : 'Sign in to back up', () {
              close();
              onLogout();
            }),
          ],
        ),
      ),
    );
  }
}

/// A compact "Aa" button for the card view's header that switches to the editorial
/// view (and back), so the choice is never more than one tap away.
class ViewStyleToggle extends ConsumerWidget {
  const ViewStyleToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appSettingsProvider.select((s) => s.cardStyle));
    final ed = Ed.of(context);
    return Tooltip(
      message: 'Switch to ${viewStyleName(otherViewStyle(style))} view',
      child: Semantics(
        button: true,
        label: 'Switch to ${viewStyleName(otherViewStyle(style))} view',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => toggleViewStyle(context, ref),
          child: SizedBox(
            width: 40,
            height: 36,
            child: Center(
              child: Text('Aa', style: ed.entry.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: ed.ink)),
            ),
          ),
        ),
      ),
    );
  }
}
