import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ai/user_memory_profile.dart';
import '../motion/motion.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../services/companion_memory_service.dart';
import '../services/groq_ai_service.dart';
import '../services/local_knowledge_index.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'card_kit.dart';
import 'fast_typewriter_text.dart';
import 'nodo_avatar_widget.dart';
import 'sanctuary_loaders.dart';
import '../rewards/reward_bus.dart';

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

/// Personal AI Companion "Nodo" with active sanctuary memory, dynamic emotion expressions,
/// witty/sarcastic personas, chat clearing, and fullscreen expansion.
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
  bool _isFullscreen = false;
  NodoEmotion _currentEmotion = NodoEmotion.neutral;
  final List<_Message> _messages = [];

  String _scopeLabel() => widget.contextScope == 'Global' ? 'everything you have saved' : '"${widget.contextScope}"';

  @override
  void initState() {
    super.initState();
    _initGreeting();
  }

  void _initGreeting() {
    final settings = ref.read(appSettingsProvider);
    final persona = settings.aiPersona;
    final name = settings.displayName.trim().isNotEmpty ? settings.displayName.trim() : 'Curator';

    if (persona == 'sarcastic') {
      _currentEmotion = NodoEmotion.sarcastic;
      _messages.add(_Message(
        true,
        'Greetings, $name. I am Nodo—your digital conscience and sanctuary companion. Ask me anything about ${_scopeLabel()}, or whatever high-priority tasks you might be actively dodging right now.',
        isNotice: false,
        modelInfo: 'Nodo AI · Persona: Witty & Sarcastic',
      ));
    } else if (persona == 'scholarly') {
      _currentEmotion = NodoEmotion.neutral;
      _messages.add(_Message(
        true,
        'Welcome, $name. I am Nodo, your reflective sanctuary intelligence. How may I synthesize your notes and thoughts regarding ${_scopeLabel()} today?',
        isNotice: false,
        modelInfo: 'Nodo AI · Persona: Scholarly',
      ));
    } else if (persona == 'stoic') {
      _currentEmotion = NodoEmotion.neutral;
      _messages.add(_Message(
        true,
        'Nodo online for $name. Inquiries regarding ${_scopeLabel()} ready. State your objective.',
        isNotice: false,
        modelInfo: 'Nodo AI · Persona: Stoic',
      ));
    } else {
      _currentEmotion = NodoEmotion.neutral;
      _messages.add(_Message(
        true,
        'Hey $name! I am Nodo, your sanctuary companion! Ready to dive into ${_scopeLabel()} and tackle today with high energy!',
        isNotice: false,
        modelInfo: 'Nodo AI · Memory Active',
      ));
    }
  }

  void _clearChat() {
    SanctuaryHapticEngine.sealImpression();
    CompanionMemoryService().clearHistory();
    setState(() {
      _messages.clear();
      _initGreeting();
    });
  }

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

    // 1. Extract and learn facts / names in real time into long-term memory
    final learnedFact = CompanionMemoryService().extractAndLearnFromMessage(text, ref);

    final settings = ref.read(appSettingsProvider);
    final persona = settings.aiPersona;

    // Gather active sanctuary ground-truth memory
    final memory = UserMemoryProfile.fromState(
      notes: ref.read(notesProvider),
      tasks: ref.read(tasksProvider),
      events: ref.read(eventsProvider),
      expenses: ref.read(expensesProvider).expenses,
      journal: ref.read(journalProvider),
      habits: ref.read(habitsProvider),
      wardrobe: ref.read(wardrobeProvider),
      settings: settings,
    );

    setState(() {
      _messages.add(_Message(false, text));
      _queryCtrl.clear();
      _isThinking = true;
      _currentEmotion = NodoEmotion.thinking;
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
    final history = CompanionMemoryService().getHistory();

    _Message reply;
    try {
      final aiRes = await GroqAiService().ask(
        query: text,
        scope: widget.contextScope,
        matches: matches,
        systemPrompt: memory.toSystemMemoryPrompt(),
        history: history,
      );

      String answerText = aiRes.answer;
      // If offline fallback returned generic message, replace with smart companion response
      if (aiRes.isOfflineFallback && (matches.isEmpty || answerText.contains('Sign in to use the cloud AI'))) {
        answerText = memory.generateSmartLocalAnswer(text);
      }

      // Check for executable action tags: [ACTION: CREATE_TASK: {...}], [ACTION: ADD_EXPENSE: {...}], [ACTION: CREATE_NOTE: {...}]
      final actionMatch = RegExp(r'\[ACTION:\s*([A-Z_]+):\s*(\{.*?\})\]').firstMatch(answerText);
      if (actionMatch != null) {
        final actionType = actionMatch.group(1);
        final actionPayload = actionMatch.group(2);
        try {
          final data = jsonDecode(actionPayload!) as Map<String, dynamic>;
          if (actionType == 'CREATE_TASK') {
            final title = data['title']?.toString() ?? 'New Task';
            final priority = data['priority']?.toString() ?? 'normal';
            RewardBus.quietly(() => ref.read(tasksProvider.notifier).addTask(title: title, priority: priority));
            answerText = '$answerText\n\n✓ Conquered: Task "$title" added to your list.';
          } else if (actionType == 'ADD_EXPENSE') {
            final title = data['title']?.toString() ?? 'Disbursement';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final category = data['category']?.toString() ?? 'General';
            RewardBus.quietly(() => ref.read(expensesProvider.notifier).addExpense(title: title, amount: amount, category: category));
            answerText = '$answerText\n\n✓ Logged: Expense "$title" (${settings.currencySymbol}${amount.toStringAsFixed(0)}) in $category.';
          } else if (actionType == 'CREATE_NOTE') {
            final title = data['title']?.toString() ?? 'Note';
            final content = data['content']?.toString() ?? '';
            RewardBus.quietly(() => ref.read(notesProvider.notifier).addNote(
                  title: title,
                  excerpt: content,
                  space: 'General Space',
                  tag: 'AI Note',
                ));
            answerText = '$answerText\n\n✓ Preserved: Note "$title" saved in your vault.';
          }
        } catch (_) {}
        answerText = answerText.replaceAll(actionMatch.group(0)!, '').trim();
      }

      // If a fact was learned from this message, append confirmation
      if (learnedFact != null && !answerText.toLowerCase().contains('remember')) {
        answerText = '$answerText\n\n*(🧠 $learnedFact)*';
      }

      final badge = aiRes.isOfflineFallback ? 'Nodo On-device Intelligence' : aiRes.modelUsed;

      reply = _Message(
        true,
        answerText,
        sources: aiRes.sources.isNotEmpty ? aiRes.sources : fallbackSources,
        isNotice: aiRes.isOfflineFallback,
        modelInfo: badge,
      );

      // Record in multi-turn persistent conversation buffer
      CompanionMemoryService().appendExchange(text, answerText);
    } catch (_) {
      String localAnswer = memory.generateSmartLocalAnswer(text);
      if (learnedFact != null) {
        localAnswer = '$localAnswer\n\n*(🧠 $learnedFact)*';
      }
      reply = _Message(
        true,
        localAnswer,
        sources: fallbackSources,
        isNotice: true,
        modelInfo: 'Nodo On-Device Intelligence',
      );
      CompanionMemoryService().appendExchange(text, localAnswer);
    }

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _messages.add(reply);

      // Emotion reaction
      final lowerText = text.toLowerCase();
      if (lowerText.contains('congrat') || lowerText.contains('done') || lowerText.contains('yay') || lowerText.contains('completed')) {
        _currentEmotion = NodoEmotion.celebrating;
      } else if (persona == 'sarcastic') {
        _currentEmotion = NodoEmotion.sarcastic;
      } else {
        _currentEmotion = NodoEmotion.neutral;
      }
    });
    _scrollToEnd();
  }

  static const _suggestions = [
    'Summarize today\'s agenda',
    'Where did I spend the most?',
    'Suggest an outfit for today',
    'High-priority tasks due',
    'Who are you?',
  ];

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final settings = ref.watch(appSettingsProvider);
    final personaLabel = switch (settings.aiPersona) {
      'sarcastic' => 'Sarcastic',
      'scholarly' => 'Scholarly',
      'stoic' => 'Stoic',
      _ => 'Energetic',
    };
    final surface = c.dark ? const Color(0xFF0F0D0D) : Colors.white;
    final radius = BorderRadius.circular(_isFullscreen ? 0 : 28);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Motion.silk,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        boxShadow: _isFullscreen
            ? null
            : [
                BoxShadow(color: Colors.black.withValues(alpha: c.dark ? 0.6 : 0.10), blurRadius: 40, offset: const Offset(0, 18)),
                BoxShadow(color: Colors.black.withValues(alpha: c.dark ? 0.3 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: _isFullscreen,
          bottom: _isFullscreen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
            child: Column(
              mainAxisSize: _isFullscreen ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nodo, its persona and what it can see, then quiet window controls.
                Row(
                  children: [
                    NodoAvatarWidget(
                      size: 36,
                      emotion: _currentEmotion,
                      isInteractive: true,
                      onTap: () {
                        SanctuaryHapticEngine.sealImpression();
                        setState(() {
                          _currentEmotion = _currentEmotion == NodoEmotion.sarcastic ? NodoEmotion.celebrating : NodoEmotion.sarcastic;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nodo', style: GoogleFonts.bodoniModa(fontSize: 23, fontWeight: FontWeight.bold, color: c.ink, height: 1.1)),
                          Text(
                            '$personaLabel · ${widget.contextScope == 'Global' ? 'Everything you have saved' : widget.contextScope}',
                            style: c.meta.copyWith(fontSize: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _HeaderIcon(icon: LucideIcons.rotateCcw, tooltip: 'Clear chat', onTap: _clearChat),
                    _HeaderIcon(
                      icon: _isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                      tooltip: _isFullscreen ? 'Shrink to window' : 'Expand full window',
                      onTap: () {
                        SanctuaryHapticEngine.sealImpression();
                        setState(() => _isFullscreen = !_isFullscreen);
                      },
                    ),
                    _HeaderIcon(icon: LucideIcons.x, tooltip: 'Close', onTap: widget.onClose, strong: true),
                  ],
                ),
                const SizedBox(height: 14),

                // The conversation: Nodo writes on the page; your messages sit in oxblood.
                Expanded(
                  flex: _isFullscreen ? 1 : 0,
                  child: SizedBox(
                    height: _isFullscreen ? null : 340,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _messages.length + (_isThinking ? 1 : 0),
                        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          if (i == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: InkDotsLoader(dotSize: 6, colors: [c.mark, c.mark.withValues(alpha: 0.6), c.mark.withValues(alpha: 0.3)]),
                              ),
                            );
                          }
                          final msg = _messages[i];
                          return Reveal(
                            style: RevealStyle.slideIn,
                            distance: 14,
                            child: msg.fromAssistant ? _assistantMessage(c, msg, i) : _userMessage(c, msg),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Things to ask, as soft pills that slide in one after another.
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Reveal(
                      style: RevealStyle.slideIn,
                      distance: 12,
                      child: Pressable(
                        pressedScale: 0.94,
                        hoverLift: 0,
                        enabled: !_isThinking,
                        onTap: () {
                          _queryCtrl.text = _suggestions[i];
                          _submitQuery();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.dark ? const Color(0xFF181414) : const Color(0xFFF4EFE9), borderRadius: BorderRadius.circular(19)),
                          child: Text(_suggestions[i], style: c.meta.copyWith(fontSize: 13, color: c.ink, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // The question field. The send button fills with oxblood once there is
                // something to send.
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _queryCtrl,
                    builder: (context, value, _) {
                      final ready = value.text.trim().isNotEmpty && !_isThinking;
                      return TextField(
                        controller: _queryCtrl,
                        autofocus: true,
                        textInputAction: TextInputAction.send,
                        style: c.body.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          hintText: 'Ask Nodo about ${widget.contextScope == 'Global' ? 'anything you saved' : widget.contextScope}…',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide(color: c.mark.withValues(alpha: 0.5))),
                          contentPadding: const EdgeInsets.fromLTRB(20, 15, 8, 15),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Tooltip(
                              message: 'Send',
                              child: Pressable(
                                pressedScale: 0.85,
                                hoverLift: 0,
                                enabled: ready,
                                onTap: _submitQuery,
                                child: AnimatedContainer(
                                  duration: Motion.standard,
                                  curve: Motion.silk,
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: ready ? c.fill : c.track),
                                  child: AnimatedRotation(
                                    duration: const Duration(milliseconds: 420),
                                    curve: Motion.settle,
                                    turns: ready ? 0 : -0.25,
                                    child: Icon(LucideIcons.arrowUp, size: 17, color: ready ? c.onFill : c.muted),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submitQuery(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Say plainly what leaves the device; the app is sold on privacy.
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    GroqAiService().isConfigured
                        ? 'Your question and the matching items it uses are sent to the cloud AI (Groq) to answer. Turn cloud AI off in Settings.'
                        : 'Cloud AI is off or you are signed out: answers come from on-device search only.',
                    style: c.meta.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_isFullscreen) {
      return Container(color: surface, width: double.infinity, height: double.infinity, child: content);
    }

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: c.dark ? 0.7 : 0.35),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                // Taps inside the dialog should not close it.
                child: GestureDetector(onTap: () {}, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _assistantMessage(CardInk c, _Message msg, int i) {
    final style = c.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.55, color: msg.isNotice ? c.muted : c.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FastTypewriterText(text: msg.text, autoStart: i == _messages.length - 1, style: style),
        ),
        if (msg.modelInfo != null || msg.sources.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            [
              if (msg.sources.isNotEmpty) 'From ${msg.sources.take(4).join(', ')}',
              if (msg.modelInfo != null) msg.modelInfo!,
            ].join(' · '),
            style: c.meta.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _userMessage(CardInk c, _Message msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: SelectableText(msg.text, style: c.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w400, color: c.onFill, height: 1.45)),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool strong;

  const _HeaderIcon({required this.icon, required this.tooltip, required this.onTap, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    return Tooltip(
      message: tooltip,
      child: Pressable(
        pressedScale: 0.85,
        hoverLift: 0,
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Center(child: Icon(icon, size: strong ? 19 : 16, color: strong ? c.ink : c.muted))),
      ),
    );
  }
}
