import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../domain/budget.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.progress,
    required this.categoryName,
    required this.currencyCode,
    this.onTap,
    this.onDelete,
  });

  final BudgetProgress progress;
  final String categoryName;
  final String currencyCode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (progress.state) {
      BudgetState.normal => AppColors.primary,
      BudgetState.warning => AppColors.warning,
      BudgetState.exceeded => AppColors.exceeded,
    };
    final label = switch (progress.state) {
      BudgetState.normal => 'Normal',
      BudgetState.warning => 'Warning',
      BudgetState.exceeded => 'Exceeded',
    };
    final fraction = (progress.percentageUsed / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: ListTile(
          onTap: onTap,
          title: Text(categoryName, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Spent ${Money.format(progress.spent, currencyCode)} · Remaining ${Money.format(progress.remaining, currencyCode)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                label,
                key: Key('budget-state-$label'),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Delete budget',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}