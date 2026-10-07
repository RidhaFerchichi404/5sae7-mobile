import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/database_error.dart';
import '../../../core/utils/iso_time.dart';
import '../domain/category.dart';
import '../domain/category_validation.dart';

class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  Future<Category> create({
    required int userId,
    required CategoryValidationResult input,
  }) async {
    _requireValid(input);
    await _ensureUnique(userId: userId, name: input.name, type: input.type);
    final now = IsoTime.timestamp(IsoTime.now());
    try {
      final db = await _database.open();
      final id = await db.insert('categories', {
        'user_id': userId,
        'name': input.name,
        'type': input.type,
        'icon': input.icon,
        'created_at': now,
      });
      return getById(id);
    } catch (error) {
      throw mapDatabaseError(
        error,
        uniqueMessage: 'A category with this name already exists.',
      );
    }
  }

  Future<Category> update({
    required Category current,
    required CategoryValidationResult input,
  }) async {
    _requireValid(input);
    if (input.type != current.type) {
      final used = await _referenceCount(current.id);
      if (used > 0) {
        throw const ValidationFailure(
          'Change the type only when nothing uses this category.',
        );
      }
    }
    await _ensureUnique(
      userId: current.userId,
      name: input.name,
      type: input.type,
      exceptId: current.id,
    );
    try {
      final db = await _database.open();
      final count = await db.update(
        'categories',
        {'name': input.name, 'type': input.type, 'icon': input.icon},
        where: 'id = ?',
        whereArgs: [current.id],
      );
      if (count == 0) {
        throw const NotFoundFailure('This category no longer exists.');
      }
      return getById(current.id);
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw mapDatabaseError(
        error,
        uniqueMessage: 'A category with this name already exists.',
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await _database.open();
      final count = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const NotFoundFailure('This category no longer exists.');
      }
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw mapDatabaseError(
        error,
        restrictMessage:
            'This category is still used. Move its transactions and budgets first.',
      );
    }
  }

  Future<void> reassign({required int fromId, required int toId}) async {
    if (fromId == toId) {
      throw const ValidationFailure('Choose a different category.');
    }
    final from = await getById(fromId);
    final to = await getById(toId);
    if (from.userId != to.userId || from.type != to.type) {
      throw const ValidationFailure(
        'Move items only to a category of the same profile and type.',
      );
    }
    final db = await _database.open();
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        {'category_id': toId},
        where: 'category_id = ?',
        whereArgs: [fromId],
      );
      await txn.update(
        'budgets',
        {'category_id': toId},
        where: 'category_id = ?',
        whereArgs: [fromId],
      );
    });
  }

  Future<void> seedDefaultCategories(int userId) async {
    final db = await _database.open();
    final now = IsoTime.timestamp(IsoTime.now());
    await db.transaction((txn) async {
      for (final item in AppConstants.predefinedCategories) {
        await txn.insert('categories', {
          'user_id': userId,
          'name': item.name,
          'type': item.type,
          'icon': item.icon,
          'created_at': now,
        });
      }
    });
  }

  Future<Category> getById(int id) async {
    final db = await _database.open();
    final rows = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) {
      throw const NotFoundFailure('This category no longer exists.');
    }
    return _map(rows.single);
  }

  Future<List<Category>> list({required int userId, String? type}) async {
    final db = await _database.open();
    final rows = await db.query(
      'categories',
      where: type == null ? 'user_id = ?' : 'user_id = ? AND type = ?',
      whereArgs: type == null ? [userId] : [userId, type],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_map).toList();
  }

  Future<void> _ensureUnique({
    required int userId,
    required String name,
    required String type,
    int? exceptId,
  }) async {
    final db = await _database.open();
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: exceptId == null
          ? 'user_id = ? AND type = ? AND lower(name) = ?'
          : 'user_id = ? AND type = ? AND lower(name) = ? AND id != ?',
      whereArgs: exceptId == null
          ? [userId, type, normalizedCategoryName(name)]
          : [userId, type, normalizedCategoryName(name), exceptId],
    );
    if (rows.isNotEmpty) {
      throw const ConflictFailure('A category with this name already exists.');
    }
  }

  Future<int> _referenceCount(int categoryId) async {
    final db = await _database.open();
    final transactions = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM transactions WHERE category_id = ?',
      [categoryId],
    );
    final budgets = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM budgets WHERE category_id = ?',
      [categoryId],
    );
    return _count(transactions) + _count(budgets);
  }

  void _requireValid(CategoryValidationResult input) {
    if (!input.isValid) {
      throw ValidationFailure(input.message!);
    }
  }

  Category _map(Map<String, Object?> row) {
    return Category(
      id: row['id']! as int,
      userId: row['user_id']! as int,
      name: row['name']! as String,
      type: row['type']! as String,
      icon: row['icon']! as String,
      createdAt: DateTime.parse(row['created_at']! as String),
    );
  }
}

int _count(List<Map<String, Object?>> rows) => rows.single['count']! as int;
