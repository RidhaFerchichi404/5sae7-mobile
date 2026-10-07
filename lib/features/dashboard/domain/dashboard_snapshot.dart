import '../../budgets/domain/budget.dart';
import '../../transactions/domain/transaction_record.dart';

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.amount,
  });

  final int categoryId;
  final String name;
  final double amount;
}

class RecentActivity {
  const RecentActivity({required this.record, required this.categoryName});

  final TransactionRecord record;
  final String categoryName;
}

class BudgetAttention {
  const BudgetAttention({required this.progress, required this.categoryName});

  final BudgetProgress progress;
  final String categoryName;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.remainingBudget,
    required this.attention,
    required this.recent,
    required this.monthlySpending,
  });

  final double balance;
  final double totalIncome;
  final double totalExpenses;
  final double monthlyIncome;
  final double monthlyExpenses;

  /// Null when no budget covers today.
  final double? remainingBudget;
  final List<BudgetAttention> attention;
  final List<RecentActivity> recent;
  final List<CategoryTotal> monthlySpending;
}

class MonthPoint {
  const MonthPoint({
    required this.month,
    required this.income,
    required this.expenses,
  });

  final DateTime month;
  final double income;
  final double expenses;
}

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.month,
    required this.expensesByCategory,
    required this.series,
    required this.income,
    required this.expenses,
    required this.mostExpensive,
    required this.budgetConsumption,
  });

  final DateTime month;
  final List<CategoryTotal> expensesByCategory;
  final List<MonthPoint> series;
  final double income;
  final double expenses;
  final CategoryTotal? mostExpensive;
  final List<BudgetAttention> budgetConsumption;
}
