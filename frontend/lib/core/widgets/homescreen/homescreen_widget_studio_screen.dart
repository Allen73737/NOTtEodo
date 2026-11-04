import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_toast_engine.dart';
import 'aesthetic_homescreen_widgets.dart';
import 'aesthetic_widget_models.dart';
import 'homescreen_widget_service.dart';

/// Interactive Homescreen Widget Studio & Showcase.
/// Allows previewing, styling, and pinning aesthetic Pinterest-style widgets.
class HomescreenWidgetStudioScreen extends StatefulWidget {
  const HomescreenWidgetStudioScreen({super.key});

  @override
  State<HomescreenWidgetStudioScreen> createState() => _HomescreenWidgetStudioScreenState();
}

class _HomescreenWidgetStudioScreenState extends State<HomescreenWidgetStudioScreen> {
  AestheticWidgetType _selectedType = AestheticWidgetType.stickyNote;
  AestheticPaperTheme _selectedTheme = AestheticPaperTheme.warmCream;
  WashiTapeStyle _selectedTape = WashiTapeStyle.terracotta;
  WidgetGridSize _selectedSize = WidgetGridSize.compact;
  bool _showStamp = true;
  String _stampLabel = 'CURATED';
  bool _isPinning = false;

  AestheticWidgetConfig get _currentConfig => AestheticWidgetConfig(
        id: 'widget_${_selectedType.name}',
        type: _selectedType,
        paperTheme: _selectedTheme,
        tapeStyle: _selectedTape,
        size: _selectedSize,
        showStamp: _showStamp,
        stampLabel: _stampLabel,
      );

  Future<void> _handleAddToHomescreen() async {
    setState(() => _isPinning = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await HomescreenWidgetService().requestPinWidget(_currentConfig);
      if (mounted) {
        if (success) {
          AppToastEngine().notify(
            title: 'Widget Pinned',
            message: '“${_selectedType.displayName}” added to your homescreen.',
            type: ToastType.success,
          );
        } else {
          // Provide manual instructions if OS direct pinning is restricted
          _showPinInstructionsDialog();
        }
      }
    } catch (_) {
      if (mounted) _showPinInstructionsDialog();
    } finally {
      if (mounted) setState(() => _isPinning = false);
    }
  }

  void _showPinInstructionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFEF9EE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF16282C), width: 1.2),
        ),
        title: const Text(
          'Place Widget on Homescreen',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF16282C),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Long-press on an empty spot on your device home screen.\n'
              '2. Tap "Widgets".\n'
              '3. Scroll to "NOTtEodo" and select your preferred widget size.\n'
              '4. Drag it to your home screen.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF16282C),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                color: Color(0xFF9C432F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFEF9EE);
    const ink = Color(0xFF16282C);
    const terracotta = Color(0xFF9C432F);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Homescreen Studio',
              style: TextStyle(
                fontFamily: 'Bodoni Moda',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            Text(
              'Aesthetic Pinterest Curation',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: Color(0xFF6B7678),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Phone Simulator Preview Canvas
              _buildHomescreenSimulator(ink),

              const SizedBox(height: 24),

              // 2. Action: Pin to homescreen button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isPinning ? null : _handleAddToHomescreen,
                  icon: _isPinning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.add_to_home_screen_rounded, size: 18, color: Colors.white),
                  label: Text(
                    _isPinning ? 'PREPARING WIDGET...' : 'ADD WIDGET TO HOMESCREEN',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 3. Module / Feature Category Picker
              const Text(
                '1. CHOOSE MODULE FEATURE',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategorySelector(ink),

              const SizedBox(height: 24),

              // 4. Widget Size Selector
              const Text(
                '2. WIDGET DIMENSIONS',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildSizeSelector(ink),

              const SizedBox(height: 24),

              // 5. Aesthetic Paper Tone Picker
              const Text(
                '3. ARTISANAL PAPER FINISH',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaperThemeSelector(ink),

              const SizedBox(height: 24),

              // 6. Washi Tape Color Picker
              const Text(
                '4. VINTAGE WASHI TAPE',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildWashiTapeSelector(),

              const SizedBox(height: 24),

              // 7. Vintage Rubber Stamp Toggle
              _buildStampSection(ink),

              const SizedBox(height: 36),

              // 8. Pinterest Gallery: All 8 Modules Showcase
              const Text(
                'COMPLETE COLLECTION SHOWCASE',
                style: TextStyle(
                  fontFamily: 'Bodoni Moda',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Curated aesthetic widgets for every facet of your life.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: Color(0xFF6B7678),
                ),
              ),
              const SizedBox(height: 16),
              _buildAllModulesShowcase(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Simulated Mobile Homescreen
  Widget _buildHomescreenSimulator(Color ink) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE9DC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ink.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        children: [
          // Status bar simulation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '9:41',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    Icon(Icons.wifi, size: 12, color: ink),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full, size: 13, color: ink),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Real live aesthetic widget sitting on simulated homescreen
          Center(
            child: AestheticHomescreenWidgetCard(
              config: _currentConfig,
            ),
          ),

          const SizedBox(height: 20),

          // Simulated app dock icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSimulatedAppIcon(Icons.notes_rounded, 'Notes', ink),
              _buildSimulatedAppIcon(Icons.check_circle_outline, 'Rituals', ink),
              _buildSimulatedAppIcon(Icons.camera_alt_outlined, 'Photos', ink),
              _buildSimulatedAppIcon(Icons.account_balance_wallet_outlined, 'Vault', ink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedAppIcon(IconData icon, String label, Color ink) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ink.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 20, color: ink),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: ink.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // Category Selector
  Widget _buildCategorySelector(Color ink) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AestheticWidgetType.values.map((type) {
          final isSelected = type == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                type.icon,
                size: 15,
                color: isSelected ? Colors.white : ink,
              ),
              label: Text(type.displayName),
              labelStyle: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : ink,
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF16282C),
              backgroundColor: const Color(0xFFF3EDE2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: ink.withValues(alpha: 0.2)),
              ),
              onSelected: (_) => setState(() => _selectedType = type),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Size Selector
  Widget _buildSizeSelector(Color ink) {
    return Row(
      children: WidgetGridSize.values.map((size) {
        final isSelected = size == _selectedSize;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFF16282C) : Colors.transparent,
                side: BorderSide(color: ink, width: 1.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => setState(() => _selectedSize = size),
              child: Text(
                size.label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : ink,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Paper Theme Selector
  Widget _buildPaperThemeSelector(Color ink) {
    return Row(
      children: AestheticPaperTheme.values.map((theme) {
        final isSelected = theme == _selectedTheme;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTheme = theme),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF9C432F) : ink.withValues(alpha: 0.3),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.cardSurfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.borderColor, width: 1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.displayName.split(' ').first,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Washi Tape Color Selector
  Widget _buildWashiTapeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: WashiTapeStyle.values.map((tape) {
        final isSelected = tape == _selectedTape;
        return GestureDetector(
          onTap: () => setState(() => _selectedTape = tape),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 22,
                decoration: BoxDecoration(
                  color: tape.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.black.withValues(alpha: 0.2),
                    width: isSelected ? 2.0 : 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tape.displayName,
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Stamp Section
  Widget _buildStampSection(Color ink) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _showStamp,
              activeColor: ink,
              onChanged: (val) => setState(() => _showStamp = val ?? true),
            ),
            const Text(
              'Include Vintage Stamp',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (_showStamp)
          DropdownButton<String>(
            value: _stampLabel,
            underline: const SizedBox(),
            items: ['CURATED', 'APPROVED', 'SANCTUARY', 'HAUTE OS'].map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _stampLabel = val);
            },
          ),
      ],
    );
  }

  // Showcase of all 8 widgets in Pinterest-style layout
  Widget _buildAllModulesShowcase() {
    return Column(
      children: AestheticWidgetType.values.map((type) {
        final config = AestheticWidgetConfig(
          id: 'showcase_${type.name}',
          type: type,
          paperTheme: _selectedTheme,
          tapeStyle: _selectedTape,
          size: WidgetGridSize.wide,
          showStamp: true,
          stampLabel: 'CURATED',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${type.sectionLabel} · ${type.displayName.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF9C432F),
                ),
              ),
              const SizedBox(height: 6),
              AestheticHomescreenWidgetCard(
                config: config,
                onTap: () {
                  setState(() => _selectedType = type);
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

