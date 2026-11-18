import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/services/ai_stylist_service.dart';
import '../../../core/widgets/app_toast_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/state/sanctuary_state.dart';
import '../../../core/widgets/bento_pod.dart';
import '../../../core/widgets/card_kit.dart';
import '../../../core/performance/sanctuary_motion_engine.dart';
import '../../../core/motion/motion.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entry_editor.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _selectedFabric = 'All Fabrics';
  StylistRecommendation? _recommendation;
  bool _isLoadingRecommendation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendation();
    });
  }

  Future<void> _loadRecommendation() async {
    if (_isLoadingRecommendation || !mounted) return;
    setState(() => _isLoadingRecommendation = true);
    final outfits = ref.read(wardrobeProvider);
    final rec = await AiStylistService().recommendDailyOutfit(wardrobe: outfits);
    if (mounted) {
      setState(() {
        _recommendation = rec;
        _isLoadingRecommendation = false;
      });
    }
  }

  void _showCurateOutfitDialog(BuildContext context, bool isDark) {
    openEntryEditor(context, EntryKind.outfit);
  }

  Widget _buildStylistBentoPod(CardInk c) {
    final rec = _recommendation;
    return BentoPod(
      style: PodTextureStyle.glass,
      padding: const EdgeInsets.fromLTRB(22, 18, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CardLabel('Suggested for today', trailing: rec?.occasion)),
              Tooltip(
                message: _isLoadingRecommendation ? 'Thinking…' : 'Suggest another',
                child: Pressable(
                  pressedScale: 0.85,
                  hoverLift: 0,
                  enabled: !_isLoadingRecommendation,
                  onTap: _loadRecommendation,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: _isLoadingRecommendation
                          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.muted))
                          : Icon(LucideIcons.refreshCw, size: 15, color: c.muted),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Motion.silk,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(a), child: child),
              ),
              child: rec == null && _isLoadingRecommendation
                  ? Padding(
                      key: const ValueKey('loading'),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text('Putting a look together…', style: c.meta.copyWith(fontSize: 14)),
                    )
                  : Column(
                      key: ValueKey(rec?.lookTitle),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(rec?.lookTitle ?? 'Linen and silk', style: c.title.copyWith(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(rec?.ensemble ?? 'Italian linen shirt with raw silk pleated trousers', style: c.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w400)),
                        const CardRule(),
                        Text(rec?.fabricHarmony ?? 'Light textures that suit mild weather.', style: c.meta.copyWith(fontSize: 13.5)),
                        const SizedBox(height: 4),
                        Text(rec?.stylingTip ?? 'Keep accessories simple.', style: c.meta.copyWith(fontSize: 13.5, fontStyle: FontStyle.italic)),
                        if (rec != null) ...[
                          const SizedBox(height: 14),
                          CardAction(
                            label: 'Save this look',
                            icon: LucideIcons.plus,
                            onTap: () {
                              ref.read(wardrobeProvider.notifier).addOutfit(
                                    title: rec.lookTitle,
                                    category: rec.ensemble,
                                    vibe: rec.occasion,
                                    tags: ['AI Suggested', 'Wardrobe'],
                                    previewIcon: 'sparkles',
                                  );
                              AppToastEngine().showToast(context, title: 'Look saved', message: '"${rec.lookTitle}" is in your wardrobe.');
                            },
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static const _fabrics = [
    ('All Fabrics', Color(0x00000000)),
    ('Italian Linen', Color(0xFFE5DFC9)),
    ('Raw Silk', Color(0xFFEADBD2)),
    ('Heavy Denim', Color(0xFF3B3437)),
    ('Cashmere', Color(0xFFE8927C)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = CardInk.of(context);
    final outfits = ref.watch(wardrobeProvider);
    final filteredOutfits = _selectedFabric == 'All Fabrics'
        ? outfits
        : outfits
            .where((o) => o.tags.any((t) => t.toLowerCase() == _selectedFabric.toLowerCase()) || o.category.toLowerCase().contains(_selectedFabric.toLowerCase()))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wardrobe', style: GoogleFonts.bodoniModa(fontSize: 36, fontWeight: FontWeight.bold, color: c.ink, height: 1.05)),
                    const SizedBox(height: 4),
                    RollingText('${outfits.length} ${outfits.length == 1 ? 'look' : 'looks'}', style: c.meta.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CardAction(label: 'New outfit', icon: LucideIcons.plus, onTap: () => _showCurateOutfitDialog(context, c.dark)),
            ],
          ),
          const SizedBox(height: 20),
          _buildStylistBentoPod(c),
          const SizedBox(height: 18),

          // Fabric filter: a real swatch beside each name; the chosen one gets a dot.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final (name, swatch) in _fabrics)
                  Semantics(
                    button: true,
                    selected: _selectedFabric == name,
                    label: name,
                    excludeSemantics: true,
                    child: Pressable(
                      pressedScale: 0.92,
                      hoverLift: 0,
                      onTap: () => setState(() => _selectedFabric = name),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 20, 4),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (swatch.a > 0) ...[
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: swatch, border: Border.all(color: c.muted.withValues(alpha: 0.3))),
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                AnimatedDefaultTextStyle(
                                  duration: Motion.standard,
                                  style: c.meta.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: _selectedFabric == name ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedFabric == name ? c.ink : c.muted,
                                  ),
                                  child: Text(name == 'All Fabrics' ? 'All' : name),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 420),
                              curve: Motion.settle,
                              scale: _selectedFabric == name ? 1 : 0,
                              child: Container(width: 4, height: 4, decoration: BoxDecoration(color: c.mark, shape: BoxShape.circle)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filteredOutfits.isEmpty)
            EmptyState(
              icon: LucideIcons.shirt,
              title: 'No looks yet',
              message: _selectedFabric == 'All Fabrics' ? 'Add an outfit to start your wardrobe.' : 'No outfits in ${_selectedFabric.toLowerCase()} yet.',
            )
          else
            MotionColumn(
              spacing: 0,
              // A board of looks on wide screens; one column on phones.
              minTileWidth: 330,
              children: [
                for (var idx = 0; idx < filteredOutfits.length; idx++)
                  Builder(key: ValueKey(filteredOutfits[idx].id), builder: (context) {
                    final outfit = filteredOutfits[idx];
                    final hasImage = outfit.imageUrl != null && outfit.imageUrl!.trim().isNotEmpty;
                    return Reveal(
                      style: RevealStyle.slideIn,
                      distance: 18,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BentoPod(
                          style: PodTextureStyle.glass,
                          padding: EdgeInsets.zero,
                          onTap: () => openEntryEditor(context, EntryKind.outfit, editing: outfit),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasImage)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                  child: _buildOutfitImage(outfit.imageUrl!, c.dark),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(22, 16, 8, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            [outfit.vibe, outfit.weather].where((s) => s.trim().isNotEmpty).join(' · '),
                                            style: c.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Delete outfit',
                                          child: Pressable(
                                            pressedScale: 0.85,
                                            hoverLift: 0,
                                            onTap: () {
                                              SanctuaryHapticEngine.sealImpression();
                                              ref.read(wardrobeProvider.notifier).removeOutfit(outfit.id);
                                            },
                                            child: SizedBox(width: 36, height: 36, child: Center(child: Icon(LucideIcons.trash2, size: 14, color: c.muted.withValues(alpha: 0.7)))),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(outfit.title, style: c.title.copyWith(fontSize: 21)),
                                          const SizedBox(height: 4),
                                          Text(outfit.items, style: c.body.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5)),
                                          if (outfit.fabric.trim().isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(outfit.fabric, style: c.meta.copyWith(fontSize: 12.5)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
        ].revealed(),
      ),
    );
  }

  Widget _buildOutfitImage(String url, bool isDark) {
    final bgColor = isDark ? const Color(0xFF141414) : const Color(0xFFF3EFE8);
    final fallback = Container(
      height: 180,
      width: double.infinity,
      color: bgColor,
      child: Center(
        child: Icon(LucideIcons.shirt, size: 28, color: isDark ? Colors.white30 : Colors.black26),
      ),
    );

    if (url.startsWith('http://') || url.startsWith('https://') || kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 190,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    try {
      final f = File(url);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 190,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    } catch (_) {}
    return fallback;
  }
}
