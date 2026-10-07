import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../users/presentation/user_providers.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_query.dart';
import '../domain/transaction_record.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final transactionListProvider =
    FutureProvider.family<List<TransactionRecord>, TransactionQuery>((
      ref,
      query,
    ) {
      return ref.watch(transactionRepositoryProvider).search(query);
    });
