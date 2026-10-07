import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/presentation/budget_providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/dashboard_reader.dart';
import '../domain/dashboard_snapshot.dart';

final dashboardReaderProvider = Provider.autoDispose<DashboardReader>((ref) {
  return DashboardReader(
    ref.watch(transactionRepositoryProvider),
    ref.watch(budgetRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

final dashboardSnapshotProvider = FutureProvider.autoDispose
    .family<DashboardSnapshot, int>((ref, userId) {
      return ref.watch(dashboardReaderProvider).load(userId);
    });

class StatisticsRequest {
  const StatisticsRequest({required this.userId, required this.month});

  final int userId;
  final DateTime month;

  @override
  bool operator ==(Object other) {
    return other is StatisticsRequest &&
        other.userId == userId &&
        other.month.year == month.year &&
        other.month.month == month.month;
  }

  @override
  int get hashCode => Object.hash(userId, month.year, month.month);
}

final statisticsSnapshotProvider = FutureProvider.autoDispose
    .family<StatisticsSnapshot, StatisticsRequest>((ref, request) {
      return ref.watch(dashboardReaderProvider).loadStatistics(
        request.userId,
        request.month,
      );
    });
