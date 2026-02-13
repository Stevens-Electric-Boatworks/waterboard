// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/gauge.dart';
import '../../test_helpers/fakes/fake_ros.dart';
import '../../test_helpers/test_util.dart';

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Has Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(initialState: ROSConnectionState.connected);
    var dataGauge = ROSGaugeDataSource(
      sub: fakeROS.subscribe("/test/", initialData: {'test': 53.0}),
      valueBuilder: (json) {
        return json['test'];
      },
    );
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSGauge(
          dataSource: dataGauge,
          minimum: 10,
          maximum: 15,
          ranges: [],
          title: "Example Title",
          unitText: "RPM",
        ),
      ),
    );
    fakeROS.propagateData("/test/", {'test': 53.0});
    await widgetTester.pumpAndSettle();
    expect(find.text("Example Title"), findsOneWidget);
    expect(find.text("RPM"), findsOneWidget);
    expect(find.text("53.0"), findsOneWidget);
    await widgetTester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
  });
  testWidgets('No Initial Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(
      initialState: ROSConnectionState.noWebsocket,
    );
    var sub = fakeROS.subscribe("/test/");
    var dataGauge = ROSGaugeDataSource(
      sub: sub,
      valueBuilder: (json) {
        return 0.0;
      },
    );
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSGauge(
          dataSource: dataGauge,
          minimum: 10,
          maximum: 15,
          ranges: [],
          title: "Example Title",
          unitText: "RPM",
        ),
      ),
    );
    await widgetTester.pumpAndSettle();
    expect(find.text("Example Title"), findsOneWidget);
    expect(find.text("RPM"), findsOneWidget);
    expect(find.text("Unknown"), findsOneWidget);
    expect(find.byType(CustomPaint), findsNWidgets(2));
  });
}
