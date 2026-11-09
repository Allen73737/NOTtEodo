import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/widget_sync_service.dart';
import '../state/app_settings.dart';

/// The two ways the app can look. Stored as `cardStyle` ('editorial' / 'bento').
String viewStyleName(String cardStyle) => cardStyle == 'editorial' ? 'Editorial' : 'Cards';

String viewStyleDescription(String cardStyle) => cardStyle == 'editorial'
    ? 'Words on paper. No boxes or borders, just type, space and gentle motion.'
    : 'Every item in its own card, with colour, texture and depth.';

String otherViewStyle(String cardStyle) => cardStyle == 'editorial' ? 'bento' : 'editorial';

/// Whether the editorial view is on. Kept in sync with settings by the app root so
/// plain functions like [edBox] can read it during build.
abstract final class EditorialMode {
  static bool active = false;

  // Look-and-feel choices from Settings, applied by the app root before each build.
  static String accent = 'terracotta';
  static String headlineFamily = 'Bodoni Moda';
  static double rowPadding = 13;
  static bool swipeActions = true;
  static bool confirmDeletes = false;
  static bool celebrate = true;

  /// Copies the current preferences into the statics above.
  static void apply(AppSettings s) {
    final p = UiPrefs.of(s);
    active = s.cardStyle == 'editorial';
    accent = p.accent;
    headlineFamily = UiPrefs.headlines[p.headline] ?? 'Bodoni Moda';
    rowPadding = p.rowPadding;
    swipeActions = p.swipeActions;
    confirmDeletes = p.confirmDeletes;
    celebrate = p.celebrate;
  }
}

/// Accent choices as (light, dark) pairs, each at least 4.5:1 on its page colour.
const Map<String, (Color, Color)> accentColors = {
  'terracotta': (Color(0xFFAD4E38), Color(0xFFE8927C)),
  'ink': (Color(0xFF1C1917), Color(0xFFF6F3ED)),
  'olive': (Color(0xFF55652B), Color(0xFFB9C77E)),
  'plum': (Color(0xFF7A3B5E), Color(0xFFD9A0C4)),
  'gold': (Color(0xFF85660F), Color(0xFFE8C872)),
};

Color accentFor(bool dark) {
  final pair = accentColors[EditorialMode.accent] ?? accentColors['terracotta']!;
  return dark ? pair.$2 : pair.$1;
}

/// Switches between the editorial and card views from anywhere, then rebuilds
/// every widget so decorations made with [edBox] pick up the change at once.
void toggleViewStyle(BuildContext context, WidgetRef ref, {String? to}) {
  final next = to ?? otherViewStyle(ref.read(appSettingsProvider).cardStyle);
  HapticFeedback.mediumImpact();
  ref.read(appSettingsProvider.notifier).setCardStyle(next);
  EditorialMode.active = next == 'editorial';
  WidgetSyncService.setStyle(next);
  rebuildAllWidgets(context);
}

/// Marks the whole widget tree for rebuild, from the root down.
void rebuildAllWidgets(BuildContext context) {
  void mark(Element e) {
    e.markNeedsBuild();
    e.visitChildren(mark);
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final root = WidgetsBinding.instance.rootElement;
    if (root != null) mark(root);
  });
}

/// A neutral page or card colour: almost no hue, and very light or very dark.
bool _isSurface(Color c) {
  final r = c.r, g = c.g, b = c.b;
  final maxC = math.max(r, math.max(g, b)), minC = math.min(r, math.min(g, b));
  final lightness = (maxC + minC) / 2;
  return maxC - minC < 0.09 && (lightness > 0.8 || lightness < 0.17);
}

/// A [BoxDecoration] that follows the view style.
///
/// In the card view it is exactly the decoration described. In the editorial view
/// the surface goes away: shadows always, borders unless they mark a circle or an
/// accent, neutral fills and faint tints. Meaningful colour stays: accent fills,
/// progress bars, swatches, images and circles (dots, avatars, toggles).
BoxDecoration edBox({
  Color? color,
  DecorationImage? image,
  BoxBorder? border,
  BorderRadiusGeometry? borderRadius,
  List<BoxShadow>? boxShadow,
  Gradient? gradient,
  BlendMode? backgroundBlendMode,
  BoxShape shape = BoxShape.rectangle,
}) {
  if (!EditorialMode.active) {
    return BoxDecoration(
      color: color,
      image: image,
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape,
    );
  }
  final circle = shape == BoxShape.circle;
  bool faint(Color c) => c.a < 0.22;
  bool plain(Color c) => _isSurface(c) || (!circle && faint(c));

  BoxBorder? keptBorder;
  if (border is Border && (circle || !_isSurface(border.top.color) && !faint(border.top.color))) {
    keptBorder = circle ? border : Border.all(color: border.top.color, width: math.min(border.top.width, 1));
  }
  final keptGradient = gradient != null && gradient.colors.any((c) => !plain(c)) ? gradient : null;
  return BoxDecoration(
    color: color != null && !plain(color) ? color : null,
    image: image,
    border: keptBorder,
    borderRadius: circle ? null : borderRadius,
    gradient: keptGradient,
    backgroundBlendMode: backgroundBlendMode,
    shape: shape,
  );
}

/// The Material theme with every container flattened, for the editorial view.
ThemeData editorialTheme(ThemeData base) {
  final dark = base.brightness == Brightness.dark;
  final paper = base.scaffoldBackgroundColor;
  final ink = dark ? const Color(0xFFF6F3ED) : const Color(0xFF1C1917);
  final accent = accentFor(dark);
  const none = BorderSide.none;
  const flat = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)));
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(secondary: accent),
    textSelectionTheme: base.textSelectionTheme.copyWith(cursorColor: accent, selectionHandleColor: accent),
    cardTheme: base.cardTheme.copyWith(color: Colors.transparent, elevation: 0, shadowColor: Colors.transparent, shape: const RoundedRectangleBorder()),
    dialogTheme: base.dialogTheme.copyWith(backgroundColor: paper, elevation: 0, shape: flat),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: paper, modalBackgroundColor: paper, elevation: 0),
    popupMenuTheme: base.popupMenuTheme.copyWith(color: paper, elevation: 2, shape: flat),
    dividerTheme: base.dividerTheme.copyWith(color: Colors.transparent, thickness: 0),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    ),
    chipTheme: base.chipTheme.copyWith(backgroundColor: Colors.transparent, side: none, elevation: 0, selectedColor: accent.withValues(alpha: 0.12)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: ink, side: none, shape: const StadiumBorder()),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: ink, foregroundColor: paper, shape: const StadiumBorder()),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: paper, shape: const StadiumBorder())),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
    listTileTheme: base.listTileTheme.copyWith(tileColor: Colors.transparent, shape: const RoundedRectangleBorder()),
    appBarTheme: base.appBarTheme.copyWith(backgroundColor: paper, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent),
    navigationBarTheme: base.navigationBarTheme.copyWith(backgroundColor: paper, elevation: 0, indicatorColor: Colors.transparent),
    snackBarTheme: base.snackBarTheme.copyWith(backgroundColor: ink, elevation: 0),
  );
}
