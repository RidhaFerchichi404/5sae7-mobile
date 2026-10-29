import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_motion.dart';
import 'package:mybudget/shared/widgets/fade_slide_in.dart';
import 'package:mybudget/shared/widgets/rows_skeleton.dart';

Widget _app(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: child),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(FadeSlideIn),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('skeleton draws the requested rows and says it is loading', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const RowsSkeleton(rows: 3, height: 72)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    final rows = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(RowsSkeleton),
        matching: find.byType(Container),
      ),
    );
    expect(rows, hasLength(3));
    expect(tester.getSize(find.byWidget(rows.first)).height, 72);
  });

  testWidgets('staggered rows start later the further down they are', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            FadeSlideIn(index: 0, child: Text('first')),
            FadeSlideIn(index: 3, child: Text('fourth')),
          ],
        ),
      ),
    );
    await tester.pump(AppMotion.stagger);
    await tester.pump(AppMotion.stagger);
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((item) => item.opacity)
        .toList();
    expect(opacities.first, greaterThan(0));
    expect(opacities.last, 0);

    await tester.pump(const Duration(seconds: 1)); // the last delay fires
    await tester.pump(const Duration(seconds: 1)); // and its fade runs
    expect(
      tester
          .widgetList<Opacity>(find.byType(Opacity))
          .every((o) => o.opacity == 1),
      isTrue,
    );
  });

  testWidgets('reduced motion shows rows in their end state at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const FadeSlideIn(index: 5, child: Text('row')), reduced: true),
    );
    await tester.pump();
    expect(_opacity(tester), 1);
  });
}
