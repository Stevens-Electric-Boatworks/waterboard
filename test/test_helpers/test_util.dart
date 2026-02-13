import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

import 'fakes/fake_ros.dart';
import 'test_util.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ROSImpl>(),
  MockSpec<ROSSubscriptionImpl>()
])
MockROSImpl createMockOfflineROS({ROSConnectionState initialState = ROSConnectionState.noWebsocket}) {
  final mockROS = MockROSImpl();
  when(mockROS.connectionState).thenReturn(ValueNotifier(initialState));
  Map<String, ROSSubscriptionImpl> virtualSubs = {};
  when(mockROS.subs).thenReturn(virtualSubs);
  when(mockROS.subscribe(any)).thenAnswer((realInvocation) {
    final topic = realInvocation.positionalArguments.first as String;

    final mockSub = MockROSSubscriptionImpl();
    when(mockSub.topic).thenReturn(topic);
    when(mockSub.isStale).thenReturn(true);
    when(mockSub.notifier).thenReturn(ValueNotifier({}));
    virtualSubs[topic] = mockSub;
    return mockSub;
  },);
  return mockROS;
}

FakeROS createFakeROS({ROSConnectionState initialState = ROSConnectionState.noWebsocket}) {
  final fakeROS = FakeROS(initialState: initialState);
  return fakeROS;
}


void ignoreOverflowErrors(
    FlutterErrorDetails details, {
      bool forceReport = false,
    }) {
  // ---

  bool ifIsOverflowError = false;
  bool isUnableToLoadAsset = false;

  // Detect overflow error.
  var exception = details.exception;
  if (exception is FlutterError) {
    ifIsOverflowError = !exception.diagnostics.any(
          (e) => e.value.toString().startsWith('A RenderFlex overflowed by'),
    );
    isUnableToLoadAsset = !exception.diagnostics.any(
          (e) => e.value.toString().startsWith('Unable to load asset'),
    );
  }

  // Ignore if is overflow error.
  if (ifIsOverflowError || isUnableToLoadAsset) {
    return;
  } else {
    FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
    // exit(1);
  }
}