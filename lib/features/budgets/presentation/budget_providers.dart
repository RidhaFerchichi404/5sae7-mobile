import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/api_client.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../data/budget_repository.dart';
import '../data/season_client.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

final seasonClientProvider = Provider<SeasonClient>((ref) {
  return SeasonClient(ref.watch(apiClientProvider));
});

/// Holidays and Ramadan inside a budget period, keyed by (start, end).
final budgetSeasonProvider =
    FutureProvider.family<List<String>, (DateTime, DateTime)>((ref, period) {
      return ref.watch(seasonClientProvider).notes(period.$1, period.$2);
    });

final budgetListProvider = FutureProvider.family<List<BudgetProgress>, int>((
  ref,
  userId,
) {
  return ref.watch(budgetRepositoryProvider).listWithProgress(userId);
});
