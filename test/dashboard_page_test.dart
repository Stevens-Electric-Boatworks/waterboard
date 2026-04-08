// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/dashboard_page.dart';
import 'package:waterboard/messages.dart';
import 'package:waterboard/pages/logs_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/motors_page.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/pages/system_page.dart';
import 'package:waterboard/pref_keys.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/settings/settings_dialog.dart';
import 'package:waterboard/widgets/custom_app_bar_widget.dart';
import 'package:waterboard/widgets/ros_widgets/ros_connection_state_widget.dart';
import 'package:waterboard/widgets/time_text.dart';
import 'test_helpers/fakes/fake_ros.dart';
import 'test_helpers/test_util.dart';

Future<DashboardPageViewModel> pumpDashboardPage(
  WidgetTester widgetTester,
  Services services,
  SharedPreferences preferences, {
  Size? size = const Size(1200, 820),
}) async {
  FlutterError.onError = ignoreOverflowErrors;
  if (size != null) {
    widgetTester.view.physicalSize = size;
    widgetTester.view.devicePixelRatio = 1.0;
  }
  DashboardPageViewModel model = DashboardPageViewModel(services);
  await widgetTester.pumpWidget(MaterialApp(home: DashboardPage(model: model)));
  return model;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  group("Main Page", () {
    testWidgets('Main Page Layout', (widgetTester) async {
      await pumpDashboardPage(
        widgetTester,
        await createServicesRegistry(
          createMockOfflineROS(),
          createMockLogger(),
          createOfflineMockInternetChecker(),
        ),
        preferences,
      );
      void checkInsideAppbar(Finder finder) {
        expect(
          find.descendant(
            of: find.byType(WaterboardAppBarWidget),
            matching: finder,
          ),
          findsOneWidget,
        );
      }

      checkInsideAppbar(find.text("Stevens Electric Boatworks"));
      checkInsideAppbar(find.byType(ClockText));
      checkInsideAppbar(find.byType(ROSConnectionStateWidget));

      expect(find.byType(BottomNavigationBar), findsOneWidget);

      //verify settings button
      checkInsideAppbar(find.widgetWithIcon(IconButton, Icons.settings));
    });
    group("Main Page Keybinds", () {
      testWidgets('Page Switching', (widgetTester) async {
        var model = await pumpDashboardPage(
          widgetTester,
          await createServicesRegistry(
            FakeROS(initialState: ROSConnectionState.connected),
            createMockLogger(),
            createOnlineMockInternetChecker("Stevens-Net", "127.0.0.1"),
          ),
          preferences,
        );
        Future<void> moveRight() async {
          await widgetTester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await widgetTester.pumpAndSettle();
        }

        Future<void> moveLeft() async {
          await widgetTester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await widgetTester.pumpAndSettle();
        }

        //on page 0, verify that moving left does nothing
        expect(model.currentPage, 0);
        await moveLeft();
        expect(model.currentPage, 0);
        expect(find.byType(MainDriverPage), findsOneWidget);

        //on page 1, verify that moving right does something, and moves us to the correct page
        await moveRight();
        expect(model.currentPage, 1);
        expect(find.byType(MotorsPage), findsOneWidget);

        await moveRight();
        expect(model.currentPage, 2);
        expect(find.byType(RadiosPage), findsOneWidget);

        await moveRight();
        expect(model.currentPage, 3);
        expect(find.byType(LogsPage), findsOneWidget);

        await moveRight();
        expect(model.currentPage, 4);
        expect(find.byType(SystemPage), findsOneWidget);

        //verify pressing right does nothing
        await moveRight();
        expect(model.currentPage, 4);
        expect(find.byType(SystemPage), findsOneWidget);
        //verify that we can move back
        await moveLeft();
        expect(model.currentPage, 3);
        expect(find.byType(LogsPage), findsOneWidget);

        await moveLeft();
        expect(model.currentPage, 2);
        expect(find.byType(RadiosPage), findsOneWidget);

        await moveLeft();
        expect(model.currentPage, 1);
        expect(find.byType(MotorsPage), findsOneWidget);

        await moveLeft();
        expect(model.currentPage, 0);
        expect(find.byType(MainDriverPage), findsOneWidget);
      });
      testWidgets('Settings Dialog', (widgetTester) async {
        await pumpDashboardPage(
          widgetTester,
          await createServicesRegistry(
            FakeROS(initialState: ROSConnectionState.connected),
            createMockLogger(),
            createOnlineMockInternetChecker("Stevens-Net", "127.0.0.1"),
          ),
          preferences,
        );
        expect(find.byType(SettingsDialog), findsNothing);

        await widgetTester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await widgetTester.pumpAndSettle();
        expect(find.byType(SettingsDialog), findsOneWidget);

        await widgetTester.sendKeyEvent(LogicalKeyboardKey.escape);
        await widgetTester.pumpAndSettle();
        expect(find.byType(SettingsDialog), findsNothing);
      });
      testWidgets('Locked Layout', (widgetTester) async {
        SharedPreferences.setMockInitialValues({PrefKeys.layoutLocked: true});
        preferences = await SharedPreferences.getInstance();
        TestWidgetsFlutterBinding.ensureInitialized();

        var model = await pumpDashboardPage(
          widgetTester,
          await createServicesRegistry(
            FakeROS(initialState: ROSConnectionState.connected),
            createMockLogger(),
            createOnlineMockInternetChecker("Stevens-Net", "127.0.0.1"),
          ),
          preferences,
        );
        Future<void> moveRight() async {
          await widgetTester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await widgetTester.pump(Duration(seconds: 1));
        }

        //on page 0, verify that moving right does nothing,
        await moveRight();
        expect(model.currentPage, 0);
        expect(find.byType(MainDriverPage), findsOneWidget);
        expect(find.byType(MotorsPage), findsNothing);

        await preferences.setBool(PrefKeys.layoutLocked, false);
        await moveRight();
        expect(model.currentPage, 1);
        expect(find.byType(MainDriverPage), findsNothing);
        expect(find.byType(MotorsPage), findsOneWidget);
      });
    });
  });
  testWidgets('ROS Connection State Text', (widgetTester) async {
    FakeROS ros = createFakeROS();
    await pumpDashboardPage(
      widgetTester,
      await createServicesRegistry(
        ros,
        createMockLogger(),
        createOfflineMockInternetChecker(),
      ),
      preferences,
    );
    await widgetTester.pumpAndSettle();
    expect(find.text(ROSConnectionStateMessages.noWebsocket), findsOneWidget);

    ros.connectionState.value = ROSConnectionState.staleData;
    await widgetTester.pumpAndSettle();
    expect(find.text(ROSConnectionStateMessages.staleData), findsOneWidget);

    ros.connectionState.value = ROSConnectionState.connected;
    await widgetTester.pumpAndSettle();
    expect(find.text(ROSConnectionStateMessages.rosConnected), findsOneWidget);
  });
}
