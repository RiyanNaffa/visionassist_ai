import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/presentation/widgets/swipe_detector.dart';

void main() {
  late List<String> swipes;

  setUp(() => swipes = []);

  Widget app({bool swipeUp = true, Widget? child}) => MaterialApp(
        home: SwipeDetector(
          onSwipeLeft: () => swipes.add('left'),
          onSwipeRight: () => swipes.add('right'),
          onSwipeUp: swipeUp ? () => swipes.add('up') : null,
          child: child ?? const SizedBox.expand(),
        ),
      );

  final area = find.byType(SwipeDetector);

  testWidgets('deliberate swipes left, right and up count', (tester) async {
    await tester.pumpWidget(app());

    await tester.fling(area, const Offset(-300, 0), 1000);
    await tester.fling(area, const Offset(300, 0), 1000);
    await tester.fling(area, const Offset(0, -300), 1000);
    await tester.pumpAndSettle();

    expect(swipes, ['left', 'right', 'up']);
  });

  testWidgets('a fast but short brush is ignored', (tester) async {
    // Seen on a phone: a 77 ms thumb brush skipped a step of the guide.
    await tester.pumpWidget(app());

    await tester.fling(area, const Offset(-60, 0), 2000);
    await tester.fling(area, const Offset(60, 0), 2000);
    await tester.fling(area, const Offset(0, -60), 2000);
    await tester.pumpAndSettle();

    expect(swipes, isEmpty);
  });

  testWidgets('distance counts from where the finger landed', (tester) async {
    await tester.pumpWidget(app());

    // Just over the minimum in total; less once the touch slop is removed.
    await tester.fling(
      area,
      const Offset(-(SwipeDetector.minDistance + 5), 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(swipes, ['left']);
  });

  testWidgets('a long but slow drag is ignored', (tester) async {
    await tester.pumpWidget(app());

    await tester.timedDrag(
      area,
      const Offset(-300, 0),
      const Duration(seconds: 3),
    );
    await tester.pumpAndSettle();

    expect(swipes, isEmpty);
  });

  testWidgets('without onSwipeUp, vertical drags still scroll the child',
      (tester) async {
    await tester.pumpWidget(
      app(
        swipeUp: false,
        child: ListView(
          children: [
            for (var i = 0; i < 50; i++)
              SizedBox(height: 100, child: Text('item $i')),
          ],
        ),
      ),
    );

    await tester.fling(area, const Offset(0, -400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('item 0'), findsNothing);
    expect(swipes, isEmpty);
  });
}
