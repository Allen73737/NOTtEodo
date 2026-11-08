import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_toast_engine.dart';
import 'aesthetic_homescreen_widgets.dart';
import 'aesthetic_widget_models.dart';
import 'homescreen_fast_data_cache.dart';
import 'homescreen_widget_service.dart';

/// Interactive Homescreen Widget Studio & Showcase.
/// Fully theme-adaptive (OLED Dark & Classic Light), persists user preferences,
/// and fast-caches live module data.
class HomescreenWidgetStudioScreen extends StatefulWidget {
  const HomescreenWidgetStudioScreen({super.key});

  @override
  State<HomescreenWidgetStudioScreen> createState() => _HomescreenWidgetStudioScreenState();
}

class _HomescreenWidgetStudioScreenState extends State<HomescreenWidgetStudioScreen> {
  late AestheticWidgetType _selectedType;
  late AestheticPaperTheme _selectedTheme;
  late WashiTapeStyle _selectedTape;
  late WidgetGridSize _selectedSize;
  late bool _showStamp;
  late String _stampLabel;
  late bool _autoMatchTheme;
  bool _isPinning = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedPreferences();
  }

  void _loadPersistedPreferences() {
    final cache = HomescreenFastDataCache();
    cache.init();

    _selectedType = cache.savedType;
    _selectedTape = cache.savedTape;
    _selectedSize = cache.savedSize;
    _showStamp = cache.savedShowStamp;
    _stampLabel = cache.savedStampLabel;
    _autoMatchTheme = cache.savedAutoMatchTheme;
    _selectedTheme = cache.savedTheme;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (_autoMatchTheme) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (isDark && _selectedTheme == AestheticPaperTheme.warmCream) {
          _selectedTheme = AestheticPaperTheme.obsidianNoir;
        } else if (!isDark && _selectedTheme == AestheticPaperTheme.obsidianNoir) {
          _selectedTheme = AestheticPaperTheme.warmCream;
        }
      }
    }
  }

  void _persistPreferences() {
    HomescreenFastDataCache().savePreferences(
      selectedType: _selectedType,
      selectedTheme: _selectedTheme,
      selectedTape: _selectedTape,
      selectedSize: _selectedSize,
      showStamp: _showStamp,
      stampLabel: _stampLabel,
      autoMatchTheme: _autoMatchTheme,
    );
  }

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
            message: '“${_selectedType.displayName}” placed on your homescreen.',
            type: ToastType.success,
          );
        } else {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAF5F2);
    final dialogInk = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1917);
    final dialogTerracotta = isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD7),
            width: 1.2,
          ),
        ),
        title: Text(
          'Place Widget on Homescreen',
          style: TextStyle(
            fontFamily: 'Bodoni Moda',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: dialogInk,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Long-press on an empty spot on your device home screen.\n'
              '2. Tap "Widgets".\n'
              '3. Scroll to "NOTtEodo" and select your preferred aesthetic widget size.\n'
              '4. Drag it to your home screen.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                height: 1.5,
                color: dialogInk,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'UNDERSTOOD',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                color: dialogTerracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFFAF5F2);
    final surface = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF4ECE8);
    final ink = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1917);
    final muted = isDark ? const Color(0xFFA6A096) : const Color(0xFF7A7570);
    final border = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE2DDD7);
    final terracotta = isDark ? const Color(0xFFE8927C) : const Color(0xFFD9725B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
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
              'Homescreen Widgets · ${isDark ? "Dark Mode" : "Light Mode"}',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Auto Match App Theme',
            icon: Icon(
              _autoMatchTheme ? Icons.brightness_auto_rounded : Icons.palette_outlined,
              color: _autoMatchTheme ? terracotta : muted,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _autoMatchTheme = !_autoMatchTheme;
                if (_autoMatchTheme) {
                  _selectedTheme = isDark ? AestheticPaperTheme.obsidianNoir : AestheticPaperTheme.warmCream;
                }
              });
              _persistPreferences();
              AppToastEngine().notify(
                title: _autoMatchTheme ? 'Theme Auto-Sync Enabled' : 'Manual Paper Palette',
                message: _autoMatchTheme
                    ? 'Widgets automatically adapt to Dark/Light mode.'
                    : 'Widgets maintain your selected paper finish.',
                type: ToastType.info,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fast Data Sync Indicator
              _buildFastSyncBadge(isDark, surface, border, terracotta),

              const SizedBox(height: 14),

              // 1. Phone Simulator Preview Canvas
              _buildHomescreenSimulator(isDark, ink, border),

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
              Text(
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
              _buildCategorySelector(isDark, ink, surface, border, terracotta),

              const SizedBox(height: 24),

              // 4. Widget Size Selector
              Text(
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
              _buildSizeSelector(isDark, ink, border, terracotta),

              const SizedBox(height: 24),

              // 5. Aesthetic Paper Tone Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '3. ARTISANAL PAPER FINISH',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _autoMatchTheme = !_autoMatchTheme;
                        if (_autoMatchTheme) {
                          _selectedTheme = isDark ? AestheticPaperTheme.obsidianNoir : AestheticPaperTheme.warmCream;
                        }
                      });
                      _persistPreferences();
                    },
                    child: Text(
                      _autoMatchTheme ? 'AUTO-SYNC ACTIVE' : 'MANUAL',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: _autoMatchTheme ? terracotta : muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPaperThemeSelector(isDark, ink, border, terracotta),

              const SizedBox(height: 24),

              // 6. Washi Tape Color Picker
              Text(
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
              _buildWashiTapeSelector(isDark, ink),

              const SizedBox(height: 24),

              // 7. Vintage Rubber Stamp Toggle
              _buildStampSection(isDark, ink, surface, border),

              const SizedBox(height: 36),

              // 8. Pinterest Gallery: All 8 Modules Showcase
              Text(
                'COMPLETE COLLECTION SHOWCASE',
                style: TextStyle(
                  fontFamily: 'Bodoni Moda',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aesthetic widgets dynamically powered by your live data.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: muted,
                ),
              ),
              const SizedBox(height: 16),
              _buildAllModulesShowcase(terracotta),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFastSyncBadge(bool isDark, Color surface, Color border, Color terracotta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: terracotta),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'FAST VAULT CACHE ACTIVE · LIVE SYNC ENABLED',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: terracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simulated Mobile Homescreen
  Widget _buildHomescreenSimulator(bool isDark, Color ink, Color border) {
    final simulatorBg = isDark ? const Color(0xFF0C1012) : const Color(0xFFEFE9DC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: simulatorBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        children: [
          // Status bar simulation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '9:41',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: ink),
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
              _buildSimulatedAppIcon(Icons.notes_rounded, 'Notes', isDark, ink),
              _buildSimulatedAppIcon(Icons.check_circle_outline, 'Rituals', isDark, ink),
              _buildSimulatedAppIcon(Icons.camera_alt_outlined, 'Photos', isDark, ink),
              _buildSimulatedAppIcon(Icons.account_balance_wallet_outlined, 'Vault', isDark, ink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedAppIcon(IconData icon, String label, bool isDark, Color ink) {
    final iconBg = isDark ? const Color(0xFF161F22) : const Color(0xFFFEF9EE);

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
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
  Widget _buildCategorySelector(bool isDark, Color ink, Color surface, Color border, Color terracotta) {
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
              selectedColor: isDark ? terracotta : const Color(0xFF1C1917),
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: isSelected ? terracotta : border),
              ),
              onSelected: (_) {
                setState(() => _selectedType = type);
                _persistPreferences();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Size Selector
  Widget _buildSizeSelector(bool isDark, Color ink, Color border, Color terracotta) {
    return Row(
      children: WidgetGridSize.values.map((size) {
        final isSelected = size == _selectedSize;
        final activeColor = isDark ? terracotta : const Color(0xFF1C1917);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? activeColor : Colors.transparent,
                side: BorderSide(color: isSelected ? activeColor : border, width: 1.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                setState(() => _selectedSize = size);
                _persistPreferences();
              },
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
  Widget _buildPaperThemeSelector(bool isDark, Color ink, Color border, Color terracotta) {
    return Row(
      children: AestheticPaperTheme.values.map((theme) {
        final isSelected = theme == _selectedTheme;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTheme = theme;
                _autoMatchTheme = false;
              });
              _persistPreferences();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? terracotta : border,
                  width: isSelected ? 2.2 : 1.0,
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
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  Widget _buildWashiTapeSelector(bool isDark, Color ink) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: WashiTapeStyle.values.map((tape) {
        final isSelected = tape == _selectedTape;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedTape = tape);
            _persistPreferences();
          },
          child: Column(
            children: [
              Container(
                width: 48,
                height: 22,
                decoration: BoxDecoration(
                  color: tape.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? ink : ink.withValues(alpha: 0.25),
                    width: isSelected ? 2.2 : 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tape.displayName,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Stamp Section
  Widget _buildStampSection(bool isDark, Color ink, Color surface, Color border) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _showStamp,
              activeColor: ink,
              checkColor: isDark ? Colors.black : Colors.white,
              onChanged: (val) {
                setState(() => _showStamp = val ?? true);
                _persistPreferences();
              },
            ),
            Text(
              'Include Vintage Stamp',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: ink),
            ),
          ],
        ),
        if (_showStamp)
          DropdownButton<String>(
            value: _stampLabel,
            dropdownColor: surface,
            underline: const SizedBox(),
            items: ['NOTTEODO', 'APPROVED', 'TODAY', 'FOCUS'].map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(
                  s,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _stampLabel = val);
                _persistPreferences();
              }
            },
          ),
      ],
    );
  }

  // Showcase of all 8 widgets in Pinterest-style layout
  Widget _buildAllModulesShowcase(Color terracotta) {
    return Column(
      children: AestheticWidgetType.values.map((type) {
        final config = AestheticWidgetConfig(
          id: 'showcase_${type.name}',
          type: type,
          paperTheme: _selectedTheme,
          tapeStyle: _selectedTape,
          size: WidgetGridSize.wide,
          showStamp: true,
          stampLabel: 'NOTTEODO',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${type.sectionLabel} · ${type.displayName.toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: terracotta,
                ),
              ),
              const SizedBox(height: 6),
              AestheticHomescreenWidgetCard(
                config: config,
                onTap: () {
                  setState(() => _selectedType = type);
                  _persistPreferences();
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
