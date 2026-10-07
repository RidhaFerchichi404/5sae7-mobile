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
  Future<Database>? _opening;

  Future<Database> open() {
    final existing = _database;
    if (existing != null) {
      return Future.value(existing);
    }
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
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
    } finally {
      _opening = null;
    }
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) {
      try {
        await opening;
      } catch (_) {
        // The caller still needs the connection closed.
      }
    }
    final database = _database;
    _database = null;
    _opening = null;
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
