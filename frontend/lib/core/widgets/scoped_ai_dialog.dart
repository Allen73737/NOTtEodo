import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../ai/user_memory_profile.dart';
import '../motion/motion.dart';
import '../performance/sanctuary_motion_engine.dart';
import '../services/companion_memory_service.dart';
import '../services/groq_ai_service.dart';
import '../services/local_knowledge_index.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'fast_typewriter_text.dart';
import 'nodo_avatar_widget.dart';
import 'sanctuary_loaders.dart';
import 'package:notteodo/core/editorial/editorial_mode.dart';

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
            ref.read(tasksProvider.notifier).addTask(title: title, priority: priority);
            answerText = '$answerText\n\n✓ Conquered: Task "$title" added to your list.';
          } else if (actionType == 'ADD_EXPENSE') {
            final title = data['title']?.toString() ?? 'Disbursement';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final category = data['category']?.toString() ?? 'General';
            ref.read(expensesProvider.notifier).addExpense(title: title, amount: amount, category: category);
            answerText = '$answerText\n\n✓ Logged: Expense "$title" (${settings.currencySymbol}${amount.toStringAsFixed(0)}) in $category.';
          } else if (actionType == 'CREATE_NOTE') {
            final title = data['title']?.toString() ?? 'Note';
            final content = data['content']?.toString() ?? '';
            ref.read(notesProvider.notifier).addNote(
                  title: title,
                  excerpt: content,
                  space: 'General Space',
                  tag: 'AI Note',
                );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final accent = isDark ? const Color(0xFFE8927C) : AppColors.secondary;
    final settings = ref.watch(appSettingsProvider);
    final personaLabel = switch (settings.aiPersona) {
      'sarcastic' => 'Sarcastic',
      'scholarly' => 'Scholarly',
      'stoic' => 'Stoic',
      _ => 'Energetic',
    };

    final content = Material(
      color: isDark ? const Color(0xFF000000) : AppColors.background,
      shape: _isFullscreen
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
            ),
      child: SafeArea(
        top: _isFullscreen,
        bottom: _isFullscreen,
        child: Padding(
          padding: EdgeInsets.all(_isFullscreen ? 20 : 20),
          child: Column(
            mainAxisSize: _isFullscreen ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with animated Nodo avatar, title, persona badge, and window controls
              Row(
                children: [
                  NodoAvatarWidget(
                    size: 34,
                    emotion: _currentEmotion,
                    isInteractive: true,
                    onTap: () {
                      SanctuaryHapticEngine.sealImpression();
                      setState(() {
                        _currentEmotion = _currentEmotion == NodoEmotion.sarcastic
                            ? NodoEmotion.celebrating
                            : NodoEmotion.sarcastic;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'NODO AI',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: edBox(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                personaLabel.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Scope: ${widget.contextScope}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Clear Chat Button
                  IconButton(
                    tooltip: 'Clear chat',
                    icon: Icon(LucideIcons.trash2, size: 17, color: isDark ? Colors.white60 : Colors.black54),
                    onPressed: _clearChat,
                  ),
                  // Fullscreen toggle button
                  IconButton(
                    tooltip: _isFullscreen ? 'Shrink to window' : 'Expand full window',
                    icon: Icon(
                      _isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2,
                      size: 17,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.sealImpression();
                      setState(() => _isFullscreen = !_isFullscreen);
                    },
                  ),
                  // Close Dialog Button
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(LucideIcons.x, size: 18, color: text),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chat Messages Area
              Expanded(
                flex: _isFullscreen ? 1 : 0,
                child: Container(
                  height: _isFullscreen ? null : 320,
                  padding: const EdgeInsets.all(12),
                  decoration: edBox(
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
                            decoration: edBox(
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
                          crossAxisAlignment: msg.fromAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 520),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: edBox(
                                color: msg.fromAssistant
                                    ? (msg.isNotice ? AppColors.primary.withValues(alpha: 0.85) : AppColors.primary)
                                    : accent,
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
                                  Icon(LucideIcons.sparkles, size: 10, color: accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    msg.modelInfo!,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
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
                                  fontSize: 11,
                                  color: accent,
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
              ),
              const SizedBox(height: 14),

              // Quick Suggestions Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Summarize today\'s agenda',
                    'Where did I spend the most?',
                    'Suggest an outfit for today',
                    'High-priority tasks due',
                    'Who are you?',
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

              // Query Input Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Talk to Nodo about ${widget.contextScope == 'Global' ? 'your items' : widget.contextScope}…',
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
                    style: IconButton.styleFrom(backgroundColor: accent),
                    icon: Icon(LucideIcons.send, size: 16, color: isDark ? Colors.black : Colors.white),
                    onPressed: _isThinking ? null : _submitQuery,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Say plainly what leaves the device; the app is sold on privacy.
              Text(
                GroqAiService().isConfigured
                    ? 'Your question and the matching items it uses are sent to the cloud AI (Groq) to answer. Turn cloud AI off in Settings.'
                    : 'Cloud AI is off or you are signed out: answers come from on-device search only.',
                style: GoogleFonts.dmSans(fontSize: 12, height: 1.4, color: isDark ? const Color(0xFFA6A096) : const Color(0xFF6B635A)),
              ),
            ],
          ),
        ),
      ),
    );

    if (_isFullscreen) {
      return Container(
        color: isDark ? const Color(0xFF000000) : AppColors.background,
        width: double.infinity,
        height: double.infinity,
        child: content,
      );
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
