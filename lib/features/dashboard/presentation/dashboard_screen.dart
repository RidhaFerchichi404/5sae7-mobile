import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/iso_time.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../budgets/domain/budget.dart';
import '../../users/domain/user_profile.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/dashboard_snapshot.dart';
import 'amount_bar.dart';
import 'dashboard_providers.dart';
import 'statistics_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.userId});

  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeUserIdProvider);
    final resolved = userId ?? active.value;
    if (userId == null && active.isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }
    if (resolved == null) {
      return const Scaffold(
        body: ErrorView(message: 'Choose a profile first.'),
      );
    }
    final snapshot = ref.watch(dashboardSnapshotProvider(resolved));
    final currency = ref.watch(userListProvider).maybeWhen(
      data: (users) => _currencyOf(users, resolved),
      orElse: () => AppConstants.defaultCurrency,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: snapshot.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dashboardSnapshotProvider(resolved)),
        ),
        data: (data) => _DashboardBody(
          snapshot: data,
          currencyCode: currency,
          onStatistics: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StatisticsScreen(userId: resolved),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.snapshot,
    required this.currencyCode,
    required this.onStatistics,
  });

  final DashboardSnapshot snapshot;
  final String currencyCode;
  final VoidCallback onStatistics;

  @override
  Widget build(BuildContext context) {
    final spendingMax = snapshot.monthlySpending.fold<double>(
      0,
      (max, item) => item.amount > max ? item.amount : max,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Balance', style: Theme.of(context).textTheme.titleMedium),
        AmountText(
          key: const Key('dashboard-balance'),
          amount: snapshot.balance,
          currencyCode: currencyCode,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Figure(
                label: 'Income',
                amount: snapshot.monthlyIncome,
                currencyCode: currencyCode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Figure(
                label: 'Expenses',
                amount: snapshot.monthlyExpenses,
                currencyCode: currencyCode,
                expense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'All time ${Money.format(snapshot.totalIncome, currencyCode)} in · ${Money.format(snapshot.totalExpenses, currencyCode)} out',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Text('Remaining budget', style: Theme.of(context).textTheme.titleMedium),
        Text(
          snapshot.remainingBudget == null
              ? 'No active budget'
              : Money.format(snapshot.remainingBudget!, currencyCode),
          key: const Key('dashboard-remaining'),
        ),
        if (snapshot.attention.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final item in snapshot.attention)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.categoryName),
              subtitle: Text(_stateLabel(item.progress.state)),
              trailing: Text(Money.format(item.progress.remaining, currencyCode)),
            ),
        ],
        const SizedBox(height: 8),
        Text('This month', style: Theme.of(context).textTheme.titleMedium),
        if (snapshot.monthlySpending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No expenses this month.'),
          )
        else
          for (final item in snapshot.monthlySpending)
            AmountBar(
              label: item.name,
              amount: item.amount,
              maxAmount: spendingMax,
              currencyCode: currencyCode,
            ),
        const SizedBox(height: 8),
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        if (snapshot.recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No transactions'),
          )
        else
          for (final item in snapshot.recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.categoryName),
              subtitle: Text(IsoTime.date(item.record.transactionDate)),
              trailing: AmountText(
                amount: item.record.amount,
                currencyCode: currencyCode,
                expense: item.record.isExpense,
              ),
            ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('open-statistics'),
          onPressed: onStatistics,
          child: const Text('Statistics'),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amount,
    required this.currencyCode,
    this.expense = false,
  });

  final String label;
  final double amount;
  final String currencyCode;
  final bool expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            AmountText(
              amount: amount,
              currencyCode: currencyCode,
              expense: expense,
            ),
          ],
        ),
      ),
    );
  }
}

String _stateLabel(BudgetState state) {
  return switch (state) {
    BudgetState.warning => 'Warning',
    BudgetState.exceeded => 'Exceeded',
    BudgetState.normal => 'Normal',
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
