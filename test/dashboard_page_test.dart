// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/dashboard_page.dart';
import 'package:waterboard/debug_vars.dart';
import 'package:waterboard/messages.dart';
import 'package:waterboard/pages/electrics_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/settings/settings_dialog.dart';
import 'package:waterboard/widgets/ros_connection_state_widget.dart';
import 'package:waterboard/widgets/time_text.dart';
import 'test_helpers/fakes/fake_ros.dart';
import 'test_helpers/test_util.dart';

Future<DashboardPageViewModel> pumpDashboardPage(
  WidgetTester widgetTester,
  ROS ros,
  SharedPreferences preferences, {
  Size? size = const Size(1200, 820),
}) async {
  FlutterError.onError = ignoreOverflowErrors;
  if (size != null) {
    widgetTester.view.physicalSize = size;
    widgetTester.view.devicePixelRatio = 1.0;
  }

  var model = DashboardPageViewModel(ros);
  await widgetTester.pumpWidget(MaterialApp(home: DashboardPage(model: model)));
  return model;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    DebugVariables.loadMap = false;
  });
  group("Main Page", () {
    testWidgets('Main Page Layout', (widgetTester) async {
      await pumpDashboardPage(
        widgetTester,
        createMockOfflineROS(),
        preferences,
      );
      void checkInsideAppbar(Finder finder) {
        expect(
          find.descendant(of: find.byType(AppBar), matching: finder),
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
          FakeROS(initialState: ROSConnectionState.connected),
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
        expect(find.byType(ElectricsPage), findsOneWidget);

        //verify correct pages
        await moveRight();
        expect(model.currentPage, 2);
        expect(find.byType(Placeholder), findsOneWidget);

        await moveRight();
        expect(model.currentPage, 3);
        expect(find.byType(RadiosPage), findsOneWidget);

        await moveRight();
        expect(model.currentPage, 4);
        expect(find.byType(Placeholder), findsOneWidget);

        await moveRight();
        expect(model.currentPage, 5);
        expect(find.byType(Placeholder), findsOneWidget);

        //verify moving right does nothing
        await moveRight();
        expect(model.currentPage, 5);
        expect(find.byType(Placeholder), findsOneWidget);

        //verify that we can move back
        await moveLeft();
        expect(model.currentPage, 4);
        expect(find.byType(Placeholder), findsOneWidget);

        await moveLeft();
        expect(model.currentPage, 3);
        expect(find.byType(RadiosPage), findsOneWidget);
      });
      testWidgets('Settings Dialog', (widgetTester) async {
        await pumpDashboardPage(
          widgetTester,
          FakeROS(initialState: ROSConnectionState.connected),
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
        SharedPreferences.setMockInitialValues({'locked_layout': true});
        preferences = await SharedPreferences.getInstance();

        var model = await pumpDashboardPage(
          widgetTester,
          FakeROS(initialState: ROSConnectionState.connected),
          preferences,
        );
        Future<void> moveRight() async {
          await widgetTester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await widgetTester.pumpAndSettle();
        }

        //on page 0, verify that moving right does nothing,
        await moveRight();
        expect(model.currentPage, 0);
        expect(find.byType(MainDriverPage), findsOneWidget);
        expect(find.byType(ElectricsPage), findsNothing);

        preferences.setBool("locked_layout", false);
        await moveRight();
        expect(model.currentPage, 1);
        expect(find.byType(MainDriverPage), findsNothing);
        expect(find.byType(ElectricsPage), findsOneWidget);
      });
    });
  });
  group("Connection Dialogs", () {
    testWidgets('Websocket Disconnected', (widgetTester) async {
      await pumpDashboardPage(
        widgetTester,
        createMockOfflineROS(),
        preferences,
      );
      await widgetTester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.widgetWithText(
          Dialog,
          ConnectionDialogMessages.websocketDisconnectTitle,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          Dialog,
          ConnectionDialogMessages.websocketDisconnectBody,
        ),
        findsOneWidget,
      );

      _testDialogButtons(widgetTester);
    });
    testWidgets('ROS Stale Data', (widgetTester) async {
      await pumpDashboardPage(
        widgetTester,
        createMockOfflineROS(initialState: ROSConnectionState.staleData),
        preferences,
      );
      await widgetTester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      //find expected messages
      expect(
        find.widgetWithText(Dialog, ConnectionDialogMessages.staleDataTitle),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(Dialog, ConnectionDialogMessages.staleDataBody),
        findsOneWidget,
      );
      _testDialogButtons(widgetTester);
    });
    testWidgets('ROS Connected (No Dialog)', (widgetTester) async {
      await pumpDashboardPage(
        widgetTester,
        createFakeROS(initialState: ROSConnectionState.connected),
        preferences,
      );
      await widgetTester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });
  testWidgets('ROS Connection State Text', (widgetTester) async {
    FakeROS ros = createFakeROS();
    await pumpDashboardPage(widgetTester, ros, preferences);
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

void _testDialogButtons(WidgetTester widgetTester) async {
  //settings button works
  var settingsButton = find.widgetWithText(TextButton, "Open Settings");
  expect(settingsButton, findsOneWidget);
  await widgetTester.tap(settingsButton);
  await widgetTester.pumpAndSettle();
  expect(
    find.byType(SettingsDialog),
    findsOneWidget,
    reason:
        "The settings dialog did not open after hitting the settings button.",
  );

  //close settings page
  await widgetTester.sendKeyDownEvent(LogicalKeyboardKey.escape);
  await widgetTester.pumpAndSettle();
  expect(
    find.byType(SettingsDialog),
    findsNothing,
    reason: "The settings dialog did not close",
  );

  //verify dialog is still there
  expect(find.byType(Dialog), findsOneWidget);

  //close button works
  var closeButton = find.widgetWithText(TextButton, "Close Dialog");
  expect(closeButton, findsOneWidget);
  await widgetTester.tap(closeButton);
  await widgetTester.pumpAndSettle();
  expect(
    find.byType(Dialog),
    findsNothing,
    reason: "The dialog was not closed after hitting the close button.",
  );
}
