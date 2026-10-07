import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(categoryName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: fraction,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(
              'Spent ${Money.format(progress.spent, currencyCode)} · Remaining ${Money.format(progress.remaining, currencyCode)}',
            ),
            Text(label, key: Key('budget-state-$label'), style: TextStyle(color: color)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
