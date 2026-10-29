import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

/// The design system's RowsSkeleton: pulsing `muted` blocks shaped like the
/// list that is loading, so the layout holds. [height] matches one row.
class RowsSkeleton extends StatefulWidget {
  const RowsSkeleton({super.key, this.rows = 4, this.height = 40});

  final int rows;
  final double height;

  @override
  State<RowsSkeleton> createState() => _RowsSkeletonState();
}

class _RowsSkeletonState extends State<RowsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
  );
  // CSS animate-pulse: opacity 1 → 0.5 → 1.
  late final Animation<double> _opacity = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: AppMotion.pulseCurve));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.of(context).secondary;
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: FadeTransition(
        opacity: _opacity,
        child: ListView.separated(
          padding: AppSpacing.screen,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.rows,
          separatorBuilder: (_, _) => AppSpacing.gap,
          itemBuilder: (_, _) => Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ),
    );
  }
}
