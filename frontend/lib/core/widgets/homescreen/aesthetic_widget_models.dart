import 'package:flutter/material.dart';

/// Categories of aesthetic widgets matching NOTtEodo's life modules.
enum AestheticWidgetType {
  stickyNote,
  ritualChecklist,
  moodboardPolaroid,
  atelierOotd,
  vaultTreasury,
  voiceMemoir,
  airmailTravel,
  horologyClock;

  String get displayName {
    switch (this) {
      case AestheticWidgetType.stickyNote:
        return 'Sticky Note & Memo';
      case AestheticWidgetType.ritualChecklist:
        return 'Daily Ritual Checklist';
      case AestheticWidgetType.moodboardPolaroid:
        return 'Pinterest Polaroid Pin';
      case AestheticWidgetType.atelierOotd:
        return 'Outfit of the Day';
      case AestheticWidgetType.vaultTreasury:
        return 'Monthly Budget & Spend';
      case AestheticWidgetType.voiceMemoir:
        return 'Vintage Voice Tape';
      case AestheticWidgetType.airmailTravel:
        return 'Airmail Travel Pass';
      case AestheticWidgetType.horologyClock:
        return 'Guilloché Horology Clock';
    }
  }

  String get targetModule {
    switch (this) {
      case AestheticWidgetType.stickyNote:
        return 'notes';
      case AestheticWidgetType.ritualChecklist:
        return 'tasks';
      case AestheticWidgetType.moodboardPolaroid:
        return 'moodboard';
      case AestheticWidgetType.atelierOotd:
        return 'wardrobe';
      case AestheticWidgetType.vaultTreasury:
        return 'expenses';
      case AestheticWidgetType.voiceMemoir:
        return 'voice';
      case AestheticWidgetType.airmailTravel:
        return 'travel';
      case AestheticWidgetType.horologyClock:
        return 'focus';
    }
  }

  String get sectionLabel {
    switch (this) {
      case AestheticWidgetType.stickyNote:
        return 'NOTES';
      case AestheticWidgetType.ritualChecklist:
        return 'HABITS & TASKS';
      case AestheticWidgetType.moodboardPolaroid:
        return 'MOODBOARD';
      case AestheticWidgetType.atelierOotd:
        return 'WARDROBE';
      case AestheticWidgetType.vaultTreasury:
        return 'EXPENSES';
      case AestheticWidgetType.voiceMemoir:
        return 'VOICE NOTES';
      case AestheticWidgetType.airmailTravel:
        return 'TRAVEL';
      case AestheticWidgetType.horologyClock:
        return 'FOCUS & TIME';
    }
  }

  IconData get icon {
    switch (this) {
      case AestheticWidgetType.stickyNote:
        return Icons.edit_note_rounded;
      case AestheticWidgetType.ritualChecklist:
        return Icons.check_circle_outline_rounded;
      case AestheticWidgetType.moodboardPolaroid:
        return Icons.photo_library_outlined;
      case AestheticWidgetType.atelierOotd:
        return Icons.checkroom_rounded;
      case AestheticWidgetType.vaultTreasury:
        return Icons.account_balance_wallet_outlined;
      case AestheticWidgetType.voiceMemoir:
        return Icons.mic_none_rounded;
      case AestheticWidgetType.airmailTravel:
        return Icons.flight_takeoff_rounded;
      case AestheticWidgetType.horologyClock:
        return Icons.watch_later_outlined;
    }
  }
}

/// Paper surface tones (zero gradients, authentic physical finishes).
enum AestheticPaperTheme {
  warmCream,
  slateNoir,
  obsidianNoir,
  matchaSage,
  terracottaClay,
  kraftLinen;

  String get displayName {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return 'Warm Cream';
      case AestheticPaperTheme.slateNoir:
        return 'Slate Noir';
      case AestheticPaperTheme.obsidianNoir:
        return 'Obsidian OLED';
      case AestheticPaperTheme.matchaSage:
        return 'Matcha Sage';
      case AestheticPaperTheme.terracottaClay:
        return 'Terracotta Clay';
      case AestheticPaperTheme.kraftLinen:
        return 'Artisanal Kraft';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFFFAF5F2);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFF141414);
      case AestheticPaperTheme.obsidianNoir:
        return const Color(0xFF000000);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFFE8EFE9);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFFFDF2EE);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFFECE4D0);
    }
  }

  Color get cardSurfaceColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFFF4ECE8);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFF1E1E1E);
      case AestheticPaperTheme.obsidianNoir:
        return const Color(0xFF0F0F0F);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFFDFE9E1);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFFF6E2DB);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFFDFD5BF);
    }
  }

  Color get textColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFF1C1917);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFFFAF5F2);
      case AestheticPaperTheme.obsidianNoir:
        return const Color(0xFFFFFFFF);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFF162E25);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFF4A1F17);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFF2C241B);
    }
  }

  Color get textMutedColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFF6E6862);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFFA6A096);
      case AestheticPaperTheme.obsidianNoir:
        return const Color(0xFFA6A6A6);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFF526D61);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFF8C5C54);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFF7A6B59);
    }
  }

  Color get accentColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFFD9725B);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFFE8927C);
      case AestheticPaperTheme.obsidianNoir:
        return const Color(0xFFE8927C);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFF386B52);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFFD9725B);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFF8A5A2B);
    }
  }

  Color get borderColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFFDDD5C8);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFF2E2E2E);
      case AestheticPaperTheme.obsidianNoir:
        return const Color(0xFF242424);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFF2F4F40);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFF5A2A20);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFF3E3326);
    }
  }
}

/// Aesthetic Washi Tape styles.
enum WashiTapeStyle {
  terracotta,
  vintageGold,
  antiqueSage,
  midnightNoir,
  blushRose;

  String get displayName {
    switch (this) {
      case WashiTapeStyle.terracotta:
        return 'Terracotta';
      case WashiTapeStyle.vintageGold:
        return 'Ochre Gold';
      case WashiTapeStyle.antiqueSage:
        return 'Antique Sage';
      case WashiTapeStyle.midnightNoir:
        return 'Midnight Noir';
      case WashiTapeStyle.blushRose:
        return 'Blush Rose';
    }
  }

  Color get color {
    switch (this) {
      case WashiTapeStyle.terracotta:
        return const Color(0xFFD9725B);
      case WashiTapeStyle.vintageGold:
        return const Color(0xFFC9A227);
      case WashiTapeStyle.antiqueSage:
        return const Color(0xFF5F8271);
      case WashiTapeStyle.midnightNoir:
        return const Color(0xFF141414);
      case WashiTapeStyle.blushRose:
        return const Color(0xFFCCA09E);
    }
  }
}

/// Homescreen grid dimensions.
enum WidgetGridSize {
  compact, // 2x2 square (~160x160 dp)
  wide,    // 4x2 banner (~340x160 dp)
  expanded;// 4x4 bento (~340x340 dp)

  String get label {
    switch (this) {
      case WidgetGridSize.compact:
        return '2×2 Compact';
      case WidgetGridSize.wide:
        return '4×2 Wide';
      case WidgetGridSize.expanded:
        return '4×4 Bento';
    }
  }

  double get width {
    switch (this) {
      case WidgetGridSize.compact:
        return 165;
      case WidgetGridSize.wide:
      case WidgetGridSize.expanded:
        return 340;
    }
  }

  double get height {
    switch (this) {
      case WidgetGridSize.compact:
      case WidgetGridSize.wide:
        return 165;
      case WidgetGridSize.expanded:
        return 340;
    }
  }
}

/// Full configuration for an aesthetic homescreen widget.
class AestheticWidgetConfig {
  final String id;
  final AestheticWidgetType type;
  final AestheticPaperTheme paperTheme;
  final WashiTapeStyle tapeStyle;
  final WidgetGridSize size;
  final bool showStamp;
  final String stampLabel;
  final String? customTitle;
  final String? customSubtitle;

  const AestheticWidgetConfig({
    required this.id,
    required this.type,
    this.paperTheme = AestheticPaperTheme.warmCream,
    this.tapeStyle = WashiTapeStyle.terracotta,
    this.size = WidgetGridSize.compact,
    this.showStamp = true,
    this.stampLabel = 'NOTTEODO',
    this.customTitle,
    this.customSubtitle,
  });

  AestheticWidgetConfig copyWith({
    AestheticWidgetType? type,
    AestheticPaperTheme? paperTheme,
    WashiTapeStyle? tapeStyle,
    WidgetGridSize? size,
    bool? showStamp,
    String? stampLabel,
    String? customTitle,
    String? customSubtitle,
  }) {
    return AestheticWidgetConfig(
      id: id,
      type: type ?? this.type,
      paperTheme: paperTheme ?? this.paperTheme,
      tapeStyle: tapeStyle ?? this.tapeStyle,
      size: size ?? this.size,
      showStamp: showStamp ?? this.showStamp,
      stampLabel: stampLabel ?? this.stampLabel,
      customTitle: customTitle ?? this.customTitle,
      customSubtitle: customSubtitle ?? this.customSubtitle,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'paperTheme': paperTheme.name,
        'tapeStyle': tapeStyle.name,
        'size': size.name,
        'showStamp': showStamp,
        'stampLabel': stampLabel,
        'customTitle': customTitle,
        'customSubtitle': customSubtitle,
      };

  factory AestheticWidgetConfig.fromMap(Map<String, dynamic> map) {
    return AestheticWidgetConfig(
      id: map['id'] as String? ?? 'widget_default',
      type: AestheticWidgetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AestheticWidgetType.stickyNote,
      ),
      paperTheme: AestheticPaperTheme.values.firstWhere(
        (e) => e.name == map['paperTheme'],
        orElse: () => AestheticPaperTheme.warmCream,
      ),
      tapeStyle: WashiTapeStyle.values.firstWhere(
        (e) => e.name == map['tapeStyle'],
        orElse: () => WashiTapeStyle.terracotta,
      ),
      size: WidgetGridSize.values.firstWhere(
        (e) => e.name == map['size'],
        orElse: () => WidgetGridSize.compact,
      ),
      showStamp: map['showStamp'] as bool? ?? true,
      stampLabel: map['stampLabel'] as String? ?? 'NOTTEODO',
      customTitle: map['customTitle'] as String?,
      customSubtitle: map['customSubtitle'] as String?,
    );
  }
}

