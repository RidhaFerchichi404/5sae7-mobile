import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/database/database_provider.dart';
import 'package:mybudget/core/errors/app_failure.dart';
import 'package:mybudget/core/theme/app_colors.dart';
import 'package:mybudget/core/utils/date_ranges.dart';
import 'package:mybudget/features/budgets/data/budget_repository.dart';
import 'package:mybudget/features/budgets/domain/budget.dart';
import 'package:mybudget/features/budgets/domain/budget_calculator.dart';
import 'package:mybudget/features/budgets/domain/budget_validation.dart';
import 'package:mybudget/features/budgets/presentation/budget_form_screen.dart';
import 'package:mybudget/features/budgets/presentation/budget_progress_card.dart';
import 'package:mybudget/features/categories/data/category_repository.dart';
import 'package:mybudget/features/categories/domain/category.dart';
import 'package:mybudget/features/categories/domain/category_validation.dart';
import 'package:mybudget/features/transactions/data/transaction_repository.dart';
import 'package:mybudget/features/transactions/domain/transaction_validation.dart';
import 'package:mybudget/features/users/data/user_repository.dart';
import 'package:mybudget/features/users/domain/user_profile.dart';
import 'package:mybudget/features/users/domain/user_validation.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

void main() {
  setUpAll(initTestDatabase);

  late AppDatabase database;
  late UserRepository users;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late BudgetRepository budgets;

  setUp(() {
    database = openTestDatabase();
    users = UserRepository(database);
    categories = CategoryRepository(database);
    transactions = TransactionRepository(database, categories);
    budgets = BudgetRepository(database, categories, transactions);
  });

  tearDown(() async {
    await database.close();
  });

  test('calculator marks 0 and 79 as normal, 80 and 100 as warning, above 100 as exceeded', () {
    final budget = _budget(100);
    expect(BudgetCalculator.progress(budget: budget, spent: 0).state, BudgetState.normal);
    expect(BudgetCalculator.progress(budget: budget, spent: 79).state, BudgetState.normal);
    expect(BudgetCalculator.progress(budget: budget, spent: 80).state, BudgetState.warning);
    expect(
      BudgetCalculator.progress(budget: budget, spent: 100).state,
      BudgetState.warning,
    );
    final over = BudgetCalculator.progress(budget: budget, spent: 130);
    expect(over.state, BudgetState.exceeded);
    expect(over.remaining, -30);
    expect(over.percentageUsed, 130);
  });

  test('monthly bounds and touching dates', () async {
    final bounds = DateRanges.monthBounds(DateTime(2026, 2, 10));
    expect(bounds.start, DateTime(2026, 2, 1));
    expect(bounds.end, DateTime(2026, 2, 28));

    final user = await _user(users);
    final food = await _expenseCategory(categories, user.id, 'Food');
    await budgets.create(
      userId: user.id,
      input: _limit(food, user.id, start: '2026-01-01', end: '2026-01-31'),
    );
    await expectLater(
      budgets.create(
        userId: user.id,
        input: _limit(food, user.id, start: '2026-01-31', end: '2026-02-15'),
      ),
      throwsA(isA<ConflictFailure>()),
    );
    final next = await budgets.create(
      userId: user.id,
      input: _limit(food, user.id, start: '2026-02-01', end: '2026-02-28'),
    );
    expect(next.startDate, DateTime(2026, 2, 1));
  });

  test('rejects an income category', () async {
    final user = await _user(users);
    final salary = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Salary', type: 'INCOME', icon: 'payments'),
      ),
    );
    final result = validateBudgetInput(
      BudgetInput(
        limitText: '100',
        currencyCode: 'TND',
        period: 'MONTHLY',
        startText: '2026-03-01',
        endText: '2026-03-31',
        category: salary,
        userId: user.id,
      ),
    );
    expect(result.isValid, isFalse);

    await expectLater(
      budgets.create(
        userId: user.id,
        input: BudgetValidationResult(
          limit: 100,
          period: 'MONTHLY',
          categoryId: salary.id,
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
        ),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('progress counts expenses inside the range only', () async {
    final user = await _user(users);
    final food = await _expenseCategory(categories, user.id, 'Food');
    final salary = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Salary', type: 'INCOME', icon: 'payments'),
      ),
    );
    await budgets.create(
      userId: user.id,
      input: _limit(
        food,
        user.id,
        start: '2026-03-01',
        end: '2026-03-31',
        period: 'MONTHLY',
        limit: '100',
      ),
    );
    await _add(transactions, food, user.id, '80', '2026-03-10', 'EXPENSE');
    await _add(transactions, food, user.id, '25', '2026-04-02', 'EXPENSE');
    await _add(transactions, salary, user.id, '500', '2026-03-10', 'INCOME');

    final progress = (await budgets.listWithProgress(user.id)).single;
    expect(progress.spent, 80);
    expect(progress.remaining, 20);
    expect(progress.percentageUsed, 80);
    expect(progress.state, BudgetState.warning);

    await budgets.delete(progress.budget.id);
    expect(await transactions.listRecent(user.id), hasLength(3));
  });

  testWidgets('the form requires a positive limit', (tester) async {
    final user = await _user(users);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: MaterialApp(home: BudgetFormScreen(userId: user.id)),
      ),
    );
    await pumpFrames(tester);
    await tester.ensureVisible(find.byKey(const Key('save-budget')));
    await tester.tap(find.byKey(const Key('save-budget')));
    await tester.pump();
    expect(find.text('Enter a limit greater than zero.'), findsOneWidget);
  });

  testWidgets('progress cards use the three state colours', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final entry in [
                (spent: 10.0, label: 'Normal', color: AppColors.primary),
                (spent: 80.0, label: 'Warning', color: AppColors.warning),
                (spent: 140.0, label: 'Exceeded', color: AppColors.exceeded),
              ])
                BudgetProgressCard(
                  progress: BudgetCalculator.progress(
                    budget: _budget(100),
                    spent: entry.spent,
                  ),
                  categoryName: 'Food',
                  currencyCode: 'TND',
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    for (final entry in [
      (label: 'Normal', color: AppColors.primary),
      (label: 'Warning', color: AppColors.warning),
      (label: 'Exceeded', color: AppColors.exceeded),
    ]) {
      final text = tester.widget<Text>(find.text(entry.label));
      expect(text.style?.color, entry.color);
    }
  });
}

Budget _budget(double limit) {
  return Budget(
    id: 1,
    userId: 1,
    categoryId: 1,
    amountLimit: limit,
    period: 'MONTHLY',
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 3, 31),
    createdAt: DateTime(2026, 3, 1),
  );
}

Future<UserProfile> _user(UserRepository users) {
  return users.create(
    validateUserInput(
      const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
    ),
  );
}

Future<Category> _expenseCategory(
  CategoryRepository categories,
  int userId,
  String name,
) {
  return categories.create(
    userId: userId,
    input: validateCategoryInput(
      CategoryInput(name: name, type: 'EXPENSE', icon: 'restaurant'),
    ),
  );
}

BudgetValidationResult _limit(
  Category category,
  int userId, {
  required String start,
  required String end,
  String period = 'CUSTOM',
  String limit = '100',
}) {
  final result = validateBudgetInput(
    BudgetInput(
      limitText: limit,
      currencyCode: 'TND',
      period: period,
      startText: start,
      endText: end,
      category: category,
      userId: userId,
    ),
  );
  expect(result.isValid, isTrue, reason: result.message);
  return result;
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
