import '../../../core/utils/date_ranges.dart';
import '../../budgets/domain/budget.dart';
import 'dashboard_snapshot.dart';

abstract final class DashboardMath {
  static double balance({required double income, required double expenses}) {
    return income - expenses;
  }

  /// Six calendar months ending on [selected], oldest first.
  static List<DateTime> trailingMonthStarts(
    DateTime selected, {
    int count = 6,
  }) {
    final anchor = DateTime(selected.year, selected.month, 1);
    return [
      for (var offset = count - 1; offset >= 0; offset--)
        DateTime(anchor.year, anchor.month - offset, 1),
    ];
  }

  static CategoryTotal? mostExpensive(List<CategoryTotal> totals) {
    final ranked = totals.where((item) => item.amount > 0).toList()
      ..sort((a, b) {
        final byAmount = b.amount.compareTo(a.amount);
        if (byAmount != 0) {
          return byAmount;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    if (ranked.isEmpty) {
      return null;
    }
    return ranked.first;
  }

  static List<BudgetProgress> coveringDay(
    List<BudgetProgress> progress,
    DateTime day,
  ) {
    return [
      for (final item in progress)
        if (DateRanges.overlaps(
          startA: item.budget.startDate,
          endA: item.budget.endDate,
          startB: day,
          endB: day,
        ))
          item,
    ];
  }

  static double? remainingTotal(List<BudgetProgress> coveringToday) {
    if (coveringToday.isEmpty) {
      return null;
    }
    return coveringToday.fold<double>(
      0,
      (sum, item) => sum + item.remaining,
    );
  }

  static List<BudgetProgress> overlappingMonth(
    List<BudgetProgress> progress,
    DateTime month,
  ) {
    final bounds = DateRanges.monthBounds(month);
    return [
      for (final item in progress)
        if (DateRanges.overlaps(
          startA: item.budget.startDate,
          endA: item.budget.endDate,
          startB: bounds.start,
          endB: bounds.end,
        ))
          item,
    ];
  }
}
