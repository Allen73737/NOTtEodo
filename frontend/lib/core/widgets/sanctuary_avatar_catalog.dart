import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../performance/sanctuary_motion_engine.dart';
import '../services/device_media_service.dart';
import '../state/app_settings.dart';
import 'app_toast_engine.dart';

/// A curated persona archetype avatar preset
class AvatarPresetItem {
  final String id;
  final String title;
  final String category; // 'GENTLEMEN', 'LADIES', 'MYTHIC & CREATIVE'
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const AvatarPresetItem({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class SanctuaryAvatarCatalog {
  static const List<AvatarPresetItem> allPresets = [
    // --- GENTLEMEN ARCHETYPES ---
    AvatarPresetItem(
      id: 'male_scholar',
      title: 'Gentleman Scholar',
      category: 'GENTLEMEN',
      subtitle: 'Philosophy, Architecture & Depth',
      icon: LucideIcons.graduationCap,
      primaryColor: Color(0xFFD9725B),
      secondaryColor: Color(0xFF8C4636),
    ),
    AvatarPresetItem(
      id: 'male_executive',
      title: 'Executive Strategist',
      category: 'GENTLEMEN',
      subtitle: 'Leadership, Precision & Strategy',
      icon: LucideIcons.briefcase,
      primaryColor: Color(0xFFC48B71),
      secondaryColor: Color(0xFF5A3D31),
    ),
    AvatarPresetItem(
      id: 'male_zen',
      title: 'Zen Master',
      category: 'GENTLEMEN',
      subtitle: 'Stillness, Clarity & Discipline',
      icon: LucideIcons.sunMedium,
      primaryColor: Color(0xFF8FA878),
      secondaryColor: Color(0xFF4A5C3D),
    ),
    AvatarPresetItem(
      id: 'male_creative',
      title: 'Visual Artisan',
      category: 'GENTLEMEN',
      subtitle: 'Design, Vision & Expression',
      icon: LucideIcons.palette,
      primaryColor: Color(0xFFE8927C),
      secondaryColor: Color(0xFF7A4538),
    ),
    AvatarPresetItem(
      id: 'male_cyber',
      title: 'Cyber Architect',
      category: 'GENTLEMEN',
      subtitle: 'Technology, Systems & Innovation',
      icon: LucideIcons.terminal,
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFF6B581B),
    ),

    // --- LADIES ARCHETYPES ---
    AvatarPresetItem(
      id: 'female_curator',
      title: 'Haute Curator',
      category: 'LADIES',
      subtitle: 'Elegance, Discernment & Rhythm',
      icon: LucideIcons.sparkles,
      primaryColor: Color(0xFFE8927C),
      secondaryColor: Color(0xFF9E4B37),
    ),
    AvatarPresetItem(
      id: 'female_architect',
      title: 'Master Architect',
      category: 'LADIES',
      subtitle: 'Structure, Space & Modernity',
      icon: LucideIcons.building2,
      primaryColor: Color(0xFF8FA878),
      secondaryColor: Color(0xFF3F5433),
    ),
    AvatarPresetItem(
      id: 'female_poet',
      title: 'Poetic Sage',
      category: 'LADIES',
      subtitle: 'Literature, Memory & Lyricism',
      icon: LucideIcons.feather,
      primaryColor: Color(0xFFC48B71),
      secondaryColor: Color(0xFF734F3F),
    ),
    AvatarPresetItem(
      id: 'female_leader',
      title: 'Lead Architect',
      category: 'LADIES',
      subtitle: 'Strategic Vision & Leadership',
      icon: LucideIcons.crown,
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFF7A6420),
    ),
    AvatarPresetItem(
      id: 'female_zen',
      title: 'Flora Alchemist',
      category: 'LADIES',
      subtitle: 'Botanical Harmony & Grace',
      icon: LucideIcons.flower,
      primaryColor: Color(0xFF8FA878),
      secondaryColor: Color(0xFF4C613D),
    ),

    // --- MYTHIC & CREATIVE ARCHETYPES ---
    AvatarPresetItem(
      id: 'phoenix',
      title: 'Golden Phoenix',
      category: 'MYTHIC & CREATIVE',
      subtitle: 'Rebirth, Resilience & Fire',
      icon: LucideIcons.flame,
      primaryColor: Color(0xFFD9725B),
      secondaryColor: Color(0xFFE5A84B),
    ),
    AvatarPresetItem(
      id: 'owl',
      title: 'Obsidian Owl',
      category: 'MYTHIC & CREATIVE',
      subtitle: 'Keen Insight & Nocturnal Wisdom',
      icon: LucideIcons.eye,
      primaryColor: Color(0xFF8FA878),
      secondaryColor: Color(0xFF36482D),
    ),
    AvatarPresetItem(
      id: 'fox',
      title: 'Mystic Kitsune',
      category: 'MYTHIC & CREATIVE',
      subtitle: 'Resourcefulness & Agility',
      icon: LucideIcons.sparkle,
      primaryColor: Color(0xFFE8927C),
      secondaryColor: Color(0xFF944533),
    ),
    AvatarPresetItem(
      id: 'dragon',
      title: 'Celestial Dragon',
      category: 'MYTHIC & CREATIVE',
      subtitle: 'Infinite Potential & Mastery',
      icon: LucideIcons.shield,
      primaryColor: Color(0xFFD4AF37),
      secondaryColor: Color(0xFF6B581B),
    ),
    AvatarPresetItem(
      id: 'horology',
      title: 'Chronometer',
      category: 'MYTHIC & CREATIVE',
      subtitle: 'Precision Timekeeping & Mastery',
      icon: LucideIcons.clock,
      primaryColor: Color(0xFFC48B71),
      secondaryColor: Color(0xFF5E3C2F),
    ),
    AvatarPresetItem(
      id: 'monogram',
      title: 'Prism Diamond',
      category: 'MYTHIC & CREATIVE',
      subtitle: 'Clarity, Purity & Luminescence',
      icon: LucideIcons.gem,
      primaryColor: Color(0xFF8FA878),
      secondaryColor: Color(0xFF4D633E),
    ),
  ];

  static AvatarPresetItem? findById(String? id) {
    if (id == null) return null;
    try {
      return allPresets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Opens the interactive, animated avatar selection modal
  static Future<void> showSelector(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SanctuaryAvatarModal(),
    );
  }
}

class _SanctuaryAvatarModal extends ConsumerStatefulWidget {
  const _SanctuaryAvatarModal();

  @override
  ConsumerState<_SanctuaryAvatarModal> createState() => _SanctuaryAvatarModalState();
}

class _SanctuaryAvatarModalState extends ConsumerState<_SanctuaryAvatarModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1B1917);
    final subtextColor = isDark ? const Color(0xFFB0A89F) : const Color(0xFF6B655D);
    final sheetBg = isDark ? const Color(0xFF12100E) : const Color(0xFFFFFDF8);
    const terracotta = Color(0xFFD9725B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF2C241E) : const Color(0xFFE5DDD0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header with device photo upload shortcut
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curator Avatar Studio',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      'Choose an animated archetype or upload your photo',
                      style: GoogleFonts.dmSans(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Upload custom photo',
                  icon: const Icon(LucideIcons.camera, size: 20, color: terracotta),
                  onPressed: () async {
                    Navigator.pop(context);
                    final media = await DeviceMediaService().pickImage();
                    if (media != null) {
                      ref.read(appSettingsProvider.notifier).setAvatarCustomPath(media.path);
                      SanctuaryHapticEngine.sealImpression();
                      if (context.mounted) {
                        AppToastEngine().showToast(
                          context,
                          title: 'Custom Photo Saved',
                          message: 'Your profile photo has been updated.',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3-Tab Archetype Selector
          TabBar(
            controller: _tabCtrl,
            isScrollable: false,
            indicatorColor: terracotta,
            indicatorWeight: 2.5,
            labelColor: terracotta,
            unselectedLabelColor: subtextColor,
            labelStyle: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            tabs: const [
              Tab(text: 'GENTLEMEN'),
              Tab(text: 'LADIES'),
              Tab(text: 'CREATIVE'),
            ],
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF26201A) : const Color(0xFFE8E0D2)),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPresetGrid('GENTLEMEN', settings, isDark, primaryTextColor, subtextColor),
                _buildPresetGrid('LADIES', settings, isDark, primaryTextColor, subtextColor),
                _buildPresetGrid('MYTHIC & CREATIVE', settings, isDark, primaryTextColor, subtextColor),
              ],
            ),
          ),

          // Bottom reset action
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ref.read(appSettingsProvider.notifier).setAvatarPreset(null);
                      SanctuaryHapticEngine.selection();
                      Navigator.pop(context);
                    },
                    icon: const Icon(LucideIcons.rotateCcw, size: 13),
                    label: const Text('Reset to Initial Monogram', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetGrid(
    String category,
    AppSettings settings,
    bool isDark,
    Color primaryTextColor,
    Color subtextColor,
  ) {
    final items = SanctuaryAvatarCatalog.allPresets.where((p) => p.category == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = settings.avatarPreset == item.id;

        return _AnimatedAvatarCard(
          item: item,
          isSelected: isSelected,
          isDark: isDark,
          primaryTextColor: primaryTextColor,
          subtextColor: subtextColor,
          onTap: () {
            SanctuaryHapticEngine.dialDetent();
            ref.read(appSettingsProvider.notifier).setAvatarPreset(item.id);
            AppToastEngine().showToast(
              context,
              title: 'Avatar Updated',
              message: '${item.title} selected as your sanctuary archetype.',
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _AnimatedAvatarCard extends StatefulWidget {
  final AvatarPresetItem item;
  final bool isSelected;
  final bool isDark;
  final Color primaryTextColor;
  final Color subtextColor;
  final VoidCallback onTap;

  const _AnimatedAvatarCard({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.primaryTextColor,
    required this.subtextColor,
    required this.onTap,
  });

  @override
  State<_AnimatedAvatarCard> createState() => _AnimatedAvatarCardState();
}

class _AnimatedAvatarCardState extends State<_AnimatedAvatarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final pulse = widget.isSelected ? _pulseCtrl.value : 0.0;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? item.primaryColor.withValues(alpha: widget.isDark ? 0.2 : 0.12)
                  : (widget.isDark ? const Color(0xFF181512) : const Color(0xFFF7F4EE)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isSelected
                    ? item.primaryColor
                    : (widget.isDark ? const Color(0xFF2C241E) : const Color(0xFFE2DCD2)),
                width: widget.isSelected ? 2.0 : 1.0,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: item.primaryColor.withValues(alpha: 0.25 + pulse * 0.2),
                        blurRadius: 12 + pulse * 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [item.primaryColor, item.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.primaryColor.withValues(alpha: 0.35 + pulse * 0.2),
                        blurRadius: 10 + pulse * 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(item.icon, size: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected ? item.primaryColor : widget.primaryTextColor,
                  ),
                ),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    color: widget.subtextColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Universal animated renderer for the active avatar across all screens
class SanctuaryActiveAvatarView extends StatefulWidget {
  final AppSettings settings;
  final double size;
  final bool animated;

  const SanctuaryActiveAvatarView({
    super.key,
    required this.settings,
    this.size = 48,
    this.animated = true,
  });

  @override
  State<SanctuaryActiveAvatarView> createState() => _SanctuaryActiveAvatarViewState();
}

class _SanctuaryActiveAvatarViewState extends State<SanctuaryActiveAvatarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );
    _glowAnim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );
    if (widget.animated) {
      _animCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SanctuaryActiveAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _animCtrl.repeat(reverse: true);
      } else {
        _animCtrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarContent = _buildAvatarContent();
    if (!widget.animated) return avatarContent;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD9725B).withValues(alpha: _glowAnim.value * 0.35),
                  blurRadius: widget.size * 0.35,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: avatarContent,
    );
  }

  Widget _buildAvatarContent() {
    final settings = widget.settings;
    final size = widget.size;

    // 1. Custom photo from device
    if (settings.avatarCustomPath != null && settings.avatarCustomPath!.isNotEmpty) {
      final file = File(settings.avatarCustomPath!);
      if (!kIsWeb && file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // 2. Preset archetype avatar
    if (settings.avatarPreset != null) {
      final preset = SanctuaryAvatarCatalog.findById(settings.avatarPreset);
      if (preset != null) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [preset.primaryColor, preset.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: preset.primaryColor.withValues(alpha: 0.35),
                blurRadius: size * 0.25,
              ),
            ],
          ),
          child: Center(
            child: Icon(preset.icon, size: size * 0.48, color: Colors.white),
          ),
        );
      }
    }

    // 3. Fallback: Monogram Initial
    const terracotta = Color(0xFFD9725B);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: terracotta.withValues(alpha: 0.2),
        border: Border.all(color: terracotta, width: 1.5),
      ),
      child: Center(
        child: Text(
          settings.initial,
          style: GoogleFonts.bodoniModa(
            fontSize: size * 0.44,
            fontWeight: FontWeight.bold,
            color: terracotta,
          ),
        ),
      ),
    );
  }
}

