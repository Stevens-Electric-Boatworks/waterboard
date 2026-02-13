// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_listenable_widget.dart';
import '../test_helpers/fakes/fake_ros.dart';
import '../test_helpers/test_util.dart';

void main() {
  testWidgets('Has Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(initialState: ROSConnectionState.connected);
    var sub = fakeROS.subscribe("/test/", initialData: {'test': 53.0});
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSListenable(
          valueNotifier: sub.notifier,
          builder: (context, value) {
            return Text("${value['test']}");
          },
          noDataBuilder: (context) => Text("No Data"),
        ),
      ),
    );
    //check if has data
    fakeROS.propagateData("/test/", {'test': 53.0});
    await widgetTester.pumpAndSettle();
    expect(find.text("53.0"), findsOneWidget);
    expect(
      find.byType(CustomPaint),
      findsOneWidget,
    ); //there is a custompaint caused by MaterialApp widget
  });
  testWidgets('No Initial Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(initialState: ROSConnectionState.connected);
    var sub = fakeROS.subscribe("/test/");
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSListenable(
          valueNotifier: sub.notifier,
          builder: (context, value) {
            return Text("${value['test']}");
          },
          noDataBuilder: (context) => Text("No Initial Data"),
        ),
      ),
    );
    await widgetTester.pumpAndSettle();
    expect(find.text("No Initial Data"), findsOneWidget);
    expect(find.byType(CustomPaint), findsNWidgets(2));
  });
  testWidgets('Has Data to Stale Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(initialState: ROSConnectionState.connected);
    var sub = fakeROS.subscribe("/test/");
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSListenable(
          valueNotifier: sub.notifier,
          builder: (context, value) {
            return Text("${value['test']}");
          },
          noDataBuilder: (context) => Text("No Initial Data"),
        ),
      ),
    );
    //check if has data
    fakeROS.propagateData("/test/", {'test': 53.0});
    await widgetTester.pumpAndSettle();
    expect(find.text("53.0"), findsOneWidget);
    expect(
      find.byType(CustomPaint),
      findsOneWidget,
    ); //there is a custompaint caused by MaterialApp widget

    //now move to no data
    await widgetTester.pump(const Duration(milliseconds: 2100));
    expect(find.text("53.0"), findsOneWidget);
    expect(
      find.byType(CustomPaint),
      findsNWidgets(2),
    ); //there is a custompaint caused by MaterialApp widget
  });
}
