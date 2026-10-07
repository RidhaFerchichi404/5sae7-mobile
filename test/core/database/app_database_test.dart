import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase appDatabase;
  late Database db;

  setUp(() async {
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await appDatabase.open();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('opens and closes', () async {
    expect(db.isOpen, isTrue);
    await appDatabase.close();
    expect(db.isOpen, isFalse);
    db = await appDatabase.open();
  });

  test('contains exactly four application tables', () async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    final names = rows.map((row) => row['name'] as String).toSet();
    expect(names, {'users', 'categories', 'transactions', 'budgets'});
  });

  test('foreign keys are enabled', () async {
    final rows = await db.rawQuery('PRAGMA foreign_keys');
    expect(rows.single.values.single, 1);
  });

  test('a category cannot reference a missing user', () async {
    expect(
      () => db.insert('categories', _category(userId: 999)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('a transaction cannot reference a missing category', () async {
    final userId = await _insertUser(db);
    expect(
      () => db.insert('transactions', _transaction(userId: userId, categoryId: 999)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('a budget cannot reference a missing category', () async {
    final userId = await _insertUser(db);
    expect(
      () => db.insert('budgets', _budget(userId: userId, categoryId: 999)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('deleting a user removes categories, transactions, and budgets', () async {
    final userId = await _insertUser(db);
    final categoryId = await db.insert('categories', _category(userId: userId));
    await db.insert(
      'transactions',
      _transaction(userId: userId, categoryId: categoryId),
    );
    await db.insert('budgets', _budget(userId: userId, categoryId: categoryId));

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);

    expect(await _count(db, 'categories'), 0);
    expect(await _count(db, 'transactions'), 0);
    expect(await _count(db, 'budgets'), 0);
  });

  test('deleting a referenced category fails', () async {
    final userId = await _insertUser(db);
    final categoryId = await db.insert('categories', _category(userId: userId));
    await db.insert(
      'transactions',
      _transaction(userId: userId, categoryId: categoryId),
    );

    expect(
      () => db.delete('categories', where: 'id = ?', whereArgs: [categoryId]),
      throwsA(isA<DatabaseException>()),
    );

    final budgetCategoryId = await db.insert(
      'categories',
      _category(userId: userId, name: 'Leisure'),
    );
    await db.insert(
      'budgets',
      _budget(userId: userId, categoryId: budgetCategoryId),
    );
    expect(
      () => db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [budgetCategoryId],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('deleting a transaction leaves the category and the budget', () async {
    final userId = await _insertUser(db);
    final categoryId = await db.insert('categories', _category(userId: userId));
    final transactionId = await db.insert(
      'transactions',
      _transaction(userId: userId, categoryId: categoryId),
    );
    await db.insert('budgets', _budget(userId: userId, categoryId: categoryId));

    await db.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);

    expect(await _count(db, 'categories'), 1);
    expect(await _count(db, 'budgets'), 1);
    expect(await _count(db, 'transactions'), 0);
  });

  test('deleting a budget leaves transactions', () async {
    final userId = await _insertUser(db);
    final categoryId = await db.insert('categories', _category(userId: userId));
    await db.insert(
      'transactions',
      _transaction(userId: userId, categoryId: categoryId),
    );
    final budgetId = await db.insert(
      'budgets',
      _budget(userId: userId, categoryId: categoryId),
    );

    await db.delete('budgets', where: 'id = ?', whereArgs: [budgetId]);

    expect(await _count(db, 'transactions'), 1);
    expect(await _count(db, 'budgets'), 0);
  });

  test('a user row can be inserted, read, and deleted', () async {
    final id = await _insertUser(db);
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    expect(rows.single['email'], 'amira@email.com');

    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    final remaining = await db.query('users', where: 'id = ?', whereArgs: [id]);
    expect(remaining, isEmpty);
  });
}

Future<int> _insertUser(Database db) {
  return db.insert('users', {
    'name': 'Amira Ben Salah',
    'email': 'amira@email.com',
    'currency': 'TND',
    'created_at': '2026-10-01T10:00:00',
    'updated_at': '2026-10-01T10:00:00',
  });
}

Map<String, Object> _category({
  required int userId,
  String name = 'Food',
}) {
  return {
    'user_id': userId,
    'name': name,
    'type': 'EXPENSE',
    'icon': 'restaurant',
    'created_at': '2026-10-01T10:00:00',
  };
}

Map<String, Object> _transaction({
  required int userId,
  required int categoryId,
}) {
  return {
    'user_id': userId,
    'category_id': categoryId,
    'amount': 42.0,
    'type': 'EXPENSE',
    'description': 'Taxi',
    'transaction_date': '2026-10-06',
    'created_at': '2026-10-06T10:00:00',
  };
}

Map<String, Object> _budget({required int userId, required int categoryId}) {
  return {
    'user_id': userId,
    'category_id': categoryId,
    'amount_limit': 400.0,
    'period': 'MONTHLY',
    'start_date': '2026-10-01',
    'end_date': '2026-10-31',
    'created_at': '2026-10-01T10:00:00',
  };
}

Future<int> _count(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
  return rows.single['count'] as int;
}
