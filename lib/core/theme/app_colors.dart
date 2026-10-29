import 'package:flutter/material.dart';

/// Colours from the AI Code Reviewer design system: monochrome neutrals,
/// hue only for meaning. Budget meanings map to its severity tokens.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.card,
    required this.popover,
    required this.ink,
    required this.muted,
    required this.secondary,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.income,
    required this.expense,
    required this.warning,
    required this.exceeded,
  });

  final Color canvas; // background
  final Color card;
  final Color popover;
  final Color ink; // foreground
  final Color muted; // muted-foreground
  final Color secondary; // secondary / accent fill
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color income; // free-tier hue, emerald-700 in light for 4.5:1 text
  final Color expense; // severity-high
  final Color warning; // severity-medium
  final Color exceeded; // severity-critical

  static const light = AppColors(
    canvas: Color(0xFFFCFCFC),
    card: Color(0xFFFFFFFF),
    popover: Color(0xFFFCFCFC),
    ink: Color(0xFF000000),
    muted: Color(0xFF525252),
    secondary: Color(0xFFEBEBEB),
    border: Color(0xFFE4E4E4),
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF047857),
    expense: Color(0xFFC2410C),
    warning: Color(0xFFB45309),
    exceeded: Color(0xFFB91C1C),
  );

  static const dark = AppColors(
    canvas: Color(0xFF000000),
    card: Color(0xFF090909),
    popover: Color(0xFF121212),
    ink: Color(0xFFFFFFFF),
    muted: Color(0xFFA4A4A4),
    secondary: Color(0xFF222222),
    border: Color(0xFF242424),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    income: Color(0xFF34D399),
    expense: Color(0xFFFB923C),
    warning: Color(0xFFFBBF24),
    exceeded: Color(0xFFF87171),
  );

  /// Falls back to [light] so bare `MaterialApp`s in tests still resolve.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith() => this;

  // shortcut: snaps instead of blending, upgrade if theme switching gets animated.
  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}
