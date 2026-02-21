// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mockito/annotations.dart';

// Project imports:
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/ros_widgets/marine_compass.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../test_helpers/fakes/fake_internet_checker.dart';
import '../test_helpers/test_util.dart';
import 'radios_page.mocks.dart';

@GenerateNiceMocks([MockSpec<InternetChecker>()])
Future<void> pumpPage(WidgetTester widgetTester, Services services) async {
  FlutterError.onError = ignoreOverflowErrors;
  await widgetTester.pumpWidget(
    MaterialApp(
      home: RadiosPage(model: RadiosPageViewModel(services: services)),
    ),
  );
}

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Verify Correct Widgets', (widgetTester) async {
    await pumpPage(
      widgetTester,
      createServicesRegistry(
        createFakeROS(initialState: ROSConnectionState.connected),
        createMockLogger(),
        createOfflineMockInternetChecker(),
      ),
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
    await pumpPage(
      widgetTester,
      createServicesRegistry(
        ros,
        createMockLogger(),
        createOfflineMockInternetChecker(),
      ),
    );
    var subs = ros.subs;
    expect(subs.length, 6);
    expect(subs.keys, [
      '/motion/gps',
      '/motion/sv',
      '/motion/vtg',
      '/motion/gps/alt',
      '/motion/gps/climb',
      '/cell',
    ]);
  });
  testWidgets('Verify Correct JSON Parsing', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(
      widgetTester,
      createServicesRegistry(
        ros,
        createMockLogger(),
        createOfflineMockInternetChecker(),
      ),
    );
    ros.propagateData("/motion/gps", {
      'lat': 13.2271727371,
      'lon': -72.1726368282,
    });
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
  group("Verify Internet State Widgets", () {
    testWidgets('Offline', (widgetTester) async {
      MockInternetChecker internetChecker = createOfflineMockInternetChecker();
      await pumpPage(
        widgetTester,
        createServicesRegistry(
          createFakeROS(initialState: ROSConnectionState.connected),
          createMockLogger(),
          internetChecker,
        ),
      );
      expect(find.text("Not Connected"), findsNWidgets(2));
      expect(find.text("Unreachable"), findsOneWidget);
    });
    testWidgets('Online', (widgetTester) async {
      MockInternetChecker internetChecker = createOnlineMockInternetChecker(
        "Stevens-Net",
        "192.158.1.2",
      );
      await pumpPage(
        widgetTester,
        createServicesRegistry(
          createFakeROS(initialState: ROSConnectionState.connected),
          createMockLogger(),
          internetChecker,
        ),
      );
      await widgetTester.pumpAndSettle();
      expect(find.text("Stevens-Net"), findsOneWidget);
      expect(find.text("192.158.1.2"), findsOneWidget);
      expect(find.text("Reachable"), findsOneWidget);
    });
    testWidgets('Offline to Online to Offline', (widgetTester) async {
      FakeInternetChecker internetChecker = createFakeInternetChecker();
      await pumpPage(
        widgetTester,
        createServicesRegistry(
          createFakeROS(initialState: ROSConnectionState.connected),
          createMockLogger(),
          internetChecker,
        ),
      );
      await widgetTester.pumpAndSettle();
      expect(find.text("Not Connected"), findsNWidgets(2));
      expect(find.text("Unreachable"), findsOneWidget);

      internetChecker.controller.add(InternetStatus.connected);
      internetChecker.ipAddress.value = "192.168.1.3";
      internetChecker.ssid.value = "Stevens-Net";
      await widgetTester.pumpAndSettle();
      expect(find.text("Stevens-Net"), findsOneWidget);
      expect(find.text("192.168.1.3"), findsOneWidget);
      expect(find.text("Reachable"), findsOneWidget);

      internetChecker.controller.add(InternetStatus.disconnected);
      internetChecker.ipAddress.value = null;
      internetChecker.ssid.value = null;
      await widgetTester.pumpAndSettle();
      expect(find.text("Not Connected"), findsNWidgets(2));
      expect(find.text("Unreachable"), findsOneWidget);
    });
  });
}
