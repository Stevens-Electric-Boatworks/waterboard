import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterboard/messages.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_connection_state_widget.dart';

import '../test_helpers/test_util.dart';

void main() {
  FlutterError.onError = ignoreOverflowErrors;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Connected', (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        home: ROSConnectionStateWidget(value: ROSConnectionState.connected, fontSize: 12, iconSize: 8),
      )
    );
    expect(find.text(ROSConnectionStateMessages.rosConnected), findsOneWidget);
  });
  testWidgets('Stale Data', (widgetTester) async {
    await widgetTester.pumpWidget(
        MaterialApp(
          home: ROSConnectionStateWidget(value: ROSConnectionState.staleData, fontSize: 12, iconSize: 8),
        )
    );
    expect(find.text(ROSConnectionStateMessages.staleData), findsOneWidget);
  });
  testWidgets('No Websocket', (widgetTester) async {
    await widgetTester.pumpWidget(
        MaterialApp(
          home: ROSConnectionStateWidget(value: ROSConnectionState.noWebsocket, fontSize: 12, iconSize: 8),
        )
    );
    expect(find.text(ROSConnectionStateMessages.noWebsocket), findsOneWidget);
  });
}
