import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'aesthetic_widget_models.dart';
import 'homescreen_fast_data_cache.dart';

/// The editorial version of a home-screen widget: type on the paper colour, no tape,
/// stamps, borders or boxes. A small-caps kicker, one large figure or headline, and a
/// few lines beneath. Rendered to an image for the phone's home screen.
class EditorialHomeWidget extends StatelessWidget {
  final AestheticWidgetConfig config;

  const EditorialHomeWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final paper = config.paperTheme.backgroundColor;
    final dark = paper.computeLuminance() < 0.35;
    final ink = dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917);
    final muted = dark ? const Color(0xFFB4ADA2) : const Color(0xFF6B635A);
    final accent = dark ? const Color(0xFFE8927C) : const Color(0xFFAD4E38);
    final compact = config.size == WidgetGridSize.compact;
    final cache = HomescreenFastDataCache();
    final now = DateTime.now();

    TextStyle kicker() => GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: accent);
    TextStyle headline(double size) => GoogleFonts.bodoniModa(fontSize: size, height: 1.05, fontWeight: FontWeight.w600, color: ink);
    TextStyle line([double size = 12.5]) => GoogleFonts.dmSans(fontSize: size, height: 1.35, color: ink);
    TextStyle meta() => GoogleFonts.dmSans(fontSize: 11, height: 1.3, color: muted);

    String title(String fallback) => (config.customTitle?.trim().isNotEmpty ?? false) ? config.customTitle!.trim() : fallback;

    final List<Widget> body;
    switch (config.type) {
      case AestheticWidgetType.ritualChecklist:
        final r = cache.rituals;
        final tasks = r?.topTasks ?? const <WidgetTaskItem>[];
        body = [
          Text(DateFormat('EEEE d').format(now).toUpperCase(), style: kicker()),
          const SizedBox(height: 4),
          Text(title(tasks.isEmpty ? 'A clear day.' : 'Today'), style: headline(compact ? 22 : 26)),
          const SizedBox(height: 8),
          for (final t in tasks.take(compact ? 3 : 5))
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('${t.isCompleted ? '●' : '○'}  ${t.title}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: line().copyWith(color: t.isCompleted ? muted : ink)),
            ),
          const Spacer(),
          if (r != null) Text('${r.habitsCompletedToday} of ${r.totalHabits} habits  ·  ${r.streakDays}-day streak', style: meta()),
        ];
      case AestheticWidgetType.stickyNote:
        final n = cache.note;
        body = [
          Text((n?.tag ?? 'NOTE').toUpperCase(), style: kicker()),
          const SizedBox(height: 4),
          Text(title(n?.title ?? 'Nothing written yet'), maxLines: 2, overflow: TextOverflow.ellipsis, style: headline(compact ? 20 : 24)),
          const SizedBox(height: 8),
          Expanded(child: Text(n?.content ?? 'Open NOTtEodo to write.', overflow: TextOverflow.fade, style: line(12))),
        ];
      case AestheticWidgetType.vaultTreasury:
        final t = cache.treasury;
        final spent = t?.monthlySpent ?? 0;
        final budget = t?.monthlyBudget ?? 0;
        final fmt = NumberFormat.decimalPatternDigits(decimalDigits: 0);
        body = [
          Text(DateFormat('MMMM').format(now).toUpperCase(), style: kicker()),
          const Spacer(),
          Text('${t?.currency ?? '₹'}${fmt.format(spent)}', style: headline(compact ? 30 : 38)),
          Text(budget > 0 ? 'of ${t?.currency ?? '₹'}${fmt.format(budget)} spent' : 'spent this month', style: meta()),
          if (budget > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LayoutBuilder(
                builder: (_, c) => Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: c.maxWidth * (spent / budget).clamp(0.0, 1.0), height: 2, child: ColoredBox(color: spent > budget ? accent : ink)),
                ),
              ),
            ),
          const Spacer(),
          if (t != null && t.latestMerchant.isNotEmpty) Text('Last: ${t.latestMerchant}', maxLines: 1, overflow: TextOverflow.ellipsis, style: meta()),
        ];
      case AestheticWidgetType.moodboardPolaroid:
        final m = cache.moodboard;
        body = [
          Text((m?.tag ?? 'MOODBOARD').toUpperCase(), style: kicker()),
          const Spacer(),
          Text(title(m?.title ?? 'Pin something'), maxLines: 2, overflow: TextOverflow.ellipsis, style: headline(compact ? 22 : 28).copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          if (m != null) Text(m.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: meta()),
        ];
      case AestheticWidgetType.atelierOotd:
        final w = cache.wardrobe;
        body = [
          Text('TODAY’S OUTFIT', style: kicker()),
          const Spacer(),
          Text(title(w?.title ?? 'Choose an outfit'), maxLines: 2, overflow: TextOverflow.ellipsis, style: headline(compact ? 22 : 28)),
          const SizedBox(height: 6),
          if (w != null) Text('${w.occasion}  ·  ${w.vibe}', maxLines: 2, overflow: TextOverflow.ellipsis, style: meta()),
        ];
      case AestheticWidgetType.voiceMemoir:
        final v = cache.voice;
        body = [
          Text('LATEST VOICE NOTE', style: kicker()),
          const Spacer(),
          Text(title(v?.title ?? 'Record a thought'), maxLines: 2, overflow: TextOverflow.ellipsis, style: headline(compact ? 22 : 26)),
          const SizedBox(height: 6),
          if (v != null) Text('${v.duration}  ·  ${DateFormat('d MMM').format(v.recordedAt)}', style: meta()),
        ];
      case AestheticWidgetType.airmailTravel:
        final t = cache.travel;
        body = [
          Text((t?.status ?? 'NEXT TRIP').toUpperCase(), style: kicker()),
          const Spacer(),
          Text(title(t?.destination ?? 'Somewhere new'), maxLines: 2, overflow: TextOverflow.ellipsis, style: headline(compact ? 24 : 30)),
          const SizedBox(height: 6),
          if (t != null) Text(t.countdown, style: line(13).copyWith(color: accent, fontWeight: FontWeight.w600)),
        ];
      case AestheticWidgetType.horologyClock:
        final h = cache.horology;
        body = [
          Text(DateFormat('EEEE d MMMM').format(now).toUpperCase(), style: kicker()),
          const SizedBox(height: 4),
          Text(DateFormat('HH:mm').format(now), style: headline(compact ? 40 : 52)),
          const Spacer(),
          Text('“${h?.quote ?? 'Make today deliberate.'}”', maxLines: compact ? 3 : 4, overflow: TextOverflow.ellipsis, style: line(12).copyWith(fontStyle: FontStyle.italic)),
          if (h != null && h.author.isNotEmpty) Text(h.author, style: meta()),
        ];
    }

    return SizedBox(
      width: config.size.width,
      height: config.size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ColoredBox(
          color: paper,
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: DefaultTextStyle(
              style: line(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
            ),
          ),
        ),
      ),
    );
  }
}
