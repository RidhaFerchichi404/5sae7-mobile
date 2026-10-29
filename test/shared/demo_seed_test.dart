import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budgets/data/budget_repository.dart';
import 'package:mybudget/features/budgets/domain/budget.dart';
import 'package:mybudget/features/categories/data/category_repository.dart';
import 'package:mybudget/features/transactions/data/transaction_repository.dart';
import 'package:mybudget/features/transactions/domain/transaction_query.dart';
import 'package:mybudget/features/users/data/user_repository.dart';
import 'package:mybudget/shared/demo/demo_seed.dart';

import '../support/test_database.dart';

void main() {
  setUpAll(initTestDatabase);

  for (final today in [
    DateTime(2026, 10, 1),
    DateTime(2026, 10, 20),
    DateTime(2026, 10, 31),
  ]) {
    test(
      'demo seed on ${today.day} October: six months, every budget state',
      () async {
        final database = openTestDatabase();
        addTearDown(database.close);
        final categories = CategoryRepository(database);
        final transactions = TransactionRepository(database, categories);
        final budgets = BudgetRepository(database, categories, transactions);

        final user = await DemoSeed(
          users: UserRepository(database),
          categories: categories,
          transactions: transactions,
          budgets: budgets,
          today: today,
        ).run();

        final rows = await transactions.search(
          TransactionQuery(userId: user.id),
        );
        expect(rows.length, greaterThan(100));
        expect(
          rows.every((row) => !row.transactionDate.isAfter(today)),
          isTrue,
        );
        final months = {
          for (final row in rows)
            DateTime(row.transactionDate.year, row.transactionDate.month),
        };
        expect(months, hasLength(6));
        expect(rows.where((row) => row.type == 'INCOME'), isNotEmpty);

        final progress = await budgets.listWithProgress(user.id);
        expect(progress, hasLength(5));
        expect(
          progress.map((item) => item.state).toSet(),
          BudgetState.values.toSet(),
        );
      },
    );
  }
}
