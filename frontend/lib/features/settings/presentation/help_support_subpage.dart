import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/widgets/app_toast_engine.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/curator_feedback_dialog.dart';
import 'settings_subpages.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;
  final IconData icon;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    required this.icon,
  });
}

/// Comprehensive Help & Support Subpage with 18+ FAQs, search, and direct feedback.
class HelpSupportSubpage extends StatefulWidget {
  const HelpSupportSubpage({super.key});

  @override
  State<HelpSupportSubpage> createState() => _HelpSupportSubpageState();
}

class _HelpSupportSubpageState extends State<HelpSupportSubpage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Set<int> _expandedIndices = {};
  final Set<int> _helpfulIndices = {};

  static const List<FaqItem> _allFaqs = [
    // 1. Streaks & Habits
    FaqItem(
      category: 'Streaks & Habits',
      icon: LucideIcons.flame,
      question: 'How does the Daily Streak work, and what happens if I miss a day?',
      answer:
          'Your streak increments every calendar day you complete at least one task or habit, or check in via the Daily Check-in (Wax Seal) on Home. If life gets busy and you miss a day, you can use a Streak Freeze (earned every 7 unbroken days) to preserve your flame without losing your progress.',
    ),
    FaqItem(
      category: 'Streaks & Habits',
      icon: LucideIcons.sparkles,
      question: 'What are the Streak Flame Evolution Tiers?',
      answer:
          'As your consistency grows, your streak flame visually evolves through 5 tiers:\n• Tier 1: Kindling Spark (Days 1–3)\n• Tier 2: Brass Lantern (Days 4–7)\n• Tier 3: Sacred Hearth (Days 8–14)\n• Tier 4: Supernova Corona (Days 15–29)\n• Tier 5: Golden Phoenix (Days 30+)\nEach tier unlocks glowing avatar frames and distinctive celebration effects.',
    ),
    FaqItem(
      category: 'Streaks & Habits',
      icon: LucideIcons.bellRing,
      question: 'How do the 3-hour system reminders work?',
      answer:
          'NOTtEodo uses Android exact alarm clocks to schedule timely reminders every 3 hours during your active day. Unlike standard push notifications, these ring on-device even if the app is closed, with engaging Duolingo-style nudges to protect your streak, pause for a breath, or tackle your #1 task.',
    ),

    // 2. Privacy & Security
    FaqItem(
      category: 'Privacy & Security',
      icon: LucideIcons.shieldCheck,
      question: 'Is my data really 100% private and stored on my own device?',
      answer:
          'Yes! NOTtEodo is built as an offline-first workspace. Your tasks, notes, habits, expenses, and voice recordings live entirely on your device in an encrypted local database. Nothing leaves your phone unless you explicitly choose to sign in to cloud sync.',
    ),
    FaqItem(
      category: 'Privacy & Security',
      icon: LucideIcons.lock,
      question: 'What is the Private Vault, and how is it secured?',
      answer:
          'The Private Vault protects your most confidential notes, journal entries, and credentials. It is encrypted on-device using military-grade AES-256 GCM encryption. You can unlock it using biometric authentication (fingerprint/Face ID) or a custom master PIN.',
    ),
    FaqItem(
      category: 'Privacy & Security',
      icon: LucideIcons.key,
      question: 'What happens if I forget my Private Vault PIN?',
      answer:
          'Because the vault uses zero-knowledge encryption, your PIN is never stored or transmitted to any server. If you forget it, you can unlock using your enrolled biometric fingerprint or restore your vault using an exported encrypted backup file.',
    ),
    FaqItem(
      category: 'Privacy & Security',
      icon: LucideIcons.eyeOff,
      question: 'Does NOTtEodo contain ads, cookies, or third-party trackers?',
      answer:
          'Zero. There are no advertising SDKs, no behavioral trackers, and no data-broker scripts inside NOTtEodo. Your focus, habits, and personal reflections belong entirely to you.',
    ),

    // 3. AI Companion (Nodo)
    FaqItem(
      category: 'AI Companion',
      icon: LucideIcons.bot,
      question: 'Who is Nodo, and how does the AI Companion work?',
      answer:
          'Nodo is your thoughtful on-device productivity companion. Nodo monitors your open priorities and habit momentum to offer helpful daily focus quotes, gentle nudges, or witty reality checks. You can talk to Nodo anytime by tapping the AI button on the navigation bar.',
    ),
    FaqItem(
      category: 'AI Companion',
      icon: LucideIcons.messageSquare,
      question: 'How do I toggle between "Inspire Me" and "Roast My Focus" modes?',
      answer:
          'On the Home screen, find the "Nodo\'s Companion Pulse" card. Tap the "Inspire Me" button for philosophical, clarifying daily motivation, or tap "Roast My Focus" for playful, affectionate reality checks that push you to stop procrastinating!',
    ),
    FaqItem(
      category: 'AI Companion',
      icon: LucideIcons.userCheck,
      question: 'What should I do if Nodo is not remembering my name or preferences?',
      answer:
          'Open Profile → Tap "Edit Profile" or the Curator Identity card. Enter your preferred display name and personal bio motto. Nodo automatically synchronizes with your profile memory cache and uses your chosen name and preferences across all conversations.',
    ),

    // 4. Focus & Timer
    FaqItem(
      category: 'Focus & Timer',
      icon: LucideIcons.watch,
      question: 'What is the Watchmaker Focus Dial, and how do I use it?',
      answer:
          'The Watchmaker Focus Dial is a precision Pomodoro timer inspired by Swiss horology. It features traditional heated steel Breguet hands that sweep smoothly across a chapter ring over a 25-minute focus session. Tap the dial on Home to open a fullscreen desk stand timer view.',
    ),
    FaqItem(
      category: 'Focus & Timer',
      icon: LucideIcons.headphones,
      question: 'How do I change the ambient soundtrack playing during focus?',
      answer:
          'Tap the headphones icon on the Focus Timer card or inside the Watchmaker Focus Dial sheet. Choose from soothing ambient loops like Rain on Parchment, Warm Fireplace, Deep Focus Drone, Coffee Shop Murmur, or upload your own custom audio track.',
    ),
    FaqItem(
      category: 'Focus & Timer',
      icon: LucideIcons.minimize2,
      question: 'How do I switch back from Zen / Minimalist Mode on Home?',
      answer:
          'When Zen Mode is active, all extra bento pods disappear to give you an uncluttered view of today\'s core priorities. To switch back, simply tap the floating expand button in the upper right header to return to the full dashboard.',
    ),

    // 5. Backup & Sync
    FaqItem(
      category: 'Backup & Sync',
      icon: LucideIcons.cloud,
      question: 'How do I backup or transfer my data to a new phone?',
      answer:
          'Go to Settings → Data Portability & Backup. Tap "Export Full Archive" to save a password-encrypted JSON snapshot of your notes, tasks, habits, and expenses. On your new phone, tap "Restore Archive" to import everything in seconds.',
    ),
    FaqItem(
      category: 'Backup & Sync',
      icon: LucideIcons.calendar,
      question: 'Can I export my tasks to Google Calendar or Apple Calendar?',
      answer:
          'Yes! In Settings → Data Portability & Backup, tap "Export Calendar (.ics)". This generates a universal iCalendar file that seamlessly syncs with Google Calendar, Apple Calendar, Outlook, and other calendar apps.',
    ),
    FaqItem(
      category: 'Backup & Sync',
      icon: LucideIcons.fileSpreadsheet,
      question: 'Can I export my monthly expenses to Excel or Google Sheets?',
      answer:
          'Yes! You can export your entire expense history as a clean CSV spreadsheet from Settings → Data Portability & Backup. The CSV includes dates, categories, amounts, and notes ready for financial planning.',
    ),

    // 6. Budget & Expenses
    FaqItem(
      category: 'Budget & Expenses',
      icon: LucideIcons.wallet,
      question: 'How does the Monthly Budget and Expense Pacing work?',
      answer:
          'Set your monthly budget limit in Settings → Financial Discipline. As you record expenses throughout the month, NOTtEodo calculates your daily spend burn rate, displays a pacing gauge, and notifies you before you cross your budget ceiling.',
    ),
    FaqItem(
      category: 'Budget & Expenses',
      icon: LucideIcons.messageSquarePlus,
      question: 'How do I submit feedback, report a bug, or suggest a new feature?',
      answer:
          'Open the navigation drawer and tap "Feature Suggestion & Feedback", or tap the "Send Feedback" button below. Your suggestions are delivered directly to the team and help shape upcoming NOTtEodo releases!',
    ),
  ];

  List<FaqItem> get _filteredFaqs {
    final query = _searchController.text.trim().toLowerCase();
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query) ||
          faq.category.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleFaq(int index) {
    SanctuaryHapticEngine.selection();
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }

  void _copyAnswer(String answer) {
    SanctuaryHapticEngine.selection();
    Clipboard.setData(ClipboardData(text: answer));
    AppToastEngine().notify(
      title: 'Answer Copied',
      message: 'FAQ answer copied to your clipboard.',
    );
  }

  void _markHelpful(int index, bool helpful) {
    SanctuaryHapticEngine.selection();
    setState(() {
      _helpfulIndices.add(index);
    });
    AppToastEngine().notify(
      title: helpful ? 'Thank you!' : 'Feedback noted',
      message: helpful ? 'Glad this helped answer your question.' : 'We will improve this explanation.',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant;
    const terracotta = Color(0xFFD9725B);
    const sage = Color(0xFF8FA878);
    const gold = Color(0xFFD4AF37);

    final categories = ['All', 'Streaks & Habits', 'Privacy & Security', 'AI Companion', 'Focus & Timer', 'Backup & Sync', 'Budget & Expenses'];
    final faqs = _filteredFaqs;

    return SettingsSubpageScaffold(
      categoryLabel: 'Customer Care & Knowledge Base',
      title: 'Help & Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hero Card
          BentoPod(
            style: PodTextureStyle.glass,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: terracotta.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: terracotta.withValues(alpha: 0.35)),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.helpCircle, color: terracotta, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequently Asked Questions',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Instant answers to 18 common questions about streaks, privacy, timers, and sync.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          color: subtextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141210) : const Color(0xFFF3ECE0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF262220) : const Color(0xFFDDD5C6),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 16, color: subtextColor),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.dmSans(fontSize: 13, color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search answers (e.g. streak, backup, timer, pin)...',
                      hintStyle: GoogleFonts.dmSans(fontSize: 12.5, color: subtextColor.withValues(alpha: 0.7)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 14, color: subtextColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      SanctuaryHapticEngine.selection();
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? terracotta
                            : (isDark ? const Color(0xFF181513) : const Color(0xFFEBE4D8)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? terracotta : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : primaryTextColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Results Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${faqs.length} TOPICS FOUND',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: terracotta,
                ),
              ),
              if (_expandedIndices.isNotEmpty)
                InkWell(
                  onTap: () {
                    SanctuaryHapticEngine.selection();
                    setState(() => _expandedIndices.clear());
                  },
                  child: Text(
                    'Collapse all',
                    style: GoogleFonts.dmSans(fontSize: 11, color: subtextColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // FAQs List
          if (faqs.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.searchX, size: 36, color: subtextColor),
                  const SizedBox(height: 10),
                  Text(
                    'No answers match your search.',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try another keyword or tap "Send Feedback" below.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...faqs.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isExpanded = _expandedIndices.contains(idx);
              final isMarked = _helpfulIndices.contains(idx);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpanded
                        ? terracotta.withValues(alpha: 0.45)
                        : (isDark ? const Color(0xFF221E1C) : const Color(0xFFE5DDD0)),
                    width: isExpanded ? 1.4 : 1.0,
                  ),
                ),
                child: InkWell(
                  onTap: () => _toggleFaq(idx),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (isExpanded ? terracotta : sage).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.icon, size: 14, color: isExpanded ? terracotta : sage),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.category.toUpperCase(),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: isExpanded ? terracotta : subtextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.question,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(LucideIcons.chevronDown, size: 16, color: subtextColor),
                            ),
                          ],
                        ),

                        // Expanded Answer
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0C0A09) : const Color(0xFFF1EADF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: terracotta.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.answer,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    color: primaryTextColor,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Action Row (Copy + Helpful feedback)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(LucideIcons.copy, size: 11),
                                      label: Text(
                                        'Copy Answer',
                                        style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: terracotta,
                                        side: BorderSide(color: terracotta.withValues(alpha: 0.35)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _copyAnswer(item.answer),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          isMarked ? 'Feedback sent' : 'Helpful?',
                                          style: GoogleFonts.dmSans(fontSize: 10, color: subtextColor),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(LucideIcons.thumbsUp, size: 13),
                                          color: isMarked ? sage : subtextColor,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: isMarked ? null : () => _markHelpful(idx, true),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(LucideIcons.thumbsDown, size: 13),
                                          color: subtextColor,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: isMarked ? null : () => _markHelpful(idx, false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),

          // Bottom Callout: Send Feedback / Contact Support
          BentoPod(
            style: PodTextureStyle.glass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.messageSquarePlus, color: gold, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Still have a question or feature idea?',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            'Our team reads every suggestion to make NOTtEodo better.',
                            style: GoogleFonts.dmSans(fontSize: 11.5, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.send, size: 14),
                    label: Text(
                      'SEND FEEDBACK OR SUGGESTION',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: terracotta,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      SanctuaryHapticEngine.selection();
                      CuratorFeedbackDialog.show(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
