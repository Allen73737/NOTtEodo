import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/motion/motion.dart';
import '../../../core/services/device_media_service.dart';
import '../../../core/services/note_rag_service.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/fast_typewriter_text.dart';

/// Opens the dedicated Note RAG AI Assistant modal.
/// Can be invoked with a single note or a collection of grouped notes.
Future<void> showNotesRagModal(
  BuildContext context, {
  required List<NoteItem> notes,
  String? initialQuery,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Note RAG AI',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => NotesRagModal(notes: notes, initialQuery: initialQuery),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class _RagChatMessage {
  final bool isUser;
  String text;
  final DeviceMediaResult? attachedMedia;
  final NoteRagResponse? response;
  final DateTime timestamp;

  _RagChatMessage({
    required this.isUser,
    required this.text,
    this.attachedMedia,
    this.response,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotesRagModal extends ConsumerStatefulWidget {
  final List<NoteItem> notes;
  final String? initialQuery;

  const NotesRagModal({
    super.key,
    required this.notes,
    this.initialQuery,
  });

  @override
  ConsumerState<NotesRagModal> createState() => _NotesRagModalState();
}

class _NotesRagModalState extends ConsumerState<NotesRagModal> {
  late List<NoteItem> _activeNotes;
  final List<_RagChatMessage> _messages = [];
  final TextEditingController _queryCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;
  DeviceMediaResult? _attachedMedia;
  bool _showNotesTray = false;
  static const Color terracotta = Color(0xFFD9725B);
  static const Color gold = terracotta;
  static const Color purple = terracotta;

  @override
  void initState() {
    super.initState();
    _activeNotes = List.from(widget.notes);
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _queryCtrl.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendQuery();
      });
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickMedia(ImageSource source) async {
    final media = await DeviceMediaService().pickImage(source: source);
    if (media != null && mounted) {
      HapticFeedback.selectionClick();
      setState(() => _attachedMedia = media);
    }
  }

  Future<void> _sendQuery([String? predefinedText]) async {
    final text = (predefinedText ?? _queryCtrl.text).trim();
    if (text.isEmpty && _attachedMedia == null) return;
    if (_isLoading) return;

    final mediaToSend = _attachedMedia;

    setState(() {
      _messages.add(_RagChatMessage(
        isUser: true,
        text: text.isNotEmpty ? text : 'Analyze this attached media against selected notes.',
        attachedMedia: mediaToSend,
      ));
      _queryCtrl.clear();
      _attachedMedia = null;
      _isLoading = true;
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      final res = await NoteRagService().queryNotes(
        query: text.isNotEmpty ? text : 'Analyze this attached media and extract relevant details from notes.',
        notes: _activeNotes,
        attachedMedia: mediaToSend,
      );

      if (!mounted) return;
      final fullAnswer = res.answer;
      final aiMessage = _RagChatMessage(
        isUser: false,
        text: '',
        response: res,
      );
      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      _scrollToBottom();
      HapticFeedback.mediumImpact();

      // Token-by-token streaming typewriter
      final words = fullAnswer.split(' ');
      int wordIndex = 0;
      Timer.periodic(const Duration(milliseconds: 25), (streamTimer) {
        if (!mounted || wordIndex >= words.length) {
          streamTimer.cancel();
          if (mounted) {
            setState(() {
              aiMessage.text = fullAnswer;
            });
            _scrollToBottom();
          }
          return;
        }
        wordIndex = (wordIndex + 2).clamp(0, words.length);
        setState(() {
          aiMessage.text = words.sublist(0, wordIndex).join(' ');
        });
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_RagChatMessage(
          isUser: false,
          text: 'RAG Query encountered an issue: $e',
        ));
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    AppToastEngine().showToast(
      context,
      title: 'Copied to Clipboard',
      message: 'RAG AI response copied.',
    );
  }

  void _appendResponseToNote(String noteId, String contentToAppend) {
    final currentNotes = ref.read(notesProvider);
    final idx = currentNotes.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      final oldNote = currentNotes[idx];
      final newContent = '${oldNote.content}\n\n🤖 **RAG AI Analysis**:\n$contentToAppend';
      ref.read(notesProvider.notifier).updateNote(noteId, content: newContent);
      HapticFeedback.selectionClick();
      AppToastEngine().showToast(
        context,
        title: 'Appended to Note',
        message: 'Saved analysis to "${oldNote.title}".',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101216) : Colors.white;
    final cardBg = isDark ? const Color(0xFF171A22) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8);
    final textPrimary = isDark ? const Color(0xFFF5F2EB) : const Color(0xFF1C1917);
    final textSub = isDark ? const Color(0xFFA6A096) : const Color(0xFF635F59);
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    const emerald = Color(0xFFD9725B);
    const gold = Color(0xFFD9725B);

    final isSingleNote = _activeNotes.length == 1;
    final titleLabel = isSingleNote
        ? 'NOTE RAG · ${_activeNotes.first.title}'
        : 'GROUP RAG · ${_activeNotes.length} NOTES INDEXED';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.brain, size: 18, color: gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSingleNote ? 'GROUNDED NOTE INTELLIGENCE' : 'MULTI-NOTE KNOWLEDGE SYNTHESIZER',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                                color: gold,
                              ),
                            ),
                            Text(
                              titleLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isSingleNote)
                        Pressable(
                          pressedScale: 0.95,
                          child: InkWell(
                            onTap: () => setState(() => _showNotesTray = !_showNotesTray),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_showNotesTray ? LucideIcons.chevronUp : LucideIcons.layers, size: 12, color: textSub),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_activeNotes.length} notes',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: textSub),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Group Notes Tray (when toggled or multiple notes active)
                if (_showNotesTray && !isSingleNote) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    color: bg,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _activeNotes.map((n) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.fileText, size: 12, color: gold),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 140),
                                  child: Text(
                                    n.title,
                                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_activeNotes.length > 1)
                                  InkWell(
                                    onTap: () {
                                      setState(() => _activeNotes.removeWhere((x) => x.id == n.id));
                                    },
                                    child: Icon(LucideIcons.x, size: 12, color: textSub),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                Divider(height: 1, color: border),

                // Chat Messages Feed
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(textPrimary, textSub, purple, cardBg, border)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(18),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) {
                            final msg = _messages[i];
                            return _buildMessageBubble(msg, isDark, textPrimary, textSub, cardBg, border, purple, accent, emerald, i == _messages.length - 1);
                          },
                        ),
                ),

                // Loading Indicator
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.6, color: gold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Searching retrieved note passages & synthesizing grounded answer...',
                          style: GoogleFonts.dmSans(fontSize: 12, color: textSub),
                        ),
                      ],
                    ),
                  ),

                // Attached Media Preview Pill
                if (_attachedMedia != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _attachedMedia!.bytes != null
                              ? Image.memory(
                                  _attachedMedia!.bytes!,
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                )
                              : (!kIsWeb && _attachedMedia!.path.isNotEmpty)
                                  ? Image.file(
                                      File(_attachedMedia!.path),
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 24, color: gold),
                                    )
                                  : const Icon(LucideIcons.image, size: 24, color: gold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MEDIA ATTACHED FOR RAG ANALYSIS',
                                style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.bold, color: gold),
                              ),
                              Text(
                                _attachedMedia!.name,
                                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                          onPressed: () => setState(() => _attachedMedia = null),
                        ),
                      ],
                    ),
                  ),

                Divider(height: 1, color: border),

                // Prompt Bar
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Upload Media Menu Button
                      PopupMenuButton<ImageSource>(
                        tooltip: 'Upload Media Mode',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _attachedMedia != null ? purple.withValues(alpha: 0.16) : cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _attachedMedia != null ? purple : border),
                          ),
                          child: Icon(
                            LucideIcons.imagePlus,
                            size: 16,
                            color: _attachedMedia != null ? purple : textSub,
                          ),
                        ),
                        onSelected: _pickMedia,
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: ImageSource.gallery,
                            child: Row(
                              children: [
                                Icon(LucideIcons.image, size: 16),
                                SizedBox(width: 8),
                                Text('Choose from Gallery / Files'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: ImageSource.camera,
                            child: Row(
                              children: [
                                Icon(LucideIcons.camera, size: 16),
                                SizedBox(width: 8),
                                Text('Take Photo with Camera'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),

                      // Query Input Field
                      Expanded(
                        child: TextField(
                          controller: _queryCtrl,
                          style: GoogleFonts.dmSans(fontSize: 13.5, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: isSingleNote
                                ? 'Ask anything about "${_activeNotes.first.title}"...'
                                : 'Ask questions across ${_activeNotes.length} grouped notes...',
                            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textSub.withValues(alpha: 0.6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: gold, width: 1.4),
                            ),
                          ),
                          onSubmitted: (_) => _sendQuery(),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Send Button
                      Pressable(
                        pressedScale: 0.94,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: _isLoading ? null : () => _sendQuery(),
                          child: const Icon(LucideIcons.send, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSub, Color purple, Color cardBg, Color border) {
    final suggested = [
      'Summarize key takeaways & action items',
      'What are the core risks or blind spots mentioned?',
      'Extract all financial numbers or deadlines',
      if (_activeNotes.length > 1) 'Compare and contrast differences between these notes',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.brain, size: 32, color: gold),
            ),
            const SizedBox(height: 14),
            Text(
              'Grounded Note RAG Assistant',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                'Ask questions strictly answered from your note passages. Attach media (receipts, diagrams, photos) to analyze alongside the text.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 13, color: textSub, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggested.map((prompt) {
                return Pressable(
                  pressedScale: 0.95,
                  child: InkWell(
                    onTap: () => _sendQuery(prompt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sparkles, size: 12, color: gold),
                          const SizedBox(width: 8),
                          Text(
                            prompt,
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    _RagChatMessage msg,
    bool isDark,
    Color textPrimary,
    Color textSub,
    Color cardBg,
    Color border,
    Color purple,
    Color accent,
    Color emerald,
    bool isLatest,
  ) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(14).copyWith(bottomRight: Radius.zero),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.attachedMedia != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.paperclip, size: 12, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        msg.attachedMedia!.name,
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                msg.text,
                style: GoogleFonts.dmSans(fontSize: 13.5, color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    // AI Message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header Badge
            Row(
              children: [
                const Icon(LucideIcons.brain, size: 14, color: gold),
                const SizedBox(width: 6),
                Text(
                  msg.response?.modelUsed ?? 'NOTtEodo Note RAG AI',
                  style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.bold, color: gold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy Answer',
                  icon: const Icon(LucideIcons.copy, size: 13),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyToClipboard(msg.text),
                ),
                if (_activeNotes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Append to first note',
                    icon: const Icon(LucideIcons.filePlus2, size: 13),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _appendResponseToNote(_activeNotes.first.id, msg.text),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // AI Answer Body with Fast Typewriter
            FastTypewriterText(
              text: msg.text,
              autoStart: isLatest,
              style: GoogleFonts.dmSans(fontSize: 13.5, color: textPrimary, height: 1.5),
            ),

            // Citations & Retrieved Sources
            if (msg.response != null && msg.response!.citedNotes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101216) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.quote, size: 11, color: textSub),
                        const SizedBox(width: 6),
                        Text(
                          'GROUNDED CITATIONS (${msg.response!.citedNotes.length})',
                          style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: textSub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: msg.response!.citedNotes.map((title) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: gold.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.fileText, size: 10, color: gold),
                              const SizedBox(width: 5),
                              Text(
                                title,
                                style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.bold, color: gold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
