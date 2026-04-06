// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/gauge.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../test_helpers/test_util.dart';

Future<void> pumpPage(WidgetTester widgetTester, ROS ros) async {
  FlutterError.onError = ignoreOverflowErrors;
  await widgetTester.pumpWidget(
    MaterialApp(
      home: MainDriverPage(model: MainDriverPageViewModel(ros: ros)),
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
    expect(find.byType(ROSGauge), findsNWidgets(5));
    expect(find.widgetWithText(ROSGauge, "BMS Current"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Speed"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor RPM"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor A Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor B Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor RPM"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "Motor A Current"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "Motor B Current"), findsOneWidget);
  });
  testWidgets('Verify Correct Subscriptions', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    var subs = ros.subs;
    expect(subs.length, 5); // 2 repeated subscriptions for motor data
    expect(subs.keys, [
      '/rosout',
      '/bms/pack_summary',
      '/motors/motorA',
      '/motors/motorB',
      '/motion/vtg',
    ]);
  });
  testWidgets('Verify Correct JSON Parsing', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);

    ros.propagateData("/motion/vtg", {'track': 0.0, 'speed': 24.3});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "24"), findsOneWidget);

    ros.propagateData("/bms/pack_summary", {'pack_current_raw': 92});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "92"), findsOneWidget);

    ros.propagateData("/motors/motorA", {
      'voltage': 0.0,
      'rpm': 256,
      'current': 128,
      'motor_temp': 172,
    });
    ros.propagateData("/motors/motorB", {
      'voltage': 0.0,
      'rpm': -1,
      'current': 129,
      'motor_temp': 39,
    });
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "256"), findsOneWidget);

    expect(find.widgetWithText(ROSText, "128 A"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "129 A"), findsOneWidget);

    expect(find.widgetWithText(ROSGauge, "39"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "172"), findsOneWidget);
  });
}
