import 'package:sqflite/sqflite.dart';

import 'app_failure.dart';

AppFailure mapDatabaseError(
  Object error, {
  String uniqueMessage = 'This value already exists.',
  String restrictMessage = 'This item is still in use.',
}) {
  if (error is DatabaseException) {
    if (error.isUniqueConstraintError()) {
      return ConflictFailure(uniqueMessage);
    }
    final text = error.toString().toUpperCase();
    if (text.contains('FOREIGN KEY')) {
      return RestrictFailure(restrictMessage);
    }
  }
  return const DatabaseFailure('The database could not complete that action.');
}
