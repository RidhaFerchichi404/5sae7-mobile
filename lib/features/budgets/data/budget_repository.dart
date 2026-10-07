import '../../../core/database/app_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/database_error.dart';
import '../../../core/utils/date_ranges.dart';
import '../../../core/utils/iso_time.dart';
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../domain/budget.dart';
import '../domain/budget_calculator.dart';
import '../domain/budget_validation.dart';

class BudgetRepository {
  BudgetRepository(this._database, this._categories, this._transactions);

  final AppDatabase _database;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;

  Future<Budget> create({
    required int userId,
    required BudgetValidationResult input,
  }) async {
    _requireValid(input);
    await _checkCategory(userId: userId, categoryId: input.categoryId);
    await _rejectOverlap(userId: userId, input: input);
    final now = IsoTime.timestamp(IsoTime.now());
    try {
      final db = await _database.open();
      final id = await db.insert('budgets', {
        'user_id': userId,
        'category_id': input.categoryId,
        'amount_limit': input.limit,
        'period': input.period,
        'start_date': IsoTime.date(input.start),
        'end_date': IsoTime.date(input.end),
        'created_at': now,
      });
      return getById(id);
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw mapDatabaseError(error);
    }
  }

  Future<Budget> update({
    required Budget current,
    required BudgetValidationResult input,
  }) async {
    _requireValid(input);
    await _checkCategory(userId: current.userId, categoryId: input.categoryId);
    await _rejectOverlap(userId: current.userId, input: input, exceptId: current.id);
    try {
      final db = await _database.open();
      final count = await db.update(
        'budgets',
        {
          'category_id': input.categoryId,
          'amount_limit': input.limit,
          'period': input.period,
          'start_date': IsoTime.date(input.start),
          'end_date': IsoTime.date(input.end),
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
      if (count == 0) {
        throw const NotFoundFailure('This budget no longer exists.');
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
    final count = await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    if (count == 0) {
      throw const NotFoundFailure('This budget no longer exists.');
    }
  }

  Future<Budget> getById(int id) async {
    final db = await _database.open();
    final rows = await db.query('budgets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      throw const NotFoundFailure('This budget no longer exists.');
    }
    return _map(rows.single);
  }

  Future<List<Budget>> list(int userId) async {
    final db = await _database.open();
    final rows = await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_date DESC',
    );
    return rows.map(_map).toList();
  }

  Future<List<Budget>> listCovering(int userId, DateTime day) async {
    final date = IsoTime.date(day);
    final db = await _database.open();
    final rows = await db.query(
      'budgets',
      where: 'user_id = ? AND start_date <= ? AND end_date >= ?',
      whereArgs: [userId, date, date],
    );
    return rows.map(_map).toList();
  }

  Future<List<BudgetProgress>> listWithProgress(int userId) async {
    final budgets = await list(userId);
    final progress = <BudgetProgress>[];
    for (final budget in budgets) {
      final spent = await _transactions.sumExpenses(
        userId: userId,
        categoryId: budget.categoryId,
        start: budget.startDate,
        end: budget.endDate,
      );
      progress.add(BudgetCalculator.progress(budget: budget, spent: spent));
    }
    return progress;
  }

  Future<void> _checkCategory({
    required int userId,
    required int categoryId,
  }) async {
    final category = await _categories.getById(categoryId);
    if (category.userId != userId || !category.isExpense) {
      throw const ValidationFailure('Budgets apply only to expense categories.');
    }
  }

  Future<void> _rejectOverlap({
    required int userId,
    required BudgetValidationResult input,
    int? exceptId,
  }) async {
    final existing = await list(userId);
    for (final other in existing) {
      if (other.id == exceptId || other.categoryId != input.categoryId) {
        continue;
      }
      if (DateRanges.overlaps(
        startA: other.startDate,
        endA: other.endDate,
        startB: input.start,
        endB: input.end,
      )) {
        throw const ConflictFailure(
          'This budget overlaps another budget for the same category.',
        );
      }
    }
  }

  void _requireValid(BudgetValidationResult input) {
    if (!input.isValid) {
      throw ValidationFailure(input.message!);
    }
  }

  Budget _map(Map<String, Object?> row) {
    return Budget(
      id: row['id']! as int,
      userId: row['user_id']! as int,
      categoryId: row['category_id']! as int,
      amountLimit: (row['amount_limit']! as num).toDouble(),
      period: row['period']! as String,
      startDate: IsoTime.tryParseDate(row['start_date']! as String)!,
      endDate: IsoTime.tryParseDate(row['end_date']! as String)!,
      createdAt: DateTime.parse(row['created_at']! as String),
    );
  }
}
