import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../services/local_knowledge_index.dart';
import '../services/sanctuary_supabase_service.dart';
import '../state/sanctuary_state.dart';
import 'sanctuary_loaders.dart';
import '../motion/motion.dart';

class _Message {
  final bool fromAssistant;
  final String text;
  final List<String> sources;
  final bool isNotice;

  const _Message(this.fromAssistant, this.text, {this.sources = const [], this.isNotice = false});
}

/// Ask questions about your own items. Answers come from the `scoped-ai` server function
/// when signed in; otherwise the closest matching items are listed.
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
      SanctuarySupabaseService().isConnectedToCloud
          ? 'Ask anything about ${_scopeLabel()}. I answer from your own notes, tasks, events and trips.'
          : 'Ask about ${_scopeLabel()} and I will find the most relevant items you have saved. '
              'Sign in to a cloud account for written AI answers.',
      isNotice: true,
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
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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
    final sources = matches.map((m) => '${m.kind}: ${m.title}').toList();

    _Message reply;
    final cloud = SanctuarySupabaseService();
    if (cloud.isConnectedToCloud) {
      try {
        final res = await cloud.askAi(
          query: text,
          scope: widget.contextScope,
          context: matches.map((m) => m.digest).join('\n\n'),
        );
        reply = _Message(true, res.answer, sources: sources);
      } catch (e) {
        final reason = e.toString().replaceFirst('Bad state: ', '');
        reply = _Message(true, _localAnswer(matches, prefix: '$reason\n\n'), sources: sources, isNotice: true);
      }
    } else {
      reply = _Message(true, _localAnswer(matches), sources: sources, isNotice: true);
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
    final lines = matches.take(4).map((m) => 'â€¢ ${m.kind} â€” ${m.title}: ${m.snippet.split('\n').last}');
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
              constraints: const BoxConstraints(maxWidth: 560),
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
                              'ASK Â· ${widget.contextScope.toUpperCase()}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.2),
                            ),
                          ),
                          IconButton(tooltip: 'Close', icon: Icon(LucideIcons.x, size: 18, color: text), onPressed: widget.onClose),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF080808) : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
                        ),
                        child: ListView.separated(
                          controller: _scroll,
                          itemCount: _messages.length + (_isThinking ? 1 : 0),
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            if (i == _messages.length) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                  child: const InkDotsLoader(dotSize: 6),
                                ),
                              );
                            }
                            final msg = _messages[i];
                            return Reveal(
                              style: RevealStyle.slideIn,
                              distance: 18,
                              child: Column(
                                crossAxisAlignment: msg.fromAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 440),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: msg.fromAssistant
                                          ? (msg.isNotice ? AppColors.primary.withValues(alpha: 0.85) : AppColors.primary)
                                          : AppColors.secondary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SelectableText(msg.text,
                                        style: GoogleFonts.dmSans(fontSize: 12.5, color: Colors.white, height: 1.45)),
                                  ),
                                  if (msg.sources.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Sources: ${msg.sources.take(4).join(' Â· ')}',
                                        style: GoogleFonts.dmSans(fontSize: 9.5, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _queryCtrl,
                              autofocus: true,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: 'Ask about ${widget.contextScope == 'Global' ? 'your items' : widget.contextScope}â€¦',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1E3236) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
