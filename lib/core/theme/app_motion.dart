import 'package:flutter/material.dart';

/// Motion from the design system's dashboard side: short and functional.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 100); // dialogs
  static const duration = Duration(milliseconds: 150); // controls, tabs
  static const slow = Duration(milliseconds: 200); // sheets, pages
  static const pulse = Duration(seconds: 2); // skeletons

  static const stagger = Duration(milliseconds: 40);
  static const maxStaggerSteps = 8;

  static const curve = Cubic(0.4, 0, 0.2, 1); // ease-in-out
  static const enter = Cubic(0, 0, 0.2, 1); // ease-out
  static const pulseCurve = Cubic(0.4, 0, 0.6, 1);

  /// True when the user asked the OS to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Pages enter like the system's Sheet: a 40px rise while fading in.
class FadeRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeRisePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) {
      return child;
    }
    // MaterialPageRoute runs for 300ms; the Interval finishes the move in 200ms.
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 2 / 3, curve: AppMotion.enter),
      reverseCurve: const Interval(1 / 3, 1, curve: AppMotion.curve),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}
