import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.expense = false,
  });

  final double amount;
  final String currencyCode;
  final bool expense;

  @override
  Widget build(BuildContext context) {
    final formatted = Money.format(amount, currencyCode);
    return Text(
      '$formatted $currencyCode',
      style: TextStyle(
        color: expense ? AppColors.expense : AppColors.income,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
