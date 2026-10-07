import 'package:flutter/widgets.dart';

/// 8-point spacing used by every screen.
abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;

  static const screen = EdgeInsets.all(sm);
  static const gap = SizedBox(height: xs);
  static const section = SizedBox(height: md);
}
