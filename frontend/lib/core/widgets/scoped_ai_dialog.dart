import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

class ScopedAiDialog extends StatefulWidget {
  final String contextScope;
  final VoidCallback onClose;

  const ScopedAiDialog({
    super.key,
    required this.contextScope,
    required this.onClose,
  });

  @override
  State<ScopedAiDialog> createState() => _ScopedAiDialogState();
}

class _ScopedAiDialogState extends State<ScopedAiDialog> {
  final TextEditingController _queryCtrl = TextEditingController();
  bool _multiDocSynthesis = false;

  final List<String> _selectedDocs = ['OSI_Model.pdf', 'TCP_Congestion.pdf'];
  final List<String> _availableDocs = ['OSI_Model.pdf', 'TCP_Congestion.pdf', 'DESIGN.md', 'Receipt_8492.pdf'];

  final List<Map<String, String>> _messages = [
    {
      'sender': 'AI',
      'text': 'Scoped AI active for scope: "Computer Networks". I have indexed 4 documents in this collection.',
      'citations': 'OSI_Model.pdf · Page 12'
    },
  ];

  void _submitQuery() {
    final text = _queryCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'User', 'text': text, 'citations': ''});
      _queryCtrl.clear();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        final synthesisTag = _multiDocSynthesis ? ' [Synthesized across ${_selectedDocs.length} documents]' : '';
        _messages.add({
          'sender': 'AI',
          'text': 'Analyzed "$text"$synthesisTag inside ${widget.contextScope}. The OSI Transport Layer guarantees end-to-end flow control using sliding window protocols.',
          'citations': _selectedDocs.join(', '),
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
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
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles, color: AppColors.secondary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'SCOPED VECTOR AI · ${widget.contextScope.toUpperCase()}',
                                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: widget.onClose),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Multi-Doc Synthesis Mode Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Multi-Document Synthesis Mode', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold)),
                          Switch(
                            value: _multiDocSynthesis,
                            activeTrackColor: AppColors.secondary,
                            onChanged: (val) => setState(() => _multiDocSynthesis = val),
                          ),
                        ],
                      ),

                      if (_multiDocSynthesis) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: _availableDocs.map((doc) {
                            final isSel = _selectedDocs.contains(doc);
                            return FilterChip(
                              label: Text(doc, style: const TextStyle(fontSize: 10)),
                              selected: isSel,
                              selectedColor: AppColors.secondary.withValues(alpha: 0.3),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDocs.add(doc);
                                  } else {
                                    _selectedDocs.remove(doc);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Chat Messages Box
                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF080808) : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.black12),
                        ),
                        child: ListView.separated(
                          itemCount: _messages.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final msg = _messages[i];
                            final isAi = msg['sender'] == 'AI';

                            return Column(
                              crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isAi ? AppColors.primary : AppColors.secondary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(msg['text']!, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white, height: 1.4)),
                                ),
                                if (isAi && msg['citations']!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('📄 Citation: ${msg['citations']}', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _queryCtrl,
                              decoration: InputDecoration(
                                hintText: 'Ask RAG AI about ${widget.contextScope}...',
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
                            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                            onPressed: _submitQuery,
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
