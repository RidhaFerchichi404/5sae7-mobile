import '../../../core/constants/app_constants.dart';
import 'budget.dart';

abstract final class BudgetCalculator {
  static BudgetProgress progress({
    required Budget budget,
    required double spent,
  }) {
    final remaining = budget.amountLimit - spent;
    final percentage = spent / budget.amountLimit * 100;
    return BudgetProgress(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percentageUsed: percentage,
      state: _state(percentage),
    );
  }

  static BudgetState stateFor(double percentage) => _state(percentage);

  static BudgetState _state(double percentage) {
    if (percentage > 100) {
      return BudgetState.exceeded;
    }
    if (percentage >= AppConstants.warningThreshold) {
      return BudgetState.warning;
    }
    return BudgetState.normal;
  }
}
