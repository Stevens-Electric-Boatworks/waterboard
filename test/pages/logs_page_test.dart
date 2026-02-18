// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

// Project imports:
import 'package:waterboard/debug_vars.dart';
import 'package:waterboard/pages/logs_page.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';
import 'package:waterboard/services/time.dart';
import '../test_helpers/test_util.dart';

DateTime get time => DateTime(2025, 9, 7, 5, 30, 17);
Future<void> pumpPage(WidgetTester widgetTester, ROS ros) async {
  FlutterError.onError = ignoreOverflowErrors;
  widgetTester.view.physicalSize = Size(1200, 800);
  widgetTester.view.devicePixelRatio = 1.0;
  await widgetTester.pumpWidget(
    MaterialApp(
      home: LogsPage(model: LogsPageViewModel(ros: ros)),
    ),
  );
}

//TODO: This entire test is so, so bad, this needs to be fixed ASAP with a ServicesAPI
void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    //clean up test state
    Log.instance.msgs.clear();
    Log.instance.onMessage.value = null;
  });
  testWidgets('Verify Correct Widgets', (widgetTester) async {
    await pumpPage(
      widgetTester,
      createFakeROS(initialState: ROSConnectionState.connected),
    );
    expect(find.text("Control System Logs"), findsOneWidget);
    expect(find.byType(SegmentedButton<Emitter>), findsOneWidget);
    expect(find.text("All"), findsOneWidget);
    expect(find.text("ROS"), findsOneWidget);
    expect(find.text("Waterboard"), findsOneWidget);
    expect(
      find.byType(Table),
      findsNWidgets(2),
    ); // we stack tables on top to freeze the top row
  });
  testWidgets('Verify Correct Subscriptions', (widgetTester) async {
    var ros = createFakeROS(initialState: ROSConnectionState.connected);
    await pumpPage(widgetTester, ros);
    var subs = ros.subs;
    expect(subs.keys, ['/rosout']);
  });
  group("On Log Message Sent", () {
    group("No Initial Data", () {
      testWidgets("ROSOut Logs", (widgetTester) async {
        DebugVariables.waterboardLogging = false;
        var ros = createFakeROS(initialState: ROSConnectionState.connected);
        await pumpPage(widgetTester, ros);
        var msg = ROSLog(
          msg: 'This is a log message',
          file: 'file.txt',
          function: 'Main.java',
          line: 12,
          level: 'INFO',
          time: time,
        );
        sendROSLog(ros, msg);
        await widgetTester.pumpAndSettle();
        findROSMessage(msg, 1);
      });
      testWidgets("Flutter Logs", (widgetTester) async {
        DebugVariables.waterboardLogging = true;
        Time.instance.clock = Clock.fixed(time);
        var ros = createFakeROS(initialState: ROSConnectionState.connected);
        await pumpPage(widgetTester, ros);
        sendFlutterLog("This is a flutter log message", Level.info);
        await widgetTester.pumpAndSettle();
        findFlutterLogMessage(
          "This is a flutter log message",
          Level.info,
          time,
        );
      });
    });
    group("Initial Data", () {
      testWidgets("ROSOut Logs", (widgetTester) async {
        DebugVariables.waterboardLogging = false;
        var ros = createFakeROS(initialState: ROSConnectionState.connected);
        var log = ROSLog(
          msg: 'This is a log message',
          file: 'file.txt',
          function: 'Main.java',
          line: 12,
          level: 'INFO',
          time: time,
        );
        sendROSLog(ros, log);
        await pumpPage(widgetTester, ros);
        await widgetTester.pumpAndSettle();
        findROSMessage(log, 1);

        log = ROSLog(
          msg: 'This is a second log message',
          file: 'file2.txt',
          function: 'Main2.java',
          line: 15,
          level: 'ERROR',
          time: time.add(Duration(hours: 1)),
        );
        sendROSLog(ros, log);
        await widgetTester.pumpAndSettle();
        expect(find.widgetWithText(Table, log.msg), findsNWidgets(1));
        expect(find.widgetWithText(Table, log.function), findsNWidgets(1));
        expect(find.widgetWithText(Table, log.file), findsNWidgets(1));
        expect(find.widgetWithText(Table, log.level), findsNWidgets(1));
        expect(find.widgetWithText(Table, "${log.line}"), findsNWidgets(1));
        expect(
          find.widgetWithText(
            Table,
            "${log.time.hour}:${log.time.minute}:${log.time.second} AM",
          ),
          findsNWidgets(1),
        );
        expect(find.widgetWithText(Table, "ROS"), findsNWidgets(2));
      });
      testWidgets("Flutter Logs", (widgetTester) async {
        DebugVariables.waterboardLogging = true;
        Time.instance.clock = Clock.fixed(time);
        sendFlutterLog("This is a flutter log message", Level.info);

        var ros = createFakeROS(initialState: ROSConnectionState.connected);
        await pumpPage(widgetTester, ros);
        await widgetTester.pumpAndSettle();
        findFlutterLogMessage(
          "This is a flutter log message",
          Level.info,
          time,
        );
        sendFlutterLog("This is a flutter log message #2", Level.warning);
        await widgetTester.pumpAndSettle();
        expect(
          find.widgetWithText(Table, "This is a flutter log message #2"),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(Table, Level.warning.name.toUpperCase()),
          findsOneWidget,
        );
        expect(find.widgetWithText(Table, ""), findsNWidgets(6));
        expect(
          find.widgetWithText(
            Table,
            "${time.hour}:${time.minute}:${time.second} AM",
          ),
          findsNWidgets(2),
        );
        expect(find.widgetWithText(Table, "DASH"), findsNWidgets(2));
      });
    });
  });
  group("Message Filtering", () {
    testWidgets("With Data", (widgetTester) async {
      DebugVariables.waterboardLogging = false;
      Time.instance.clock = Clock.fixed(time);
      var ros = createFakeROS(initialState: ROSConnectionState.connected);
      var log = ROSLog(
        msg: 'This is a log message',
        file: 'file.txt',
        function: 'Main.java',
        line: 12,
        level: 'INFO',
        time: time,
      );
      sendROSLog(ros, log);
      DebugVariables.waterboardLogging = true;
      sendFlutterLog("This is a flutter log message", Level.warning);
      await pumpPage(widgetTester, ros);
      await widgetTester.pumpAndSettle();
      expect(find.widgetWithText(Table, log.msg), findsNWidgets(1));
      expect(find.widgetWithText(Table, log.function), findsNWidgets(1));
      expect(find.widgetWithText(Table, log.level), findsNWidgets(1));
      expect(find.widgetWithText(Table, log.file), findsNWidgets(1));
      expect(find.widgetWithText(Table, "${log.line}"), findsNWidgets(1));
      expect(
        find.widgetWithText(
          Table,
          "${log.time.hour}:${log.time.minute}:${log.time.second} AM",
        ),
        findsNWidgets(2),
      );
      expect(find.widgetWithText(Table, "ROS"), findsNWidgets(1));

      expect(
        find.widgetWithText(Table, "This is a flutter log message"),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(Table, Level.warning.name.toUpperCase()),
        findsOneWidget,
      );
      expect(find.widgetWithText(Table, ""), findsNWidgets(3));
      expect(
        find.widgetWithText(
          Table,
          "${time.hour}:${time.minute}:${time.second} AM",
        ),
        findsNWidgets(2),
      );
      expect(find.widgetWithText(Table, "DASH"), findsNWidgets(1));

      //click on the segmentedbuttons
      await widgetTester.tap(find.byIcon(Icons.computer));
      await widgetTester.pumpAndSettle();
      findROSMessage(log, 1);
      expect(
        find.widgetWithText(Table, "This is a flutter log message"),
        findsNothing,
      );
      expect(
        find.widgetWithText(Table, Level.warning.name.toUpperCase()),
        findsNothing,
      );
      expect(find.widgetWithText(Table, ""), findsNothing);
      expect(
        find.widgetWithText(
          Table,
          "${time.hour}:${time.minute}:${time.second} AM",
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(Table, "DASH"), findsNothing);

      await widgetTester.tap(find.byIcon(Icons.water_drop));
      await widgetTester.pumpAndSettle();
      expect(find.widgetWithText(Table, log.msg), findsNothing);
      expect(find.widgetWithText(Table, log.function), findsNothing);
      expect(find.widgetWithText(Table, log.level), findsNothing);
      expect(find.widgetWithText(Table, log.file), findsNothing);
      expect(find.widgetWithText(Table, "${log.line}"), findsNothing);
      expect(
        find.widgetWithText(
          Table,
          "${log.time.hour}:${log.time.minute}:${log.time.second} AM",
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(Table, "ROS"), findsNothing);
      findFlutterLogMessage(
        "This is a flutter log message",
        Level.warning,
        time,
      );
    });
  });
}

void sendFlutterLog(String message, Level level) {
  Log.instance.log(level, message);
}

void findROSMessage(ROSLog log, int amount) async {
  expect(find.widgetWithText(Table, log.msg), findsNWidgets(amount));
  expect(find.widgetWithText(Table, log.function), findsNWidgets(amount));
  expect(find.widgetWithText(Table, log.level), findsNWidgets(amount));
  expect(find.widgetWithText(Table, log.file), findsNWidgets(amount));
  expect(find.widgetWithText(Table, "${log.line}"), findsNWidgets(amount));
  expect(
    find.widgetWithText(
      Table,
      "${log.time.hour}:${log.time.minute}:${log.time.second} AM",
    ),
    findsNWidgets(amount),
  );
  expect(find.widgetWithText(Table, "ROS"), findsNWidgets(amount));
}

void findFlutterLogMessage(String msg, Level level, DateTime time) async {
  expect(find.widgetWithText(Table, msg), findsOneWidget);
  expect(find.widgetWithText(Table, level.name.toUpperCase()), findsOneWidget);
  expect(find.widgetWithText(Table, ""), findsNWidgets(3));
  expect(
    find.widgetWithText(Table, "${time.hour}:${time.minute}:${time.second} AM"),
    findsOneWidget,
  );
  expect(find.widgetWithText(Table, "DASH"), findsOneWidget);
}

void sendROSLog(ROS ros, ROSLog log) {
  ros.rosLogs.logs.add(log);
  ros.rosLogs.onLogMessage.value = log;
}
