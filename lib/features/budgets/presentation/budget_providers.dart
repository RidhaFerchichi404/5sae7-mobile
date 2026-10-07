import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

final budgetListProvider = FutureProvider.family<List<BudgetProgress>, int>((
  ref,
  userId,
) {
  return ref.watch(budgetRepositoryProvider).listWithProgress(userId);
});
