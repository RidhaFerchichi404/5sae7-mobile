import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/database/database_provider.dart';
import 'package:mybudget/core/errors/app_failure.dart';
import 'package:mybudget/features/budgets/data/budget_repository.dart';
import 'package:mybudget/features/budgets/domain/budget_validation.dart';
import 'package:mybudget/features/categories/data/category_repository.dart';
import 'package:mybudget/features/categories/domain/category_validation.dart';
import 'package:mybudget/features/transactions/data/transaction_repository.dart';
import 'package:mybudget/features/transactions/domain/transaction_validation.dart';
import 'package:mybudget/features/users/data/user_repository.dart';
import 'package:mybudget/features/users/domain/user_validation.dart';
import 'package:mybudget/features/users/presentation/profile_screen.dart';
import 'package:mybudget/main.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

void main() {
  setUpAll(initTestDatabase);

  late AppDatabase database;
  late UserRepository users;

  setUp(() {
    database = openTestDatabase();
    users = UserRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('rejects an empty name and an unknown currency', () {
    final empty = validateUserInput(
      const UserInput(name: '   ', email: 'amira@email.com', currency: 'TND'),
    );
    final currency = validateUserInput(
      const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'JPY'),
    );

    expect(empty.isValid, isFalse);
    expect(empty.nameError, isNotNull);
    expect(currency.currencyError, isNotNull);
  });

  test('stores emails in lowercase and rejects case-only duplicates', () async {
    final first = await users.create(
      validateUserInput(
        const UserInput(
          name: 'Amira Ben Salah',
          email: 'Amira@Email.com',
          currency: 'TND',
        ),
      ),
    );
    expect(first.email, 'amira@email.com');

    await expectLater(
      users.create(
        validateUserInput(
          const UserInput(
            name: 'Other',
            email: 'amira@email.com',
            currency: 'EUR',
          ),
        ),
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('deleting a profile cascades categories, transactions, and budgets', () async {
    final user = await users.create(
      validateUserInput(
        const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
      ),
    );
    final categories = CategoryRepository(database);
    final transactions = TransactionRepository(database, categories);
    final budgets = BudgetRepository(database, categories, transactions);
    final category = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Food', type: 'EXPENSE', icon: 'restaurant'),
      ),
    );
    await transactions.create(
      userId: user.id,
      input: validateTransactionInput(
        TransactionInput(
          amountText: '12.500',
          currencyCode: 'TND',
          type: 'EXPENSE',
          category: category,
          userId: user.id,
          dateText: '2026-03-01',
          description: 'Lunch',
        ),
      ),
    );
    await budgets.create(
      userId: user.id,
      input: validateBudgetInput(
        BudgetInput(
          limitText: '100',
          currencyCode: 'TND',
          period: 'MONTHLY',
          startText: '2026-03-01',
          endText: '2026-03-31',
          category: category,
          userId: user.id,
        ),
      ),
    );

    await users.delete(user.id);

    expect(await users.list(), isEmpty);
    expect(await categories.list(userId: user.id), isEmpty);
    expect(await budgets.list(user.id), isEmpty);
  });

  testWidgets('create form shows a validation error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: const MyBudgetApp(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('Create profile'), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-profile')));
    await tester.pump();

    expect(find.text('Enter a name between 1 and 80 characters.'), findsOneWidget);
  });

  testWidgets('delete confirmation names the profile', (tester) async {
    final user = await users.create(
      validateUserInput(
        const UserInput(name: 'Amira Ben Salah', email: 'amira@email.com'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: MaterialApp(home: ProfileScreen(userId: user.id)),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byKey(const Key('delete-profile')));
    await pumpFrames(tester);

    expect(find.textContaining('Delete Amira Ben Salah?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await pumpFrames(tester);
    expect(await users.list(), hasLength(1));
  });
}
