import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Component styling shared by the light and dark themes, so every switch, segmented
/// control, dialog, sheet, field and button in the app matches the cards: no outlines,
/// soft fills, oxblood for the one thing that is on or chosen.
abstract class AppComponentTheme {
  static ThemeData apply(ThemeData base, {required bool dark}) {
    final ink = dark ? const Color(0xFFF6F3ED) : const Color(0xFF1A1614);
    final muted = dark ? const Color(0xFFA89C9C) : const Color(0xFF6B605A);
    final mark = dark ? const Color(0xFFD0485A) : const Color(0xFF7A1F2B);
    final fill = dark ? const Color(0xFF8E2433) : const Color(0xFF7A1F2B);
    final onFill = dark ? const Color(0xFFF6F3ED) : Colors.white;
    final track = dark ? const Color(0xFF2A1F21) : const Color(0xFFEADFD9);
    final hairline = dark ? const Color(0xFF221C1D) : const Color(0xFFEDE6DF);
    final surface = dark ? const Color(0xFF0F0D0D) : Colors.white;
    final field = dark ? const Color(0xFF161313) : const Color(0xFFF4EFE9);
    final sans = GoogleFonts.dmSans();
    final shape14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return base.copyWith(
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 24),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? onFill : (dark ? const Color(0xFF8A7F7F) : Colors.white)),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? fill : track),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? fill : Colors.transparent),
        checkColor: WidgetStatePropertyAll(onFill),
        side: BorderSide(color: muted.withValues(alpha: 0.6), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? fill : muted)),
      sliderTheme: SliderThemeData(
        activeTrackColor: fill,
        inactiveTrackColor: track,
        thumbColor: fill,
        overlayColor: fill.withValues(alpha: 0.12),
        trackHeight: 3,
        valueIndicatorColor: fill,
        valueIndicatorTextStyle: sans.copyWith(color: onFill, fontWeight: FontWeight.w600),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: mark, linearTrackColor: track, circularTrackColor: Colors.transparent),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? fill : field),
          foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? onFill : ink),
          side: const WidgetStatePropertyAll(BorderSide.none),
          textStyle: WidgetStatePropertyAll(sans.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          shape: WidgetStatePropertyAll(shape14),
          visualDensity: VisualDensity.compact,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: onFill,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: onFill,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: field,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: mark, textStyle: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: sans.copyWith(color: muted, fontSize: 14.5),
        labelStyle: sans.copyWith(color: muted),
        floatingLabelStyle: sans.copyWith(color: mark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: mark, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: base.colorScheme.error, width: 1.2)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: field,
        selectedColor: fill,
        secondarySelectedColor: fill,
        labelStyle: sans.copyWith(color: ink, fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: sans.copyWith(color: onFill, fontSize: 13, fontWeight: FontWeight.w600),
        checkmarkColor: onFill,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      // Behind a dialog or sheet the page goes fully opaque (pitch black or ivory), so
      // nothing underneath bleeds through; a hairline keeps the dialog's edge visible.
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: base.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: BorderSide(color: hairline)),
        titleTextStyle: GoogleFonts.bodoniModa(fontSize: 24, fontWeight: FontWeight.w700, color: ink, height: 1.15),
        contentTextStyle: sans.copyWith(fontSize: 14.5, color: muted, height: 1.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        modalBarrierColor: base.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.6 : 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: sans.copyWith(fontSize: 14, color: ink),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFF1A1616) : const Color(0xFF1A1614),
        contentTextStyle: sans.copyWith(color: const Color(0xFFF6F3ED), fontSize: 14),
        actionTextColor: const Color(0xFFD0485A),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: dark ? const Color(0xFF2A2424) : const Color(0xFF1A1614), borderRadius: BorderRadius.circular(8)),
        textStyle: sans.copyWith(color: const Color(0xFFF6F3ED), fontSize: 12.5),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        titleTextStyle: sans.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: ink),
        subtitleTextStyle: sans.copyWith(fontSize: 12.5, color: muted),
        shape: shape14,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.bodoniModa(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: muted,
        indicatorColor: mark,
        dividerColor: Colors.transparent,
        labelStyle: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: sans.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
