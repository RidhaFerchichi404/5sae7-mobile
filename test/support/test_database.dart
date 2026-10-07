import 'package:mybudget/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initTestDatabase() {
  sqfliteFfiInit();
}

AppDatabase openTestDatabase() {
  return AppDatabase(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
}
