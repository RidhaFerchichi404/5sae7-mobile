import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/app_constants.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/database/database_provider.dart';
import 'package:mybudget/core/errors/app_failure.dart';
import 'package:mybudget/features/budgets/data/budget_repository.dart';
import 'package:mybudget/features/budgets/domain/budget_validation.dart';
import 'package:mybudget/features/categories/data/category_repository.dart';
import 'package:mybudget/features/categories/domain/category_validation.dart';
import 'package:mybudget/features/categories/presentation/categories_screen.dart';
import 'package:mybudget/features/categories/presentation/category_form_screen.dart';
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

  setUp(() {
    database = openTestDatabase();
    users = UserRepository(database);
    categories = CategoryRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('normalises names and rejects an icon outside the catalogue', () {
    expect(normalizedCategoryName('  Food '), 'food');
    final result = validateCategoryInput(
      const CategoryInput(name: 'Pets', type: 'EXPENSE', icon: 'not-an-icon'),
    );
    expect(result.iconError, isNotNull);
  });

  test('seeds the 13 predefined categories', () async {
    final user = await _user(users);
    await categories.seedDefaultCategories(user.id);
    final rows = await categories.list(userId: user.id);
    expect(rows, hasLength(AppConstants.predefinedCategories.length));
    expect(rows.where((row) => row.type == 'EXPENSE'), hasLength(9));
    expect(rows.where((row) => row.type == 'INCOME'), hasLength(4));
  });

  test('rejects a case-insensitive duplicate for the same type', () async {
    final user = await _user(users);
    await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Market', type: 'EXPENSE', icon: 'shopping_bag'),
      ),
    );
    await expectLater(
      categories.create(
        userId: user.id,
        input: validateCategoryInput(
          const CategoryInput(name: 'market', type: 'EXPENSE', icon: 'shopping_bag'),
        ),
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('refuses a type change while a transaction references the category', () async {
    final user = await _user(users);
    final category = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Market', type: 'EXPENSE', icon: 'shopping_bag'),
      ),
    );
    await TransactionRepository(database, categories).create(
      userId: user.id,
      input: _expense(category, user.id, '10', '2026-03-02'),
    );

    await expectLater(
      categories.update(
        current: category,
        input: validateCategoryInput(
          const CategoryInput(name: 'Market', type: 'INCOME', icon: 'shopping_bag'),
        ),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('restricts delete when a transaction or a budget still uses it', () async {
    final user = await _user(users);
    final food = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Food', type: 'EXPENSE', icon: 'restaurant'),
      ),
    );
    final rent = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Rent', type: 'EXPENSE', icon: 'home'),
      ),
    );
    await TransactionRepository(database, categories).create(
      userId: user.id,
      input: _expense(food, user.id, '8', '2026-03-02'),
    );
    await BudgetRepository(
      database,
      categories,
      TransactionRepository(database, categories),
    ).create(
      userId: user.id,
      input: validateBudgetInput(
        BudgetInput(
          limitText: '200',
          currencyCode: 'TND',
          period: 'CUSTOM',
          startText: '2026-04-01',
          endText: '2026-04-10',
          category: rent,
          userId: user.id,
        ),
      ),
    );

    await expectLater(
      categories.delete(food.id),
      throwsA(isA<RestrictFailure>()),
    );
    await expectLater(
      categories.delete(rent.id),
      throwsA(isA<RestrictFailure>()),
    );
  });

  test('reassignment moves transactions and budgets', () async {
    final user = await _user(users);
    final food = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Food', type: 'EXPENSE', icon: 'restaurant'),
      ),
    );
    final market = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Market', type: 'EXPENSE', icon: 'shopping_bag'),
      ),
    );
    final transactions = TransactionRepository(database, categories);
    final created = await transactions.create(
      userId: user.id,
      input: _expense(food, user.id, '8', '2026-03-02'),
    );
    final budgets = BudgetRepository(database, categories, transactions);
    final budget = await budgets.create(
      userId: user.id,
      input: validateBudgetInput(
        BudgetInput(
          limitText: '80',
          currencyCode: 'TND',
          period: 'MONTHLY',
          startText: '2026-03-01',
          endText: '2026-03-31',
          category: food,
          userId: user.id,
        ),
      ),
    );

    await categories.reassign(fromId: food.id, toId: market.id);
    expect((await transactions.getById(created.id)).categoryId, market.id);
    expect((await budgets.getById(budget.id)).categoryId, market.id);
    await categories.delete(food.id);
    expect(await categories.getById(market.id), isNotNull);
  });

  testWidgets('category form saves a custom category', (tester) async {
    await _user(users);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: const MaterialApp(home: CategoryFormScreen()),
      ),
    );
    await pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('category-name')), 'Pets');
    await tester.ensureVisible(find.byKey(const Key('save-category')));
    await tester.tap(find.byKey(const Key('save-category')));
    await pumpFrames(tester);

    final user = (await users.list()).single;
    final rows = await categories.list(userId: user.id);
    expect(rows.single.name, 'Pets');
  });

  testWidgets('blocked delete offers another category', (tester) async {
    final user = await _user(users);
    await categories.seedDefaultCategories(user.id);
    final food = (await categories.list(userId: user.id, type: 'EXPENSE'))
        .firstWhere((row) => row.name == 'Food');
    await TransactionRepository(database, categories).create(
      userId: user.id,
      input: _expense(food, user.id, '5', '2026-03-04'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: const MaterialApp(home: CategoriesScreen()),
      ),
    );
    await pumpFrames(tester);
    final delete = find.byKey(Key('delete-category-${food.id}'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await pumpFrames(tester);
    await tester.tap(find.text('Delete'));
    await pumpFrames(tester);

    expect(find.byKey(const Key('category-restrict')), findsOneWidget);
  });
}

Future<UserProfile> _user(UserRepository users) {
  return users.create(
    validateUserInput(
      const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
    ),
  );
}

TransactionValidationResult _expense(
  dynamic category,
  int userId,
  String amount,
  String date,
) {
  return validateTransactionInput(
    TransactionInput(
      amountText: amount,
      currencyCode: 'TND',
      type: 'EXPENSE',
      category: category,
      userId: userId,
      dateText: date,
      description: 'Note',
    ),
  );
}
