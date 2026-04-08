// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/pages/motors_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/gauge.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../test_helpers/test_util.dart';

Future<void> pumpPage(WidgetTester widgetTester, ROS ros) async {
  FlutterError.onError = ignoreOverflowErrors;
  await widgetTester.pumpWidget(
    MaterialApp(
      home: MotorsPage(model: MotorsPageViewModel(ros: ros)),
    ),
  );
}

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Verify Correct Widgets', (widgetTester) async {
    await pumpPage(
      widgetTester,
      createFakeROS(initialState: ROSConnectionState.connected),
    );
    expect(find.byType(ROSGauge), findsNWidgets(8));
    expect(find.byType(ROSText), findsNWidgets(2));
    expect(find.widgetWithText(ROSGauge, "Motor A Current"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor A Voltage"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor A RPM"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor A Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor B Current"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor B Voltage"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor B RPM"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor B Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "Motor A"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "Motor B"), findsOneWidget);
  });
  testWidgets('Verify Correct Subscriptions', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    var subs = ros.subs;
    expect(subs.length, 3); // 2 repeated subscriptions for motor data
    expect(subs.keys, ['/rosout', '/motors/motorA', '/motors/motorB']);
  });
  testWidgets('Verify Correct JSON Parsing', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    ros.propagateData("/motors/motorB", {
      'voltage': 52.0,
      'rpm': 1800,
      'current': 128.0,
      'motor_temp': 21.2,
      'enabled': true,
    });
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "52"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "1800"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "128"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "21"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "ENABLED"), findsOneWidget);

    ros.propagateData("/motors/motorA", {
      'voltage': 47.5,
      'rpm': 2123,
      'current': 19.2,
      'motor_temp': 12.4,
      'enabled': false,
    });
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "47"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "2123"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "19"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "12"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "DISABLED"), findsOneWidget);
  });
}
