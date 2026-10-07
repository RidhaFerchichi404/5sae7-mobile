import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../budgets/domain/budget.dart';
import '../../users/domain/user_profile.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/dashboard_snapshot.dart';
import 'amount_bar.dart';
import 'dashboard_providers.dart';
import 'month_label.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key, this.userId});

  final int? userId;

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.userId ?? ref.watch(activeUserIdProvider).value;
    if (resolved == null) {
      return const Scaffold(
        body: ErrorView(message: 'Choose a profile first.'),
      );
    }
    final request = StatisticsRequest(userId: resolved, month: _month);
    final snapshot = ref.watch(statisticsSnapshotProvider(request));
    final currency = ref.watch(userListProvider).maybeWhen(
      data: (users) => _currencyOf(users, resolved),
      orElse: () => AppConstants.defaultCurrency,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(formatMonth(_month), key: const Key('statistics-month')),
              IconButton(
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Expanded(
            child: snapshot.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (data) => _StatisticsBody(snapshot: data, currencyCode: currency),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.snapshot, required this.currencyCode});

  final StatisticsSnapshot snapshot;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final categoryMax = snapshot.expensesByCategory.fold<double>(
      0,
      (max, item) => item.amount > max ? item.amount : max,
    );
    final seriesMax = snapshot.series.fold<double>(0, (max, point) {
      final peak = point.expenses > point.income ? point.expenses : point.income;
      return peak > max ? peak : max;
    });
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('Income versus expenses', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AmountBar(
          label: 'Income',
          amount: snapshot.income,
          maxAmount: _peak(snapshot.income, snapshot.expenses),
          currencyCode: currencyCode,
          color: AppColors.income,
        ),
        AmountBar(
          label: 'Expenses',
          amount: snapshot.expenses,
          maxAmount: _peak(snapshot.income, snapshot.expenses),
          currencyCode: currencyCode,
        ),
        const SizedBox(height: 16),
        Text('Most expensive', style: Theme.of(context).textTheme.titleMedium),
        Text(
          snapshot.mostExpensive == null
              ? 'No expenses this month.'
              : '${snapshot.mostExpensive!.name} · ${Money.format(snapshot.mostExpensive!.amount, currencyCode)}',
          key: const Key('most-expensive'),
        ),
        const SizedBox(height: 16),
        Text('Expenses by category', style: Theme.of(context).textTheme.titleMedium),
        if (snapshot.expensesByCategory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No expenses this month.'),
          )
        else
          for (final item in snapshot.expensesByCategory)
            AmountBar(
              label: item.name,
              amount: item.amount,
              maxAmount: categoryMax,
              currencyCode: currencyCode,
            ),
        const SizedBox(height: 16),
        Text('Spending evolution', style: Theme.of(context).textTheme.titleMedium),
        for (final point in snapshot.series)
          AmountBar(
            label: formatMonth(point.month),
            amount: point.expenses,
            maxAmount: seriesMax,
            currencyCode: currencyCode,
          ),
        const SizedBox(height: 16),
        Text('Budget consumption', style: Theme.of(context).textTheme.titleMedium),
        if (snapshot.budgetConsumption.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No budget overlaps this month.'),
          )
        else
          for (final item in snapshot.budgetConsumption)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.categoryName),
              subtitle: Text(_stateLabel(item.progress.state)),
              trailing: Text(
                '${item.progress.percentageUsed.toStringAsFixed(0)}%',
              ),
            ),
      ],
    );
  }
}

double _peak(double a, double b) {
  final peak = a > b ? a : b;
  return peak == 0 ? 1 : peak;
}

String _stateLabel(BudgetState state) {
  return switch (state) {
    BudgetState.normal => 'Normal',
    BudgetState.warning => 'Warning',
    BudgetState.exceeded => 'Exceeded',
  };
}

String _currencyOf(List<UserProfile> users, int userId) {
  for (final user in users) {
    if (user.id == userId) {
      return user.currency;
    }
  }
  return AppConstants.defaultCurrency;
}
