import '../../../core/database/app_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/database_error.dart';
import '../../../core/utils/iso_time.dart';
import '../../categories/data/category_repository.dart';
import '../domain/transaction_query.dart';
import '../domain/transaction_record.dart';
import '../domain/transaction_validation.dart';

class TransactionRepository {
  TransactionRepository(this._database, this._categories);

  final AppDatabase _database;
  final CategoryRepository _categories;

  Future<TransactionRecord> create({
    required int userId,
    required TransactionValidationResult input,
  }) async {
    _requireValid(input);
    await _checkCategory(userId: userId, input: input);
    final now = IsoTime.timestamp(IsoTime.now());
    try {
      final db = await _database.open();
      final id = await db.insert('transactions', {
        'user_id': userId,
        'category_id': input.categoryId,
        'amount': input.amount,
        'type': input.type,
        'description': input.description,
        'transaction_date': IsoTime.date(input.date),
        'created_at': now,
      });
      return getById(id);
    } catch (error) {
      throw mapDatabaseError(error);
    }
  }

  Future<TransactionRecord> update({
    required TransactionRecord current,
    required TransactionValidationResult input,
  }) async {
    _requireValid(input);
    await _checkCategory(userId: current.userId, input: input);
    try {
      final db = await _database.open();
      final count = await db.update(
        'transactions',
        {
          'category_id': input.categoryId,
          'amount': input.amount,
          'type': input.type,
          'description': input.description,
          'transaction_date': IsoTime.date(input.date),
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
      if (count == 0) {
        throw const NotFoundFailure('This transaction no longer exists.');
      }
      return getById(current.id);
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw mapDatabaseError(error);
    }
  }

  Future<void> delete(int id) async {
    final db = await _database.open();
    final count = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw const NotFoundFailure('This transaction no longer exists.');
    }
  }

  Future<TransactionRecord> getById(int id) async {
    final db = await _database.open();
    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) {
      throw const NotFoundFailure('This transaction no longer exists.');
    }
    return _map(rows.single);
  }

  Future<List<TransactionRecord>> search(TransactionQuery query) async {
    final db = await _database.open();
    final where = <String>['t.user_id = ?'];
    final args = <Object>[query.userId];
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      where.add("lower(ifnull(t.description, '')) LIKE ?");
      args.add('%${search.toLowerCase()}%');
    }
    if (query.type != null) {
      where.add('t.type = ?');
      args.add(query.type!);
    }
    if (query.categoryId != null) {
      where.add('t.category_id = ?');
      args.add(query.categoryId!);
    }
    if (query.from != null) {
      where.add('t.transaction_date >= ?');
      args.add(IsoTime.date(query.from!));
    }
    if (query.to != null) {
      where.add('t.transaction_date <= ?');
      args.add(IsoTime.date(query.to!));
    }
    final direction = query.ascending ? 'ASC' : 'DESC';
    final order = switch (query.sortField) {
      TransactionSortField.date =>
        't.transaction_date $direction, t.created_at $direction',
      TransactionSortField.amount => 't.amount $direction',
      TransactionSortField.categoryName => 'c.name COLLATE NOCASE $direction',
    };
    final rows = await db.rawQuery(
      '''
      SELECT t.* FROM transactions t
      JOIN categories c ON c.id = t.category_id
      WHERE ${where.join(' AND ')}
      ORDER BY $order
      ''',
      args,
    );
    return rows.map(_map).toList();
  }

  Future<double> sum({
    required int userId,
    required String type,
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _database.open();
    final where = <String>['user_id = ?', 'type = ?'];
    final args = <Object>[userId, type];
    if (start != null) {
      where.add('transaction_date >= ?');
      args.add(IsoTime.date(start));
    }
    if (end != null) {
      where.add('transaction_date <= ?');
      args.add(IsoTime.date(end));
    }
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE ${where.join(' AND ')}',
      args,
    );
    return (rows.single['total'] as num).toDouble();
  }

  Future<Map<int, double>> sumByCategory({
    required int userId,
    required String type,
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _database.open();
    final where = <String>['user_id = ?', 'type = ?'];
    final args = <Object>[userId, type];
    if (start != null) {
      where.add('transaction_date >= ?');
      args.add(IsoTime.date(start));
    }
    if (end != null) {
      where.add('transaction_date <= ?');
      args.add(IsoTime.date(end));
    }
    final rows = await db.rawQuery(
      '''
      SELECT category_id, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE ${where.join(' AND ')}
      GROUP BY category_id
      ''',
      args,
    );
    return {
      for (final row in rows)
        row['category_id']! as int: (row['total']! as num).toDouble(),
    };
  }

  Future<double> sumExpenses({
    required int userId,
    required int categoryId,
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _database.open();
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total FROM transactions
      WHERE user_id = ? AND category_id = ? AND type = 'EXPENSE'
        AND transaction_date >= ? AND transaction_date <= ?
      ''',
      [userId, categoryId, IsoTime.date(start), IsoTime.date(end)],
    );
    return (rows.single['total'] as num).toDouble();
  }

  Future<List<TransactionRecord>> listRecent(int userId, {int limit = 5}) {
    return search(
      TransactionQuery(
        userId: userId,
        sortField: TransactionSortField.date,
        ascending: false,
      ),
    ).then((rows) => rows.take(limit).toList());
  }

  Future<void> _checkCategory({
    required int userId,
    required TransactionValidationResult input,
  }) async {
    final category = await _categories.getById(input.categoryId);
    if (category.userId != userId || category.type != input.type) {
      throw const ValidationFailure(
        'The category type must match the transaction.',
      );
    }
  }

  void _requireValid(TransactionValidationResult input) {
    if (!input.isValid) {
      throw ValidationFailure(input.message!);
    }
  }

  TransactionRecord _map(Map<String, Object?> row) {
    return TransactionRecord(
      id: row['id']! as int,
      userId: row['user_id']! as int,
      categoryId: row['category_id']! as int,
      amount: (row['amount']! as num).toDouble(),
      type: row['type']! as String,
      description: row['description'] as String?,
      transactionDate: IsoTime.tryParseDate(row['transaction_date']! as String)!,
      createdAt: DateTime.parse(row['created_at']! as String),
    );
  }
}
