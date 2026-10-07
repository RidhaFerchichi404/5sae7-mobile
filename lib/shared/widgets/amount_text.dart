import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.expense = false,
    this.prominent = false,
  });

  final double amount;
  final String currencyCode;
  final bool expense;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final formatted = Money.format(amount, currencyCode);
    final color = expense ? AppColors.expense : AppColors.income;
    final base = prominent
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.titleMedium;
    return Text(
      '$formatted $currencyCode',
      style: base?.copyWith(color: color, fontWeight: FontWeight.w700),
    );
  }
}
