import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/editorial/editorial_kit.dart';
import '../../../core/services/cloudinary_media_service.dart';
import '../../../core/services/device_media_service.dart';
import '../../../core/services/sanctuary_supabase_service.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/entry_editor.dart';

/// The moodboard as a picture essay: each pin is its image with a caption beneath,
/// gathered into boards. Hold a pin to move it to a board or attach its source link.
class MoodboardEditorialView extends ConsumerStatefulWidget {
  const MoodboardEditorialView({super.key});

  @override
  ConsumerState<MoodboardEditorialView> createState() => _MoodboardEditorialViewState();
}

class _MoodboardEditorialViewState extends ConsumerState<MoodboardEditorialView> {
  String _board = 'All';

  MoodboardNotifier get _pins => ref.read(moodboardProvider.notifier);

  Future<void> _addFromPhotos() async {
    final media = await DeviceMediaService().pickImage();
    if (media == null || !mounted) return;
    final title = await showEditorialPrompt(context, title: 'Name this pin', hint: 'e.g. Autumn palette');
    if (title == null || !mounted) return;
    final board = _board == 'All' || _board == 'Unsorted' ? '' : _board;
    final pin = _pins.addPin(title: title.isEmpty ? 'Inspiration' : title, imageUrl: media.path);
    if (board.isNotEmpty) _pins.moveToBoard(pin.id, board);

    // Signed-in users get a cloud copy so the pin shows on their other devices.
    if (media.bytes != null && SanctuarySupabaseService().isConnectedToCloud) {
      unawaited(() async {
        try {
          final res = await CloudinaryMediaService().uploadBytes(
            bytes: media.bytes!,
            filename: media.name.isNotEmpty ? media.name : 'pin_${pin.id}.jpg',
            category: 'moodboard',
          );
          if (res != null && res.secureUrl.isNotEmpty) _pins.updatePin(pin.id, imageUrl: res.secureUrl);
        } catch (_) {}
      }());
    }
  }

  Future<void> _moveTo(MoodboardPin p, List<String> boards) async {
    final name = await showEditorialPrompt(
      context,
      title: 'Move to board',
      hint: boards.isEmpty ? 'New board name' : 'e.g. ${boards.first}',
      initial: p.board,
      confirmLabel: 'Move',
    );
    if (name != null) _pins.moveToBoard(p.id, name);
  }

  Future<void> _setLink(MoodboardPin p) async {
    final link = await showEditorialPrompt(context, title: 'Source link', hint: 'https://', initial: p.link, keyboard: TextInputType.url);
    if (link != null) _pins.setLink(p.id, link);
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final pins = ref.watch(moodboardProvider);
    final boards = {for (final p in pins) if (p.board.trim().isNotEmpty) p.board.trim()}.toList()..sort();
    final tabs = ['All', ...boards, if (boards.isNotEmpty && pins.any((p) => p.board.trim().isEmpty)) 'Unsorted'];
    if (!tabs.contains(_board)) _board = 'All';
    final shown = pins.where((p) => _board == 'All' || p.boardLabel == _board).toList();

    return EditorialPage(
      kicker: 'Moodboard',
      title: _board == 'All' ? 'Inspiration' : _board,
      standfirst: pins.isEmpty ? 'Images worth keeping.' : '${shown.length} ${shown.length == 1 ? 'pin' : 'pins'}.',
      actionLabel: 'Add',
      onAction: _addFromPhotos,
      slivers: [
        if (tabs.length > 1) SliverToBoxAdapter(child: EditorialTabs(options: tabs, selected: _board, onSelected: (b) => setState(() => _board = b))),
        if (pins.isEmpty)
          SliverToBoxAdapter(
            child: EditorialEmpty(
              title: 'Nothing pinned.',
              message: 'Add a photo. Hold a pin to put it on a board or keep the link it came from.',
              actionLabel: 'Add from photos  →',
              onAction: _addFromPhotos,
            ),
          ),
        SliverList.builder(
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final p = shown[i];
            return Semantics(
              label: '${p.title}. ${p.note}',
              customSemanticsActions: {const CustomSemanticsAction(label: 'More options'): () => _menu(p, boards)},
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => _menu(p, boards),
                onTap: p.link.isEmpty ? null : () => launchUrl(Uri.parse(p.link), mode: LaunchMode.externalApplication),
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.imageUrl.isNotEmpty) EditorialImage(p.imageUrl, semanticLabel: p.title),
                      const SizedBox(height: 12),
                      Text(p.title, style: ed.title.copyWith(fontSize: 21)),
                      if (p.note.isNotEmpty && p.note != 'Added from photos') ...[
                        const SizedBox(height: 4),
                        Text(p.note, style: ed.body.copyWith(color: ed.muted, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 4),
                      Text([if (_board == 'All') p.boardLabel, p.date, if (p.link.isNotEmpty) 'source ↗'].join('  ·  '), style: ed.meta),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _menu(MoodboardPin p, List<String> boards) {
    showEditorialMenu(context, title: p.title, subtitle: p.boardLabel, items: [
      EditorialMenuItem('Move to board…', () => _moveTo(p, boards)),
      for (final b in boards.where((b) => b != p.board.trim()).take(4)) EditorialMenuItem('Move to $b', () => _pins.moveToBoard(p.id, b)),
      EditorialMenuItem(p.link.isEmpty ? 'Add source link' : 'Change source link', () => _setLink(p)),
      EditorialMenuItem('Edit', () => openEntryEditor(context, EntryKind.pin, editing: p)),
      EditorialMenuItem('Delete', () => _pins.deletePin(p.id), destructive: true),
    ]);
  }
}
