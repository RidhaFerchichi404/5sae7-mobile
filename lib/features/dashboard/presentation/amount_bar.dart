import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(Money.format(amount, currencyCode)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
