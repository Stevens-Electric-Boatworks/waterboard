// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/ros_widgets/marine_compass.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../test_helpers/fakes/fake_internet_checker.dart';
import '../test_helpers/test_util.dart';
import 'radios_page_test.mocks.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('Verify Correct Widgets', (widgetTester) async {
    await pumpPage(
      widgetTester,
      await createServicesRegistry(
        createFakeROS(initialState: ROSConnectionState.connected),
        createMockLogger(),
        createOfflineMockInternetChecker(),
      ),
    );
    // lat, long, sats count, speed
    expect(find.byType(ROSText), findsNWidgets(4));
    expect(find.text("Latitude"), findsOneWidget);
    expect(find.text("Longitude"), findsOneWidget);
    expect(find.text("Satellites"), findsOneWidget);
    expect(find.text("Speed (mph)"), findsOneWidget);
    expect(find.text("IP Address"), findsOneWidget);
    expect(find.text("Shore Reachable?"), findsOneWidget);
    expect(find.text("WiFi SSID"), findsOneWidget);
    expect(find.text("Cell Information"), findsOneWidget);
    expect(find.byType(MarineCompass), findsOneWidget);
  });
  testWidgets('Verify Correct Subscriptions', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(
      widgetTester,
      await createServicesRegistry(
        ros,
        createMockLogger(),
        createOfflineMockInternetChecker(),
      ),
    );
    var subs = ros.subs;
    expect(subs.keys, [
      '/rosout', //always subscribed
      '/motion/gps',
      '/motion/sv',
      '/motion/gsa',
      '/motion/vtg',
      '/cell',
    ]);
  });
  testWidgets('Verify Correct JSON Parsing', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(
      widgetTester,
      await createServicesRegistry(
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

    ros.propagateData("/motion/vtg", {'speed': 8.24, 'true_track': 14.0});
    await widgetTester.pumpAndSettle();
    expect(find.widgetWithText(ROSText, "8.2" /*2 sig figs*/), findsOneWidget);
    expect(find.widgetWithText(MarineCompass, "14°"), findsOneWidget);

    //cell information test
    expect(find.text("No Cell Data Received"), findsOneWidget);
    ros.propagateData("/cell", {
      "bars": 2,
      "network": "AT&T",
      "technology": "5G",
      "rsrp": -17,
      "rsrq": 56,
      "apn": "stable",
      "ip_addr": "192.167.1.2",
      "pin_status": "READY",
      "reg_status": 1,
    });
    await widgetTester.pumpAndSettle();
    expect(find.text("Bars:"), findsOneWidget);
    expect(find.text("RSRP:"), findsOneWidget);
    expect(find.text("RSRQ:"), findsOneWidget);
    expect(find.text("IP Address:"), findsOneWidget);
    expect(find.text("APN:"), findsOneWidget);
    expect(find.text("Network:"), findsOneWidget);
    expect(find.text("Technology:"), findsOneWidget);
    expect(find.text("Reg. Status:"), findsOneWidget);
    expect(find.text("Pin Status:"), findsOneWidget);

    expect(find.text("2"), findsOneWidget);
    expect(find.text("-17"), findsOneWidget);
    expect(find.text("56"), findsOneWidget);
    expect(find.text("192.167.1.2"), findsOneWidget);
    expect(find.text("stable"), findsOneWidget);
    expect(find.text("AT&T"), findsOneWidget);
    expect(find.text("5G"), findsOneWidget);
    expect(find.text("1"), findsOneWidget);
    expect(find.text("READY"), findsOneWidget);
  });
  group("Verify Internet State Widgets", () {
    testWidgets('Offline', (widgetTester) async {
      MockInternetChecker internetChecker = createOfflineMockInternetChecker();
      await pumpPage(
        widgetTester,
        await createServicesRegistry(
          createFakeROS(initialState: ROSConnectionState.connected),
          createMockLogger(),
          internetChecker,
        ),
      );
      expect(find.text("Disconnected"), findsNWidgets(2));
      expect(find.text("Unreachable"), findsOneWidget);
    });
    testWidgets('Online', (widgetTester) async {
      MockInternetChecker internetChecker = createOnlineMockInternetChecker(
        "Stevens-Net",
        "192.158.1.2",
      );
      await pumpPage(
        widgetTester,
        await createServicesRegistry(
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
        await createServicesRegistry(
          createFakeROS(initialState: ROSConnectionState.connected),
          createMockLogger(),
          internetChecker,
        ),
      );
      await widgetTester.pumpAndSettle();
      expect(find.text("Disconnected"), findsNWidgets(2));
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
      expect(find.text("Disconnected"), findsNWidgets(2));
      expect(find.text("Unreachable"), findsOneWidget);
    });
  });
  group("Satellite Information", () {
    testWidgets("No Data", (widgetTester) async {
      await pumpPage(
        widgetTester,
        await createServicesRegistry(
          createFakeROS(initialState: ROSConnectionState.noWebsocket),
          createMockLogger(),
          createOfflineMockInternetChecker(),
        ),
      );

      expect(find.text("GPS Satellites"), findsOneWidget);
      expect(find.text("No GPS Satellites Connected"), findsOneWidget);
      expect(find.text("No GSA Data"), findsOneWidget);
    });
    testWidgets("Only Satellite Data", (widgetTester) async {
      var ros = createFakeROS(initialState: ROSConnectionState.connected);
      await pumpPage(
        widgetTester,
        await createServicesRegistry(
          ros,
          createMockLogger(),
          createOfflineMockInternetChecker(),
        ),
      );
      var satsList = generateSatsList([
        SatelliteTestData(prn: 1, elev: 2, azimuth: 4, snr: 5),
        SatelliteTestData(prn: 6, elev: 7, azimuth: 8, snr: 9),
        SatelliteTestData(prn: 10, elev: 11, azimuth: 12, snr: 13),
      ]);
      ros.propagateData("/motion/sv", satsList);
      await widgetTester.pumpAndSettle();
      expect(find.text("GPS Satellites"), findsOneWidget);
      expect(find.text("No GPS Satellites Connected"), findsNothing);
      expect(find.text("No GSA Data"), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text("active"), findsOneWidget);
      expect(find.text("prn"), findsOneWidget);
      expect(find.text("snr"), findsOneWidget);
      expect(find.text("azimuth"), findsOneWidget);
      expect(find.text("elev"), findsOneWidget);
      expect(find.text("?"), findsNWidgets(3));

      //verify that it shows up in the table
      assertSatInDataTable(
        SatelliteTestData(prn: 1, elev: 2, azimuth: 4, snr: 5),
      );
      assertSatInDataTable(
        SatelliteTestData(prn: 6, elev: 7, azimuth: 8, snr: 9),
      );
      assertSatInDataTable(
        SatelliteTestData(prn: 10, elev: 11, azimuth: 12, snr: 13),
      );
    });
    testWidgets("Only GSA Data", (widgetTester) async {
      var ros = createFakeROS(initialState: ROSConnectionState.connected);
      await pumpPage(
        widgetTester,
        await createServicesRegistry(
          ros,
          createMockLogger(),
          createOfflineMockInternetChecker(),
        ),
      );
      ros.propagateData("/motion/gsa", {
        "op_mode": "A",
        "mode": 3,
        "prn": [1, 2, 3],
        "pdop": 0.01323,
        "hdop": 0.02323,
        "vdop": 0.03323,
        "system_id": 1,
      });
      await widgetTester.pumpAndSettle();
      expect(find.text("GPS Satellites"), findsOneWidget);
      expect(find.text("No GPS Satellites Connected"), findsOneWidget);
      expect(find.text("No GSA Data"), findsNothing);
      expect(find.byType(DataTable), findsNothing);
      expect(find.text("Operation Mode"), findsOneWidget);
      expect(find.text("Status"), findsOneWidget);
      expect(find.text("PDOP"), findsOneWidget);
      expect(find.text("VDOP"), findsOneWidget);
      expect(find.text("HDOP"), findsOneWidget);

      //verify that correct data is being used
      ros.propagateData("/motion/gsa", {
        "op_mode": "A",
        "mode": 3,
        "prn": [1, 2, 3],
        "pdop": 0.01323,
        "hdop": 0.02323,
        "vdop": 0.03323,
        "system_id": 1,
      });
      await widgetTester.pumpAndSettle();
      expect(find.text("AUTO"), findsOneWidget);
      expect(find.text("3D FIX"), findsOneWidget);
      expect(find.text("0.01"), findsOneWidget);
      expect(find.text("0.02"), findsOneWidget);
      expect(find.text("0.03"), findsOneWidget);

      //next mode
      ros.propagateData("/motion/gsa", {
        "op_mode": "M",
        "mode": 2,
        "prn": [],
        "pdop": 0.12323,
        "hdop": 0.13323,
        "vdop": 1.23323,
        "system_id": 1,
      });
      await widgetTester.pumpAndSettle();
      expect(find.text("MANUAL"), findsOneWidget);
      expect(find.text("2D FIX"), findsOneWidget);
      expect(find.text("0.1"), findsNWidgets(2));
      expect(find.text("1"), findsOneWidget);
      //next mode
      ros.propagateData("/motion/gsa", {
        "op_mode": "fsdfasfd", //corrupted data
        "mode": 1,
        "prn": [],
        "pdop": 0.12323,
        "hdop": 0.13323,
        "vdop": 1.23323,
        "system_id": 1,
      });
      await widgetTester.pumpAndSettle();
      expect(find.text("Unknown"), findsOneWidget);
      expect(find.text("NO FIX"), findsOneWidget);
      expect(find.text("0.1"), findsNWidgets(2));
      expect(find.text("1"), findsOneWidget);
      //next mode
      ros.propagateData("/motion/gsa", {
        "op_mode": "fsdfasfd", //corrupted data
        "mode": -192, //corrupted data
        "prn": [],
        "pdop": 0.12323,
        "hdop": 0.13323,
        "vdop": 1.23323,
        "system_id": 1,
      });
      await widgetTester.pumpAndSettle();
      expect(find.text("Unknown"), findsNWidgets(2));
      expect(find.text("0.1"), findsNWidgets(2));
      expect(find.text("1"), findsOneWidget);
    });
    testWidgets("GSA and Satellite Data", (widgetTester) async {
      var ros = createFakeROS(initialState: ROSConnectionState.connected);
      await pumpPage(
        widgetTester,
        await createServicesRegistry(
          ros,
          createMockLogger(),
          createOfflineMockInternetChecker(),
        ),
      );
      var satsList = generateSatsList([
        SatelliteTestData(prn: 1, elev: 2, azimuth: 4, snr: 5),
        SatelliteTestData(prn: 6, elev: 7, azimuth: 8, snr: 9),
        SatelliteTestData(prn: 10, elev: 11, azimuth: 12, snr: 13),
      ]);
      ros.propagateData("/motion/sv", satsList);
      ros.propagateData("/motion/gsa", {
        "op_mode": "A",
        "mode": 3,
        "prn": [1, 6],
        "pdop": 0.01323,
        "hdop": 0.02323,
        "vdop": 0.03323,
        "system_id": 1,
      });
      await widgetTester.pumpAndSettle();
      expect(find.text("No GPS Satellites Connected"), findsNothing);
      expect(find.text("No GSA Data"), findsNothing);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text("Operation Mode"), findsOneWidget);
      expect(find.text("Status"), findsOneWidget);
      expect(find.text("PDOP"), findsOneWidget);
      expect(find.text("VDOP"), findsOneWidget);
      expect(find.text("HDOP"), findsOneWidget);
      expect(find.text("AUTO"), findsOneWidget);
      expect(find.text("3D FIX"), findsOneWidget);
      expect(find.text("0.01"), findsOneWidget);
      expect(find.text("0.02"), findsOneWidget);
      expect(find.text("0.03"), findsOneWidget);

      //verify that we have 2 "Y"'s for the correct data being found
      expect(
        find.descendant(of: find.byType(DataTable), matching: find.text("Y")),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: find.byType(DataTable), matching: find.text("N")),
        findsOneWidget,
      );
      //update list with new satellite that is not included in the PRN list
      ros.propagateData(
        "/motion/sv",
        generateSatsList([
          SatelliteTestData(prn: 1, elev: 2, azimuth: 4, snr: 5),
          SatelliteTestData(prn: 6, elev: 7, azimuth: 8, snr: 9),
          SatelliteTestData(prn: 10, elev: 11, azimuth: 12, snr: 13),
          SatelliteTestData(prn: 19, elev: 20, azimuth: 21, snr: 22),
        ]),
      );
      await widgetTester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(DataTable), matching: find.text("Y")),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: find.byType(DataTable), matching: find.text("N")),
        findsNWidgets(2),
      );
    });
  });
}

class SatelliteTestData {
  final int prn;
  final int elev;
  final int azimuth;
  final int snr;

  SatelliteTestData({
    required this.prn,
    required this.elev,
    required this.azimuth,
    required this.snr,
  });
  static Map<String, dynamic> toJson(SatelliteTestData value) => {
    'prn': value.prn,
    'elev': value.elev,
    'azimuth': value.azimuth,
    'snr': value.snr,
  };
}

void assertSatInDataTable(SatelliteTestData data) {
  void text(String txt) {
    expect(
      find.descendant(of: find.byType(DataTable), matching: find.text(txt)),
      findsOneWidget,
    );
  }

  text("${data.snr}");
  text("${data.prn}");
  text("${data.azimuth}");
  text("${data.elev}");
}

Map<String, dynamic> generateSatsList(List<SatelliteTestData> items) {
  return jsonDecode(
    jsonEncode(
      {"sats": items},
      toEncodable: (Object? value) => value is SatelliteTestData
          ? SatelliteTestData.toJson(value)
          : throw UnsupportedError('Cannot convert to JSON: $value'),
    ),
  );
}
