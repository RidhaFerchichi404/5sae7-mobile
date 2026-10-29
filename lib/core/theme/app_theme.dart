import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.secondary,
      onSecondary: c.ink,
      error: c.exceeded,
      onError: c.onPrimary,
      surface: c.card,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      surfaceContainerHighest: c.secondary,
      outline: c.border,
      outlineVariant: c.border,
    );
    const radiusLg = BorderRadius.all(Radius.circular(8));
    const radiusXl = BorderRadius.all(Radius.circular(12));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Geist',
      extensions: [c],
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.popover, // dropdown menus
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      // Headings semibold with -0.025em tracking; body 14px.
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: c.ink,
          fontWeight: FontWeight.w600,
          fontSize: 30,
          height: 1.2,
          letterSpacing: -0.75,
        ),
        titleLarge: TextStyle(
          color: c.ink,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          letterSpacing: -0.55,
        ),
        titleMedium: TextStyle(
          color: c.ink,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.375,
        ),
        labelLarge: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: c.ink, fontSize: 15),
        bodyMedium: TextStyle(color: c.ink, fontSize: 14, height: 1.43),
        bodySmall: TextStyle(color: c.muted, fontSize: 12, height: 1.33),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeRisePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeRisePageTransitionsBuilder(),
          TargetPlatform.linux: FadeRisePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeRisePageTransitionsBuilder(),
          TargetPlatform.windows: FadeRisePageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeRisePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: c.border)),
        titleTextStyle: TextStyle(
          fontFamily: 'Geist',
          color: c.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.45,
        ),
      ),
      // Borders, not shadows: cards are a hairline on card.
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radiusXl,
          side: BorderSide(color: c.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.muted,
        shape: const RoundedRectangleBorder(borderRadius: radiusXl),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusXl,
          side: BorderSide(color: c.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.popover,
        contentTextStyle: TextStyle(fontFamily: 'Geist', color: c.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? c.secondary.withValues(alpha: 0.3)
            : c.card,
        labelStyle: TextStyle(color: c.muted),
        hintStyle: TextStyle(color: c.muted),
        border: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: c.muted, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: c.exceeded),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusLg,
          borderSide: BorderSide(color: c.exceeded, width: 1.5),
        ),
      ),
      // 48px tall for touch, though the web system uses 32px.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.border),
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: radiusLg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(borderRadius: radiusLg),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.ink,
          shape: const RoundedRectangleBorder(borderRadius: radiusLg),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: radiusXl),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: c.secondary,
          selectedForegroundColor: c.ink,
          foregroundColor: c.muted,
          side: BorderSide(color: c.border),
          shape: const RoundedRectangleBorder(borderRadius: radiusLg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.secondary,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
      ),
      // Off state in muted so the control keeps 3:1 against card.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.muted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.muted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.secondary,
        indicatorShape: const RoundedRectangleBorder(borderRadius: radiusLg),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Geist',
            color: selected ? c.ink : c.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? c.ink : c.muted);
        }),
      ),
    );
  }
}
