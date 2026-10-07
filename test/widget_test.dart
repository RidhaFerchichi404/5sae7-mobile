import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybudget/main.dart';

void main() {
  testWidgets('shell shows the four destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyBudgetApp()));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsWidgets);
  });
}
