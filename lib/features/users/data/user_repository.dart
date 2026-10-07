import '../../../core/database/app_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/database_error.dart';
import '../../../core/utils/iso_time.dart';
import '../domain/user_profile.dart';
import '../domain/user_validation.dart';

class UserRepository {
  UserRepository(this._database);

  final AppDatabase _database;

  Future<UserProfile> create(UserValidationResult input) async {
    _requireValid(input);
    final now = IsoTime.timestamp(IsoTime.now());
    try {
      final db = await _database.open();
      final id = await db.insert('users', {
        'name': input.name,
        'email': input.email,
        'currency': input.currency,
        'created_at': now,
        'updated_at': now,
      });
      return getById(id);
    } catch (error) {
      throw mapDatabaseError(
        error,
        uniqueMessage: 'A profile with this email already exists.',
      );
    }
  }

  Future<UserProfile> update(UserProfile user, UserValidationResult input) async {
    _requireValid(input);
    final now = IsoTime.timestamp(IsoTime.now());
    try {
      final db = await _database.open();
      final count = await db.update(
        'users',
        {
          'name': input.name,
          'email': input.email,
          'currency': input.currency,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );
      if (count == 0) {
        throw NotFoundFailure('This profile no longer exists.');
      }
      return getById(user.id);
    } catch (error) {
      if (error is AppFailure) {
        rethrow;
      }
      throw mapDatabaseError(
        error,
        uniqueMessage: 'A profile with this email already exists.',
      );
    }
  }

  Future<void> delete(int id) async {
    final db = await _database.open();
    final count = await db.delete('users', where: 'id = ?', whereArgs: [id]);
    if (count == 0) {
      throw const NotFoundFailure('This profile no longer exists.');
    }
  }

  Future<UserProfile> getById(int id) async {
    final db = await _database.open();
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      throw const NotFoundFailure('This profile no longer exists.');
    }
    return _map(rows.single);
  }

  Future<List<UserProfile>> list() async {
    final db = await _database.open();
    final rows = await db.query('users', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(_map).toList();
  }

  void _requireValid(UserValidationResult input) {
    if (!input.isValid) {
      throw ValidationFailure(
        input.nameError ?? input.emailError ?? input.currencyError!,
      );
    }
  }

  UserProfile _map(Map<String, Object?> row) {
    return UserProfile(
      id: row['id']! as int,
      name: row['name']! as String,
      email: row['email']! as String,
      currency: row['currency']! as String,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
