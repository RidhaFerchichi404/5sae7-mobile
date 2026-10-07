import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/app_constants.dart';
import 'package:mybudget/core/database/database_provider.dart';
import 'package:mybudget/core/utils/date_ranges.dart';
import 'package:mybudget/core/utils/iso_time.dart';
import 'package:mybudget/features/budgets/data/budget_repository.dart';
import 'package:mybudget/features/budgets/domain/budget.dart';
import 'package:mybudget/features/budgets/domain/budget_calculator.dart';
import 'package:mybudget/features/budgets/domain/budget_validation.dart';
import 'package:mybudget/features/categories/data/category_repository.dart';
import 'package:mybudget/features/categories/domain/category.dart';
import 'package:mybudget/features/categories/domain/category_validation.dart';
import 'package:mybudget/features/dashboard/domain/dashboard_math.dart';
import 'package:mybudget/features/dashboard/domain/dashboard_reader.dart';
import 'package:mybudget/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:mybudget/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mybudget/features/transactions/data/transaction_repository.dart';
import 'package:mybudget/features/transactions/domain/transaction_validation.dart';
import 'package:mybudget/features/users/data/user_repository.dart';
import 'package:mybudget/features/users/domain/user_validation.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

void main() {
  setUpAll(initTestDatabase);

  test('balance subtracts expenses from income', () {
    expect(DashboardMath.balance(income: 500, expenses: 130), 370);
  });

  test('the statistics window is six months ending on the selected month', () {
    final months = DashboardMath.trailingMonthStarts(DateTime(2026, 3, 18));
    expect(months, hasLength(6));
    expect(months.first, DateTime(2025, 10, 1));
    expect(months.last, DateTime(2026, 3, 1));
  });

  test('a tie for most expensive category uses the name in ascending order', () {
    final winner = DashboardMath.mostExpensive(const [
      CategoryTotal(categoryId: 2, name: 'Transport', amount: 50),
      CategoryTotal(categoryId: 1, name: 'Food', amount: 50),
    ]);
    expect(winner?.name, 'Food');
  });

  test('a budget outside today is left out of the remaining total', () {
    final old = BudgetCalculator.progress(
      budget: Budget(
        id: 1,
        userId: 1,
        categoryId: 1,
        amountLimit: 100,
        period: 'CUSTOM',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 31),
        createdAt: DateTime(2020, 1, 1),
      ),
      spent: 10,
    );
    final covering = DashboardMath.coveringDay([old], DateTime(2026, 3, 1));
    expect(covering, isEmpty);
    expect(DashboardMath.remainingTotal(covering), isNull);
  });

  test('demo path matches dashboard and statistics figures', () async {
    final database = openTestDatabase();
    final users = UserRepository(database);
    final categories = CategoryRepository(database);
    final transactions = TransactionRepository(database, categories);
    final budgets = BudgetRepository(database, categories, transactions);
    final reader = DashboardReader(transactions, budgets, categories);
    final today = DateTime.now();
    final month = DateRanges.monthBounds(today);
    final date = IsoTime.date(today);

    final user = await users.create(
      validateUserInput(
        const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
      ),
    );
    await categories.seedDefaultCategories(user.id);
    expect(await categories.list(userId: user.id), hasLength(13));

    final campus = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Campus', type: 'EXPENSE', icon: 'school'),
      ),
    );
    final salary = (await categories.list(userId: user.id, type: 'INCOME'))
        .firstWhere((row) => row.name == 'Salary');
    final food = (await categories.list(userId: user.id, type: 'EXPENSE'))
        .firstWhere((row) => row.name == 'Food');

    await _add(transactions, salary, user.id, '500', date, 'INCOME');
    await _add(transactions, campus, user.id, '40', date, 'EXPENSE');
    await budgets.create(
      userId: user.id,
      input: _budget(campus, user.id, month.start, month.end, '100'),
    );
    var progress = await budgets.listWithProgress(user.id);
    expect(progress.single.spent, 40);
    expect(progress.single.remaining, 60);
    expect(progress.single.percentageUsed, 40);
    expect(progress.single.state, BudgetState.normal);

    await _add(transactions, campus, user.id, '70', date, 'EXPENSE');
    await _add(transactions, food, user.id, '20', date, 'EXPENSE');
    progress = await budgets.listWithProgress(user.id);
    expect(progress.single.spent, 110);
    expect(progress.single.remaining, -10);
    expect(progress.single.state, BudgetState.exceeded);

    final dashboard = await reader.load(user.id, today: today);
    expect(dashboard.balance, 370);
    expect(dashboard.monthlyIncome, 500);
    expect(dashboard.monthlyExpenses, 130);
    expect(dashboard.remainingBudget, -10);
    expect(dashboard.attention.single.categoryName, 'Campus');
    expect(dashboard.recent, isNotEmpty);

    final statistics = await reader.loadStatistics(user.id, today);
    expect(statistics.mostExpensive?.name, 'Campus');
    expect(statistics.series, hasLength(6));
    expect(statistics.budgetConsumption.single.progress.state, BudgetState.exceeded);

    final db = await database.open();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    expect(
      tables.map((row) => row['name']).toSet(),
      {'users', 'categories', 'transactions', 'budgets'},
    );
    await database.close();
  });

  testWidgets('dashboard totals open statistics', (tester) async {
    final database = openTestDatabase();
    final users = UserRepository(database);
    final categories = CategoryRepository(database);
    final transactions = TransactionRepository(database, categories);
    final user = await users.create(
      validateUserInput(
        const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
      ),
    );
    final food = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Food', type: 'EXPENSE', icon: 'restaurant'),
      ),
    );
    final salary = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Salary', type: 'INCOME', icon: 'payments'),
      ),
    );
    final today = IsoTime.date(DateTime.now());
    await _add(transactions, salary, user.id, '100', today, 'INCOME');
    await _add(transactions, food, user.id, '30', today, 'EXPENSE');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: MaterialApp(home: DashboardScreen(userId: user.id)),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('70.000 TND'), findsWidgets);
    await tester.tap(find.byKey(const Key('open-statistics')));
    await pumpFrames(tester);
    expect(find.text('Income versus expenses'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    await database.close();
  });
}

Future<void> _add(
  TransactionRepository transactions,
  Category category,
  int userId,
  String amount,
  String date,
  String type,
) {
  return transactions.create(
    userId: userId,
    input: validateTransactionInput(
      TransactionInput(
        amountText: amount,
        currencyCode: 'TND',
        type: type,
        category: category,
        userId: userId,
        dateText: date,
        description: type,
      ),
    ),
  );
}

BudgetValidationResult _budget(
  Category category,
  int userId,
  DateTime start,
  DateTime end,
  String limit,
) {
  final result = validateBudgetInput(
    BudgetInput(
      limitText: limit,
      currencyCode: 'TND',
      period: AppConstants.monthlyPeriod,
      startText: IsoTime.date(start),
      endText: IsoTime.date(end),
      category: category,
      userId: userId,
    ),
  );
  expect(result.isValid, isTrue, reason: result.message);
  return result;
}
