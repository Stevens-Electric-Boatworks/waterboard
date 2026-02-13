// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../../test_helpers/fakes/fake_ros.dart';
import '../../test_helpers/test_util.dart';

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Has Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(initialState: ROSConnectionState.connected);
    var data = ROSTextDataSource(
      sub: fakeROS.subscribe("/test/", initialData: {'test': "ABCDEF"}),
      valueBuilder: (json) {
        return (json['test'], Colors.yellow);
      },
    );
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSText(subtext: "This is subtext", dataSource: data),
      ),
    );
    fakeROS.propagateData("/test/", {'test': "LMNOP"});
    await widgetTester.pumpAndSettle();
    var text = find.text("LMNOP");
    expect(text, findsOneWidget);
    final textWidget = widgetTester.widget<Text>(text);
    expect(textWidget.style?.color, Colors.yellow);

    expect(find.text("This is subtext"), findsOneWidget);
    await widgetTester.pumpAndSettle();
  });
  testWidgets('No Data', (widgetTester) async {
    FakeROS fakeROS = createFakeROS(initialState: ROSConnectionState.staleData);
    var data = ROSTextDataSource(
      sub: fakeROS.subscribe("/test/"),
      valueBuilder: (json) {
        return (json['test'], Colors.yellow);
      },
    );
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSText(subtext: "This is subtext", dataSource: data),
      ),
    );
    await widgetTester.pumpAndSettle();
    var text = find.text("Unknown");
    expect(text, findsOneWidget);
    final textWidget = widgetTester.widget<Text>(text);
    expect(textWidget.style?.color, Colors.grey);
    expect(find.text("This is subtext"), findsOneWidget);
    await widgetTester.pumpAndSettle();
  });
}
