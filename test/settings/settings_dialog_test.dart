// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/pages/standby_mode_page.dart';
import 'package:waterboard/settings/settings_dialog.dart';
import 'package:waterboard/widgets/time_text.dart';
import '../test_helpers/test_util.dart';
import '../test_helpers/test_util.mocks.dart';

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences instance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    instance = await SharedPreferences.getInstance();
  });
  testWidgets('Verify Layout', (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsDialog(ros: createMockOfflineROS())),
      ),
    );
    await widgetTester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(ClockText), findsOneWidget);
    expect(find.text("IP Address: "), findsOneWidget);
    expect(find.text("Port: "), findsOneWidget);
    expect(find.text("Lock Layout"), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, "Restart ROSBridge Comms"),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, "Enter Standby Mode"),
      findsOneWidget,
    );
  });
  group("Enterable Data", () {
    testWidgets('No Initial Data', (widgetTester) async {
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsDialog(ros: createMockOfflineROS())),
        ),
      );
      await widgetTester.pumpAndSettle();
      //default values
      expect(find.text("127.0.0.1"), findsOneWidget);
      expect(find.text("9090"), findsOneWidget);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(instance.getString("websocket.ip"), null);
      expect(instance.getInt("websocket.port"), null);

      var ipPrompt = find.byKey(Key("ip_address"));
      await widgetTester.enterText(ipPrompt, "192.172.1.3");
      await widgetTester.pumpAndSettle();
      expect(instance.getString("websocket.ip"), "192.172.1.3");

      var portPrompt = find.byKey(Key("port"));
      await widgetTester.enterText(portPrompt, "8281");
      await widgetTester.pumpAndSettle();
      expect(instance.getInt("websocket.port"), 8281);

      //validate new values
      expect(find.text("192.172.1.3"), findsOneWidget);
      expect(find.text("8281"), findsOneWidget);

      //find swtich
      var lockedLayout = find.byType(Switch);
      expect(lockedLayout, findsOneWidget);
      expect(instance.getBool("locked_layout"), null);
      expect(widgetTester.widget<Switch>(lockedLayout).value, false);
      await widgetTester.tap(lockedLayout);
      await widgetTester.pumpAndSettle();
      expect(instance.getBool("locked_layout"), true);
      expect(widgetTester.widget<Switch>(lockedLayout).value, true);
      await widgetTester.tap(lockedLayout);
      await widgetTester.pumpAndSettle();
      expect(instance.getBool("locked_layout"), false);
      expect(widgetTester.widget<Switch>(lockedLayout).value, false);
    });
    testWidgets('With Initial Data', (widgetTester) async {
      SharedPreferences.setMockInitialValues({
        'websocket.ip': "127.132.2.3",
        'websocket.port': 2712,
        'locked_layout': true,
      });
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsDialog(ros: createMockOfflineROS())),
        ),
      );
      await widgetTester.pumpAndSettle();
      //validate new values
      expect(find.text("127.132.2.3"), findsOneWidget);
      expect(find.text("2712"), findsOneWidget);

      var lockedLayout = find.byType(Switch);
      expect(widgetTester.widget<Switch>(lockedLayout).value, true);
    });
  });
  group("Verify Buttons", () {
    testWidgets('Restart ROSBridge Comms', (widgetTester) async {
      MockROSImpl mock = createMockOfflineROS();
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsDialog(ros: mock)),
        ),
      );
      await widgetTester.pumpAndSettle();
      var button = find.widgetWithText(FilledButton, "Restart ROSBridge Comms");
      expect(button, findsOneWidget);
      await widgetTester.tap(button);
      verify(mock.reconnect()).called(1);
    });
    testWidgets('Enter Standby Mode', (widgetTester) async {
      MockROSImpl mock = createMockOfflineROS();
      FlutterError.onError = ignoreOverflowErrors;
      await widgetTester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsDialog(ros: mock)),
        ),
      );
      await widgetTester.pumpAndSettle();
      var button = find.widgetWithText(FilledButton, "Enter Standby Mode");
      expect(button, findsOneWidget);
      await widgetTester.tap(button);
      await widgetTester.pumpAndSettle();
      expect(find.byType(StandbyModePage), findsOneWidget);
    });
  });
}
