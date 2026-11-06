import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'app_toast_engine.dart';

class CuratorIdentityDialog extends ConsumerStatefulWidget {
  const CuratorIdentityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const CuratorIdentityDialog(),
    );
  }

  @override
  ConsumerState<CuratorIdentityDialog> createState() => _CuratorIdentityDialogState();
}

class _CuratorIdentityDialogState extends ConsumerState<CuratorIdentityDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  bool _isEditingLocation = false;
  late final TextEditingController _locCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    final loc = ref.read(appSettingsProvider).userLocation ?? '';
    _locCtrl = TextEditingController(text: loc);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  void _saveLocation() {
    final text = _locCtrl.text.trim();
    ref.read(appSettingsProvider.notifier).setUserLocation(text.isEmpty ? null : text);
    setState(() => _isEditingLocation = false);
    HapticFeedback.lightImpact();
    AppToastEngine().showToast(
      context,
      title: 'Location Updated',
      message: text.isEmpty ? 'Location removed from profile.' : 'Set to "$text".',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFB0A89F) : const Color(0xFF6B655D);
    final cardBg = isDark ? const Color(0xFF12100E) : const Color(0xFFFFFDF8);
    final borderColor = isDark ? const Color(0xFF2C241E) : const Color(0xFFE5DDD0);
    const terracotta = Color(0xFFD9725B);
    const goldAccent = Color(0xFFD4AF37);
    const warmSage = Color(0xFF8FA878);

    final notesCount = ref.watch(notesProvider).length;
    final tasksDone = ref.watch(tasksProvider).where((t) => t.completed).length;
    final habits = ref.watch(habitsProvider);
    final streak = settings.activeStreak > 0 ? settings.activeStreak : 1;

    final badges = [
      {'title': 'Genesis', 'desc': 'Day 1 Sanctuary Explorer', 'icon': '🌟', 'unlocked': streak >= 1},
      {'title': 'Momentum', 'desc': '3-Day Active Flow', 'icon': '🔥', 'unlocked': streak >= 3},
      {'title': 'Sovereign', 'desc': '7-Day Unbroken Habit', 'icon': '👑', 'unlocked': streak >= 7},
      {'title': 'Archivist', 'desc': '5+ Notes Crafted', 'icon': '📜', 'unlocked': notesCount >= 5},
      {'title': 'Titan', 'desc': '5+ Tasks Conquered', 'icon': '⚡', 'unlocked': tasksDone >= 5},
      {'title': 'Zen Master', 'desc': 'Habit Discipline', 'icon': '🧘', 'unlocked': habits.isNotEmpty},
    ];

    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.25),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar with Close Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: terracotta.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: terracotta.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'CURATOR PASSPORT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: terracotta,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1A16) : const Color(0xFFEDE6DA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.x, size: 16, color: subtextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Expanded High-Res Avatar Pod with Glow Aura
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: terracotta.withValues(alpha: 0.18),
                        border: Border.all(color: terracotta, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: terracotta.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          settings.initial,
                          style: GoogleFonts.bodoniModa(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: terracotta,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Display Name
                    Text(
                      settings.displayName.isEmpty ? 'Sanctuary Curator' : settings.displayName,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.bioMotto.isEmpty ? 'Sovereign productivity suite' : settings.bioMotto,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                    ),
                    const SizedBox(height: 16),

                    // Live Real Streak & Metrics Ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A0908) : const Color(0xFFF3ECE0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricCol('🔥 $streak Days', 'Live Streak', terracotta),
                          _buildDivider(borderColor),
                          _buildMetricCol('${settings.longestStreak.clamp(streak, 999)} Days', 'Best Streak', goldAccent),
                          _buildDivider(borderColor),
                          _buildMetricCol('${badges.where((b) => b['unlocked'] == true).length}/6', 'Badges', warmSage),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optional User Location Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171411) : const Color(0xFFF5EEE2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: _isEditingLocation
                          ? Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 15, color: terracotta),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _locCtrl,
                                    autofocus: true,
                                    style: GoogleFonts.dmSans(fontSize: 12.5, color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      hintText: 'City, Country (e.g. Tokyo, JP)',
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _saveLocation(),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(LucideIcons.check, size: 16, color: warmSage),
                                  onPressed: _saveLocation,
                                ),
                              ],
                            )
                          : InkWell(
                              onTap: () => setState(() => _isEditingLocation = true),
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mapPin, size: 14, color: terracotta),
                                      const SizedBox(width: 8),
                                      Text(
                                        settings.userLocation != null && settings.userLocation!.isNotEmpty
                                            ? settings.userLocation!
                                            : 'Add Location (Optional)',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: settings.userLocation != null && settings.userLocation!.isNotEmpty
                                              ? primaryTextColor
                                              : subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(LucideIcons.pencil, size: 12, color: subtextColor),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Badges & Stickers Grid
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SANCTUARY BADGES & ACHIEVEMENTS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: subtextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges.map((b) {
                        final isUnlocked = b['unlocked'] as bool;
                        return Container(
                          width: 116,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? (isDark ? const Color(0xFF1E1712) : const Color(0xFFFBEFE3))
                                : (isDark ? const Color(0xFF110E0B) : const Color(0xFFEBE4D6)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnlocked
                                  ? terracotta.withValues(alpha: 0.5)
                                  : (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b['icon'] as String, style: const TextStyle(fontSize: 16)),
                                  if (!isUnlocked)
                                    Icon(LucideIcons.lock, size: 11, color: subtextColor.withValues(alpha: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b['title'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? primaryTextColor : subtextColor,
                                ),
                              ),
                              Text(
                                b['desc'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(width: 1, height: 26, color: color);
  }
}

