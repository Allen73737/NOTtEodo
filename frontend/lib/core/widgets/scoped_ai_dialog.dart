import 'fast_typewriter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../services/groq_ai_service.dart';
import '../services/local_knowledge_index.dart';
import '../state/sanctuary_state.dart';
import 'sanctuary_loaders.dart';
import '../motion/motion.dart';

class _Message {
  final bool fromAssistant;
  final String text;
  final List<String> sources;
  final bool isNotice;
  final String? modelInfo;

  const _Message(
    this.fromAssistant,
    this.text, {
    this.sources = const [],
    this.isNotice = false,
    this.modelInfo,
  });
}

/// Ask questions about your own items. Powered by Sovereign Groq AI with a 7-step
/// failover cascade, grounded in your local and cloud knowledge base.
class ScopedAiDialog extends ConsumerStatefulWidget {
  final String contextScope;
  final VoidCallback onClose;

  const ScopedAiDialog({
    super.key,
    required this.contextScope,
    required this.onClose,
  });

  @override
  ConsumerState<ScopedAiDialog> createState() => _ScopedAiDialogState();
}

class _ScopedAiDialogState extends ConsumerState<ScopedAiDialog> {
  final TextEditingController _queryCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isThinking = false;
  late final List<_Message> _messages = [
    _Message(
      true,
      'Ask anything about ${_scopeLabel()}. I synthesize your personal notes, tasks, events, expenses, and trips with high-capacity neural reasoning.',
      isNotice: false,
      modelInfo: 'Sovereign AI · 7-Tier Cascade Active',
    ),
  ];

  String _scopeLabel() => widget.contextScope == 'Global' ? 'everything you have saved' : '"${widget.contextScope}"';

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitQuery() async {
    final text = _queryCtrl.text.trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _messages.add(_Message(false, text));
      _queryCtrl.clear();
      _isThinking = true;
    });
    _scrollToEnd();

    final scopeTerms = widget.contextScope == 'Global' ? '' : ' ${widget.contextScope}';
    final matches = LocalKnowledgeIndex.search(
      '$text$scopeTerms',
      notes: ref.read(notesProvider),
      tasks: ref.read(tasksProvider),
      events: ref.read(eventsProvider),
      trips: ref.read(travelProvider),
      journal: ref.read(journalProvider),
      expenses: ref.read(expensesProvider).expenses,
    );
    final fallbackSources = matches.map((m) => '${m.kind}: ${m.title}').toList();

    _Message reply;
    try {
      final aiRes = await GroqAiService().ask(
        query: text,
        scope: widget.contextScope,
        matches: matches,
      );

      final badge = aiRes.isOfflineFallback ? 'On-device answer' : aiRes.modelUsed;

      reply = _Message(
        true,
        aiRes.answer,
        sources: aiRes.sources.isNotEmpty ? aiRes.sources : fallbackSources,
        isNotice: aiRes.isOfflineFallback,
        modelInfo: badge,
      );
    } catch (e) {
      reply = _Message(
        true,
        _localAnswer(matches, prefix: '$e\n\n'),
        sources: fallbackSources,
        isNotice: true,
        modelInfo: 'Offline Knowledge Base',
      );
    }

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _messages.add(reply);
    });
    _scrollToEnd();
  }

  static String _localAnswer(List<KnowledgeMatch> matches, {String prefix = ''}) {
    if (matches.isEmpty) return '${prefix}Nothing you have saved matches that yet. Try different words.';
    final lines = matches.take(4).map((m) => '• ${m.kind} — ${m.title}: ${m.snippet.split('\n').last}');
    return '${prefix}Closest matches in your items:\n${lines.join('\n')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;

    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Material(
                color: isDark ? const Color(0xFF000000) : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.sparkles, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SOVEREIGN AI · ${widget.contextScope.toUpperCase()}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: Icon(LucideIcons.x, size: 18, color: text),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 320,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF080808) : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
                        ),
                        child: ListView.separated(
                          controller: _scroll,
                          itemCount: _messages.length + (_isThinking ? 1 : 0),
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            if (i == _messages.length) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const InkDotsLoader(dotSize: 6),
                                ),
                              );
                            }
                            final msg = _messages[i];
                            return Reveal(
                              style: RevealStyle.slideIn,
                              distance: 18,
                              child: Column(
                                crossAxisAlignment:
                                    msg.fromAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 460),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: msg.fromAssistant
                                          ? (msg.isNotice ? AppColors.primary.withValues(alpha: 0.85) : AppColors.primary)
                                          : AppColors.secondary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: msg.fromAssistant
                                        ? FastTypewriterText(
                                            text: msg.text,
                                            autoStart: i == _messages.length - 1,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              color: Colors.white,
                                              height: 1.45,
                                            ),
                                          )
                                        : SelectableText(
                                            msg.text,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12.5,
                                              color: Colors.white,
                                              height: 1.45,
                                            ),
                                          ),
                                  ),
                                  if (msg.modelInfo != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.sparkles, size: 10, color: isDark ? AppColors.goldLight : AppColors.secondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          msg.modelInfo!,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.goldLight : AppColors.secondary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (msg.sources.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Sources: ${msg.sources.take(4).join(' · ')}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9.5,
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick AI Inquiry Suggestion Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Summarize today\'s agenda',
                            'Where did I spend the most?',
                            'Suggest an outfit for today',
                            'High-priority tasks due',
                          ].map((prompt) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  prompt,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: text,
                                  ),
                                ),
                                backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E3D8),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onPressed: _isThinking
                                    ? null
                                    : () {
                                        _queryCtrl.text = prompt;
                                        _submitQuery();
                                      },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _queryCtrl,
                              autofocus: true,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText:
                                    'Ask about ${widget.contextScope == 'Global' ? 'your items' : widget.contextScope}…',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF121212) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _submitQuery(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Send',
                            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                            onPressed: _isThinking ? null : _submitQuery,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
