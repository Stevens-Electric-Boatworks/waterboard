// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/gauge.dart';
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
    expect(find.byType(ROSGauge), findsNWidgets(6));
    expect(find.widgetWithText(ROSGauge, "Motor Current"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Inlet Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Outlet Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor Temp"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Speed"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "Motor RPM"), findsOneWidget);
  });
  testWidgets('Verify Correct Subscriptions', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    var subs = ros.subs;
    expect(subs.length, 4); // 2 repeated subscriptions for motor data
    expect(subs.keys, [
      '/motors/can_motor_data',
      '/electrical/temp_sensors/in',
      '/electrical/temp_sensors/out',
      '/motion/vtg',
    ]);
  });
  testWidgets('Verify Correct JSON Parsing', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    ros.propagateData("/electrical/temp_sensors/in", {'inlet_temp': 13.2});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "13.0"), findsOneWidget);

    ros.propagateData("/electrical/temp_sensors/out", {'outlet_temp': 19.1});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "19.0"), findsOneWidget);

    ros.propagateData("/motion/vtg", {'track': 0.0, 'speed': 24.3});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "24.0"), findsOneWidget);

    ros.propagateData("/motors/can_motor_data", {
      'voltage': 0.0,
      'rpm': 256,
      'current': 128,
      'motor_temp': 172,
    });
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSGauge, "256.0"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "128.0"), findsOneWidget);
    expect(find.widgetWithText(ROSGauge, "172.0"), findsOneWidget);
  });
}
