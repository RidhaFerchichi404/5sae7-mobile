import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/app_constants.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/database/database_provider.dart';
import 'package:mybudget/core/errors/app_failure.dart';
import 'package:mybudget/features/categories/data/category_repository.dart';
import 'package:mybudget/features/categories/domain/category.dart';
import 'package:mybudget/features/categories/domain/category_validation.dart';
import 'package:mybudget/features/transactions/data/transaction_repository.dart';
import 'package:mybudget/features/transactions/domain/transaction_query.dart';
import 'package:mybudget/features/transactions/domain/transaction_validation.dart';
import 'package:mybudget/features/transactions/presentation/transaction_form_screen.dart';
import 'package:mybudget/features/transactions/presentation/transactions_screen.dart';
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

  setUp(() {
    database = openTestDatabase();
    users = UserRepository(database);
    categories = CategoryRepository(database);
    transactions = TransactionRepository(database, categories);
  });

  tearDown(() async {
    await database.close();
  });

  test('enforces TND and EUR decimal scales', () {
    expect(
      _input(amount: '1.234', currency: 'TND', date: '2026-03-01').amountError,
      isNull,
    );
    expect(
      _input(amount: '1.2345', currency: 'TND', date: '2026-03-01').amountError,
      isNotNull,
    );
    expect(
      _input(amount: '1.23', currency: 'EUR', date: '2026-03-01').amountError,
      isNull,
    );
    expect(
      _input(amount: '1.234', currency: 'EUR', date: '2026-03-01').amountError,
      isNotNull,
    );
  });

  test('stores an empty description as null and allows a future date', () async {
    final user = await _user(users);
    final food = await _expenseCategory(categories, user.id);
    final created = await transactions.create(
      userId: user.id,
      input: _input(
        amount: '4.5',
        currency: 'TND',
        date: '2099-01-15',
        description: '   ',
        category: food,
        userId: user.id,
      ),
    );
    expect(created.description, isNull);
    expect(created.transactionDate, DateTime(2099, 1, 15));
  });

  test('rejects a category whose type does not match', () async {
    final user = await _user(users);
    final food = await _expenseCategory(categories, user.id);
    final result = validateTransactionInput(
      TransactionInput(
        amountText: '10',
        currencyCode: 'TND',
        type: AppConstants.incomeType,
        category: food,
        userId: user.id,
        dateText: '2026-03-01',
        description: '',
      ),
    );
    expect(result.categoryError, isNotNull);

    final forged = TransactionValidationResult(
      amount: 10,
      type: AppConstants.incomeType,
      categoryId: food.id,
      date: DateTime(2026, 3, 1),
      description: null,
    );
    await expectLater(
      transactions.create(userId: user.id, input: forged),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('creates, filters, sorts, sums, and lists recent rows', () async {
    final user = await _user(users);
    final food = await _expenseCategory(categories, user.id);
    final salary = await categories.create(
      userId: user.id,
      input: validateCategoryInput(
        const CategoryInput(name: 'Salary', type: 'INCOME', icon: 'payments'),
      ),
    );
    await transactions.create(
      userId: user.id,
      input: _input(
        amount: '10',
        currency: 'TND',
        date: '2026-03-01',
        description: 'Coffee',
        category: food,
        userId: user.id,
      ),
    );
    await transactions.create(
      userId: user.id,
      input: _input(
        amount: '30',
        currency: 'TND',
        date: '2026-03-05',
        description: 'Dinner',
        category: food,
        userId: user.id,
      ),
    );
    final income = await transactions.create(
      userId: user.id,
      input: validateTransactionInput(
        TransactionInput(
          amountText: '900',
          currencyCode: 'TND',
          type: 'INCOME',
          category: salary,
          userId: user.id,
          dateText: '2026-03-03',
          description: 'March salary',
        ),
      ),
    );
    final updated = await transactions.update(
      current: income,
      input: validateTransactionInput(
        TransactionInput(
          amountText: '950',
          currencyCode: 'TND',
          type: 'INCOME',
          category: salary,
          userId: user.id,
          dateText: '2026-03-03',
          description: 'March salary',
        ),
      ),
    );
    expect(updated.amount, 950);
    expect(updated.userId, income.userId);
    expect(updated.createdAt, income.createdAt);

    final filtered = await transactions.search(
      TransactionQuery(
        userId: user.id,
        search: 'din',
        type: 'EXPENSE',
        categoryId: food.id,
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31),
      ),
    );
    expect(filtered, hasLength(1));
    expect(filtered.single.amount, 30);

    final byAmount = await transactions.search(
      TransactionQuery(
        userId: user.id,
        type: 'EXPENSE',
        sortField: TransactionSortField.amount,
        ascending: true,
      ),
    );
    expect(byAmount.map((row) => row.amount).toList(), [10, 30]);

    expect(
      await transactions.sum(
        userId: user.id,
        type: 'EXPENSE',
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
      ),
      40,
    );
    expect(await transactions.sum(userId: user.id, type: 'INCOME'), 950);

    for (var day = 6; day <= 9; day++) {
      await transactions.create(
        userId: user.id,
        input: _input(
          amount: '1',
          currency: 'TND',
          date: '2026-03-0$day',
          description: 'Extra',
          category: food,
          userId: user.id,
        ),
      );
    }
    final recent = await transactions.listRecent(user.id);
    expect(recent, hasLength(5));
    expect(recent.first.transactionDate.isAfter(recent.last.transactionDate), isTrue);

    await transactions.delete(updated.id);
    await expectLater(
      transactions.getById(updated.id),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  testWidgets('the form asks for a category', (tester) async {
    final user = await _user(users);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: MaterialApp(home: TransactionFormScreen(userId: user.id)),
      ),
    );
    await pumpFrames(tester);
    await tester.enterText(find.byKey(const Key('transaction-amount')), '12.5');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pump();
    expect(find.text('Choose a category.'), findsOneWidget);
  });

  testWidgets('history is empty before the first transaction', (tester) async {
    final user = await _user(users);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: MaterialApp(home: TransactionsScreen(userId: user.id)),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('No transactions'), findsOneWidget);
  });
}

TransactionValidationResult _input({
  required String amount,
  required String currency,
  required String date,
  String description = '',
  Category? category,
  int userId = 1,
  String type = 'EXPENSE',
}) {
  return validateTransactionInput(
    TransactionInput(
      amountText: amount,
      currencyCode: currency,
      type: type,
      category: category,
      userId: userId,
      dateText: date,
      description: description,
    ),
  );
}

Future<UserProfile> _user(UserRepository users) {
  return users.create(
    validateUserInput(
      const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
    ),
  );
}

Future<Category> _expenseCategory(CategoryRepository categories, int userId) {
  return categories.create(
    userId: userId,
    input: validateCategoryInput(
      const CategoryInput(name: 'Food', type: 'EXPENSE', icon: 'restaurant'),
    ),
  );
}
