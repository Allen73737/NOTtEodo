import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditorialFlippableImage(
                      pin: p,
                      onLongPress: () => _menu(p, boards),
                    ),
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

/// A 3D flippable photo in the editorial view: tap flips to reveal handwritten notes and source details.
class EditorialFlippableImage extends StatefulWidget {
  final MoodboardPin pin;
  final VoidCallback onLongPress;

  const EditorialFlippableImage({super.key, required this.pin, required this.onLongPress});

  @override
  State<EditorialFlippableImage> createState() => _EditorialFlippableImageState();
}

class _EditorialFlippableImageState extends State<EditorialFlippableImage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final ed = Ed.of(context);
    final p = widget.pin;

    return GestureDetector(
      onTap: _flip,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isUnder = angle > math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(ed, p),
                  )
                : _buildFront(ed, p),
          );
        },
      ),
    );
  }

  Widget _buildFront(Ed ed, MoodboardPin p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: EditorialImage(p.imageUrl, semanticLabel: p.title),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tap photo to flip note ↻', style: ed.meta.copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
            if (p.link.isNotEmpty)
              Text('source ↗', style: ed.meta.copyWith(fontSize: 12, color: ed.accent)),
          ],
        ),
      ],
    );
  }

  Widget _buildBack(Ed ed, MoodboardPin p) {
    final hasNote = p.note.isNotEmpty && p.note != 'Added from photos';
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ed.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ed.faint.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.boardLabel.toUpperCase(), style: ed.meta.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold, color: ed.accent)),
                  Text(p.date, style: ed.meta),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                hasNote ? p.note : 'No handwritten note recorded. Hold this pin to edit or add reflections.',
                style: ed.body.copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (p.link.isNotEmpty) ...[
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(p.link), mode: LaunchMode.externalApplication),
                  child: Text('Visit Source: ${p.link}', style: ed.meta.copyWith(color: ed.accent, decoration: TextDecoration.underline)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.bottomRight,
            child: Text('Tap to return ↺', style: ed.meta.copyWith(color: ed.muted, fontStyle: FontStyle.italic, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
