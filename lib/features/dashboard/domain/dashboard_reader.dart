import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_ranges.dart';
import '../../../core/utils/iso_time.dart';
import '../../budgets/data/budget_repository.dart';
import '../../budgets/domain/budget.dart';
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import 'dashboard_math.dart';
import 'dashboard_snapshot.dart';

class DashboardReader {
  DashboardReader(this._transactions, this._budgets, this._categories);

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final CategoryRepository _categories;

  Future<DashboardSnapshot> load(int userId, {DateTime? today}) async {
    final day = today ?? IsoTime.now();
    final month = DateRanges.monthBounds(day);
    final totalIncome = await _transactions.sum(
      userId: userId,
      type: AppConstants.incomeType,
    );
    final totalExpenses = await _transactions.sum(
      userId: userId,
      type: AppConstants.expenseType,
    );
    final monthlyIncome = await _transactions.sum(
      userId: userId,
      type: AppConstants.incomeType,
      start: month.start,
      end: month.end,
    );
    final monthlyExpenses = await _transactions.sum(
      userId: userId,
      type: AppConstants.expenseType,
      start: month.start,
      end: month.end,
    );
    final names = await _names(userId);
    final spending = _totals(
      await _transactions.sumByCategory(
        userId: userId,
        type: AppConstants.expenseType,
        start: month.start,
        end: month.end,
      ),
      names,
    );
    final progress = await _budgets.listWithProgress(userId);
    final active = DashboardMath.coveringDay(progress, day);
    final recent = await _transactions.listRecent(userId);
    return DashboardSnapshot(
      balance: DashboardMath.balance(
        income: totalIncome,
        expenses: totalExpenses,
      ),
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      remainingBudget: DashboardMath.remainingTotal(active),
      attention: [
        for (final item in active)
          if (item.state != BudgetState.normal)
            BudgetAttention(
              progress: item,
              categoryName: names[item.budget.categoryId] ?? 'Category',
            ),
      ],
      recent: [
        for (final record in recent)
          RecentActivity(
            record: record,
            categoryName: names[record.categoryId] ?? record.type,
          ),
      ],
      monthlySpending: spending,
    );
  }

  Future<StatisticsSnapshot> loadStatistics(int userId, DateTime month) async {
    final bounds = DateRanges.monthBounds(month);
    final names = await _names(userId);
    final series = <MonthPoint>[];
    for (final start in DashboardMath.trailingMonthStarts(month)) {
      final range = DateRanges.monthBounds(start);
      series.add(
        MonthPoint(
          month: range.start,
          income: await _transactions.sum(
            userId: userId,
            type: AppConstants.incomeType,
            start: range.start,
            end: range.end,
          ),
          expenses: await _transactions.sum(
            userId: userId,
            type: AppConstants.expenseType,
            start: range.start,
            end: range.end,
          ),
        ),
      );
    }
    final byCategory = _totals(
      await _transactions.sumByCategory(
        userId: userId,
        type: AppConstants.expenseType,
        start: bounds.start,
        end: bounds.end,
      ),
      names,
    );
    final progress = await _budgets.listWithProgress(userId);
    return StatisticsSnapshot(
      month: bounds.start,
      expensesByCategory: byCategory,
      series: series,
      income: await _transactions.sum(
        userId: userId,
        type: AppConstants.incomeType,
        start: bounds.start,
        end: bounds.end,
      ),
      expenses: await _transactions.sum(
        userId: userId,
        type: AppConstants.expenseType,
        start: bounds.start,
        end: bounds.end,
      ),
      mostExpensive: DashboardMath.mostExpensive(byCategory),
      budgetConsumption: [
        for (final item in DashboardMath.overlappingMonth(progress, month))
          BudgetAttention(
            progress: item,
            categoryName: names[item.budget.categoryId] ?? 'Category',
          ),
      ],
    );
  }

  Future<Map<int, String>> _names(int userId) async {
    final categories = await _categories.list(userId: userId);
    return {
      for (final category in categories) category.id: category.name,
    };
  }

  List<CategoryTotal> _totals(Map<int, double> sums, Map<int, String> names) {
    final totals = [
      for (final entry in sums.entries)
        if (entry.value > 0)
          CategoryTotal(
            categoryId: entry.key,
            name: names[entry.key] ?? 'Category',
            amount: entry.value,
          ),
    ];
    totals.sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      if (byAmount != 0) {
        return byAmount;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return totals;
  }
}
