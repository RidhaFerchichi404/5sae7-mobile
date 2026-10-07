import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Shared database instance. Features read this provider. They do not
/// open a second database file.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});
