import '../../../core/constants/app_constants.dart';

enum BudgetState { normal, warning, exceeded }

class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amountLimit,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final int categoryId;
  final double amountLimit;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  bool get isMonthly => period == AppConstants.monthlyPeriod;
}

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.state,
  });

  final Budget budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final BudgetState state;
}
