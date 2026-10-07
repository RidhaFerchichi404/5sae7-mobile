import 'package:flutter_test/flutter_test.dart';

/// Advances the test clock without waiting on a repeating animation.
Future<void> pumpFrames(WidgetTester tester, {int frames = 30}) async {
  await tester.pump();
  for (var index = 0; index < frames; index++) {
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}
