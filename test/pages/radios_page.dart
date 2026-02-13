// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/marine_compass.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';

import '../test_helpers/test_util.dart';

Future<void> pumpPage(WidgetTester widgetTester, ROS ros) async {
  FlutterError.onError = ignoreOverflowErrors;
  await widgetTester.pumpWidget(
    MaterialApp(
      home: RadiosPage(model: RadiosPageViewModel(ros: ros)),
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
    expect(find.byType(ROSText), findsNWidgets(7));
    expect(find.text("Latitude"), findsOneWidget);
    expect(find.text("Longitude"), findsOneWidget);
    expect(find.text("Satellites"), findsOneWidget);
    expect(find.text("Speed (mph)"), findsOneWidget);
    expect(find.text("Altitude"), findsOneWidget);
    expect(find.text("Climb"), findsOneWidget);
    expect(find.text("IP Address"), findsOneWidget);
    expect(find.text("Shore Reachable?"), findsOneWidget);
    expect(find.text("WiFi SSID"), findsOneWidget);
    expect(find.text("Cell Strength"), findsOneWidget);
    expect(find.text("shore.stevenseboat.org"), findsOneWidget);
    expect(find.text("Shore URL"), findsOneWidget);


    //TODO: add proper map testing
    expect(find.text("The map is loading..."), findsOneWidget);


  });
  testWidgets('Verify Correct Subscriptions', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    var subs = ros.subs;
    expect(subs.length, 6);
    expect(subs.keys, [
      '/motion/gps',
      '/motion/sv',
      '/motion/vtg',
      '/motion/gps/alt',
      '/motion/gps/climb',
      '/cell'
    ]);
  });
  testWidgets('Verify Correct JSON Parsing', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    ros.propagateData("/motion/gps", {'lat': 13.2271727371, 'lon': -72.1726368282});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSText, "13.2271727371"), findsOneWidget);
    expect(find.widgetWithText(ROSText, "-72.1726368282"), findsOneWidget);

    ros.propagateData("/motion/sv", {'sats': 12});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSText, "12"), findsOneWidget);

    ros.propagateData("/motion/vtg", {'speed': 8.24, 'true_track': 14.0});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSText, "8.2" /*2 sig figs*/), findsOneWidget);
    expect(find.widgetWithText(MarineCompass, "14.0°"), findsOneWidget);

    //alt, cell, and climb are all unimplemented
    expect(find.widgetWithText(ROSText, "Unknown"), findsNWidgets(3));

  });
  // testWidgets('Verify Internet State', (widgetTester) async {
  //   await pumpPage(
  //     widgetTester,
  //     createFakeROS(initialState: ROSConnectionState.connected),
  //   );
  //   expect(find.byType(ROSText), findsNWidgets(7));
  //   expect(find.text("Latitude"), findsOneWidget);
  //   expect(find.text("Longitude"), findsOneWidget);
  //   expect(find.text("Satellites"), findsOneWidget);
  //   expect(find.text("Speed (mph)"), findsOneWidget);
  //   expect(find.text("Altitude"), findsOneWidget);
  //   expect(find.text("Climb"), findsOneWidget);
  //   expect(find.text("IP Address"), findsOneWidget);
  //   expect(find.text("Shore Reachable?"), findsOneWidget);
  //   expect(find.text("WiFi SSID"), findsOneWidget);
  //   expect(find.text("Cell Strength"), findsOneWidget);
  //   expect(find.text("shore.stevenseboat.org"), findsOneWidget);
  //   expect(find.text("Shore URL"), findsOneWidget);
  //
  //
  //   //TODO: add proper map testing
  //   expect(find.text("The map is loading..."), findsOneWidget);
  //
  //
  // });

}
