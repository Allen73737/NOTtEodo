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
        return 'Atelier Vibe of the Day';
      case AestheticWidgetType.vaultTreasury:
        return 'Sovereign Treasury Ledger';
      case AestheticWidgetType.voiceMemoir:
        return 'Vintage Voice Tape';
      case AestheticWidgetType.airmailTravel:
        return 'Airmail Travel Pass';
      case AestheticWidgetType.horologyClock:
        return 'Guilloché Horology Clock';
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
        return 'MEMOIRS';
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
  matchaSage,
  terracottaClay,
  kraftLinen;

  String get displayName {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return 'Warm Cream';
      case AestheticPaperTheme.slateNoir:
        return 'Slate Noir';
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
        return const Color(0xFFFEF9EE);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFF16282C);
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
        return const Color(0xFFF4EDE0);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFF22353A);
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
        return const Color(0xFF16282C);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFFFEF9EE);
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
        return const Color(0xFF6B7678);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFFA1AFB2);
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
        return const Color(0xFF9C432F);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFFE07A5F);
      case AestheticPaperTheme.matchaSage:
        return const Color(0xFF386B52);
      case AestheticPaperTheme.terracottaClay:
        return const Color(0xFF9C432F);
      case AestheticPaperTheme.kraftLinen:
        return const Color(0xFF8A5A2B);
    }
  }

  Color get borderColor {
    switch (this) {
      case AestheticPaperTheme.warmCream:
        return const Color(0xFF16282C);
      case AestheticPaperTheme.slateNoir:
        return const Color(0xFF4A5F63);
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
        return const Color(0xFF16282C);
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
    this.stampLabel = 'CURATED',
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
}

