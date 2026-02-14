// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:waterboard/pages/standby_mode_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_connection_state_widget.dart';
import 'package:waterboard/widgets/time_text.dart';
import '../test_helpers/test_util.dart';

Future<void> pumpPage(WidgetTester widgetTester, ROS ros) async {
  FlutterError.onError = ignoreOverflowErrors;
  await widgetTester.pumpWidget(MaterialApp(home: StandbyModePage(ros: ros)));
}

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Verify Correct Widgets', (widgetTester) async {
    await pumpPage(
      widgetTester,
      createFakeROS(initialState: ROSConnectionState.connected),
    );
    expect(find.byType(ClockText), findsOneWidget);
    expect(find.byType(ROSConnectionStateWidget), findsOneWidget);

    await widgetTester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await widgetTester.pumpAndSettle();

    expect(find.byType(ROSConnectionStateWidget), findsOneWidget);
    expect(find.text("Our Sponsors"), findsOneWidget);
    expect(find.text("Platinum "), findsOneWidget);
    expect(find.text("Sponsors"), findsOneWidget);
    expect(find.text("Sponsor"), findsNWidgets(2));
    expect(find.text("Gold "), findsOneWidget);
    expect(find.text("Silver "), findsOneWidget);
    expect(find.text("American Society of\n Naval Engineers"), findsOneWidget);
    expect(find.text("Private Sponsor"), findsOneWidget);
    expect(
      find.text(
        "Society of Naval Architects and Marine Engineers\nStevens Chapter",
      ),
      findsOneWidget,
    );
    expect(find.text("DHX Machines"), findsOneWidget);

    await widgetTester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await widgetTester.pumpAndSettle();
    expect(find.byType(ClockText), findsOneWidget);
    expect(find.byType(ROSConnectionStateWidget), findsOneWidget);
  });
  group("Closing Page", () {
    testWidgets('Test Closing Keybind', (widgetTester) async {
      await pumpPage(
        widgetTester,
        createFakeROS(initialState: ROSConnectionState.connected),
      );
      await widgetTester.sendKeyEvent(LogicalKeyboardKey.escape);
      await widgetTester.pumpAndSettle();
      expect(find.byType(StandbyModePage), findsNothing);
    });
    testWidgets('Test Close Button', (widgetTester) async {
      await pumpPage(
        widgetTester,
        createFakeROS(initialState: ROSConnectionState.connected),
      );
      var closeButton = find.byIcon(Icons.arrow_back_rounded);
      expect(closeButton, findsOneWidget);
      await widgetTester.tap(closeButton);
      await widgetTester.pumpAndSettle();
      expect(find.byType(StandbyModePage), findsNothing);
    });
  });
}
