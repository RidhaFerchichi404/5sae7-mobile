import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// The only place that opens `mybudget.db`.
///
/// Schema version 2 and later require a team migration pull request.
/// Version 1 has no upgrade steps.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory,
      _path = path;

  static const schemaVersion = 1;
  static const fileName = 'mybudget.db';

  final DatabaseFactory? _factory;
  final String? _path;
  Database? _database;

  Future<Database> open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final factory = _factory ?? databaseFactory;
    final path = _path ?? await _defaultPath();
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: (db, version) => createSchema(db),
        onUpgrade: _onUpgrade,
      ),
    );
    _database = database;
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, fileName);
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= newVersion || oldVersion >= schemaVersion) {
      return;
    }
  }
}
