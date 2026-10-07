import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';

class AmountBar extends StatelessWidget {
  const AmountBar({
    super.key,
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.currencyCode,
    this.color = AppColors.expense,
  });

  final String label;
  final double amount;
  final double maxAmount;
  final String currencyCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount <= 0 ? 0.0 : (amount / maxAmount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                Money.format(amount, currencyCode),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: AppMotion.duration,
            curve: AppMotion.curve,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              );
            },
          ),
        ],
      ),
    );
  }
}