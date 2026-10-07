import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/database/database_provider.dart';
import 'package:mybudget/features/users/data/user_repository.dart';
import 'package:mybudget/features/users/domain/user_validation.dart';
import 'package:mybudget/main.dart';

import 'support/pump.dart';
import 'support/test_database.dart';

void main() {
  setUpAll(initTestDatabase);

  late AppDatabase database;

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('no profile opens the create gate', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: const MyBudgetApp(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('Create profile'), findsOneWidget);
    expect(find.text('Create your profile'), findsOneWidget);
  });

  testWidgets('one profile opens the shell and keeps statistics for later', (
    tester,
  ) async {
    await UserRepository(database).create(
      validateUserInput(
        const UserInput(name: 'Amira', email: 'amira@email.com', currency: 'TND'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: const MyBudgetApp(),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('Transactions'));
    await pumpFrames(tester);
    expect(find.text('No transactions'), findsOneWidget);

    await tester.tap(find.text('More'));
    await pumpFrames(tester);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Income, expenses, and budgets'), findsOneWidget);
  });
}
