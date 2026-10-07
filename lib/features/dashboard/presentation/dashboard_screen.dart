import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/iso_time.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/section_card.dart';
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
      padding: AppSpacing.screen,
      children: [
        FadeSlideIn(
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance', style: Theme.of(context).textTheme.titleMedium),
                AmountText(
                  key: const Key('dashboard-balance'),
                  amount: snapshot.balance,
                  currencyCode: currencyCode,
                  prominent: true,
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gap,
        FadeSlideIn(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Income',
                  amount: snapshot.monthlyIncome,
                  currencyCode: currencyCode,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
        ),
        AppSpacing.gap,
        Text(
          'All time ${Money.format(snapshot.totalIncome, currencyCode)} in · ${Money.format(snapshot.totalExpenses, currencyCode)} out',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        AppSpacing.section,
        OutlinedButton(
          key: const Key('open-statistics'),
          onPressed: onStatistics,
          child: const Text('Statistics'),
        ),
        AppSpacing.section,
        FadeSlideIn(
          index: 2,
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppSpacing.gap,
                Text(
                  snapshot.remainingBudget == null
                      ? 'No active budget'
                      : Money.format(snapshot.remainingBudget!, currencyCode),
                  key: const Key('dashboard-remaining'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final item in snapshot.attention)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.categoryName),
                    subtitle: Text(_stateLabel(item.progress.state)),
                    trailing: Text(
                      Money.format(item.progress.remaining, currencyCode),
                    ),
                  ),
              ],
            ),
          ),
        ),
        AppSpacing.section,
        Text('This month', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gap,
        if (snapshot.monthlySpending.isEmpty)
          Text(
            'No expenses this month.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (var i = 0; i < snapshot.monthlySpending.length; i++)
            FadeSlideIn(
              index: i,
              child: AmountBar(
                label: snapshot.monthlySpending[i].name,
                amount: snapshot.monthlySpending[i].amount,
                maxAmount: spendingMax,
                currencyCode: currencyCode,
              ),
            ),
        AppSpacing.section,
        Text('Recent', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gap,
        if (snapshot.recent.isEmpty)
          Text('No transactions', style: Theme.of(context).textTheme.bodySmall)
        else
          for (var i = 0; i < snapshot.recent.length; i++)
            FadeSlideIn(
              index: i,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(snapshot.recent[i].categoryName),
                subtitle: Text(
                  IsoTime.date(snapshot.recent[i].record.transactionDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: AmountText(
                  amount: snapshot.recent[i].record.amount,
                  currencyCode: currencyCode,
                  expense: snapshot.recent[i].record.isExpense,
                ),
              ),
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
        padding: const EdgeInsets.all(AppSpacing.sm),
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
