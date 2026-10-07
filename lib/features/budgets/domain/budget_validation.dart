import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_ranges.dart';
import '../../../core/utils/iso_time.dart';
import '../../../core/utils/money.dart';
import '../../categories/domain/category.dart';

class BudgetInput {
  const BudgetInput({
    required this.limitText,
    required this.currencyCode,
    required this.period,
    required this.startText,
    required this.endText,
    required this.category,
    required this.userId,
  });

  final String limitText;
  final String currencyCode;
  final String period;
  final String startText;
  final String endText;
  final Category? category;
  final int userId;
}

class BudgetValidationResult {
  const BudgetValidationResult({
    required this.limit,
    required this.period,
    required this.categoryId,
    required this.start,
    required this.end,
    this.limitError,
    this.categoryError,
    this.dateError,
    this.periodError,
  });

  final double limit;
  final String period;
  final int categoryId;
  final DateTime start;
  final DateTime end;
  final String? limitError;
  final String? categoryError;
  final String? dateError;
  final String? periodError;

  bool get isValid =>
      limitError == null &&
      categoryError == null &&
      dateError == null &&
      periodError == null;

  String? get message =>
      limitError ?? categoryError ?? dateError ?? periodError;
}

BudgetValidationResult validateBudgetInput(BudgetInput input) {
  final limitText = input.limitText.trim().replaceAll(',', '.');
  final limit = double.tryParse(limitText);
  String? limitError;
  if (limit == null || limit.isNaN || limit.isInfinite || limit <= 0) {
    limitError = 'Enter a limit greater than zero.';
  } else {
    final dot = limitText.indexOf('.');
    if (dot != -1 &&
        limitText.length - dot - 1 > Money.decimalScale(input.currencyCode)) {
      limitError =
          'Use at most ${Money.decimalScale(input.currencyCode)} decimal places.';
    }
  }

  String? categoryError;
  final category = input.category;
  if (category == null) {
    categoryError = 'Choose an expense category.';
  } else if (category.userId != input.userId) {
    categoryError = 'Choose a category from this profile.';
  } else if (category.type != AppConstants.expenseType) {
    categoryError = 'Budgets apply only to expense categories.';
  }

  final start = IsoTime.tryParseDate(input.startText.trim());
  final end = IsoTime.tryParseDate(input.endText.trim());
  String? dateError;
  if (start == null || end == null) {
    dateError = 'Enter valid dates.';
  } else if (end.isBefore(start)) {
    dateError = 'The end date must be on or after the start date.';
  } else if (input.period == AppConstants.monthlyPeriod) {
    final bounds = DateRanges.monthBounds(start);
    if (start != bounds.start || end != bounds.end) {
      dateError = 'A monthly budget must cover one calendar month.';
    }
  }

  String? periodError;
  if (!AppConstants.budgetPeriods.contains(input.period)) {
    periodError = 'Choose a monthly or custom period.';
  }

  return BudgetValidationResult(
    limit: limit ?? 0,
    period: input.period,
    categoryId: category?.id ?? 0,
    start: start ?? DateTime(1970),
    end: end ?? DateTime(1970),
    limitError: limitError,
    categoryError: categoryError,
    dateError: dateError,
    periodError: periodError,
  );
}
