// Flutter imports:

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Project imports:
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';
import '../pages/radios_page.mocks.dart';
import 'fakes/fake_internet_checker.dart';
import 'fakes/fake_ros.dart';
import 'test_util.mocks.dart';

Services createServicesRegistry(ROS ros, Log logger, InternetChecker checker) {
  Services service = Services();
  service.initializeWithMocks(ros: ros, logger: logger, internet: checker);
  return service;
}

@GenerateNiceMocks([MockSpec<ROSImpl>(), MockSpec<ROSSubscriptionImpl>()])
MockROSImpl createMockOfflineROS({
  ROSConnectionState initialState = ROSConnectionState.noWebsocket,
}) {
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
  });
  return mockROS;
}

FakeROS createFakeROS({
  ROSConnectionState initialState = ROSConnectionState.noWebsocket,
}) {
  final fakeROS = FakeROS(initialState: initialState);
  return fakeROS;
}

@GenerateNiceMocks([MockSpec<Log>()])
Log createMockLogger() {
  MockLog mock = MockLog();
  when(mock.onMessage).thenReturn(ValueNotifier(null));
  return mock;
}

MockInternetChecker createOfflineMockInternetChecker() {
  MockInternetChecker checker = MockInternetChecker();
  when(checker.ssid).thenAnswer((realInvocation) => ValueNotifier(null));
  when(checker.ipAddress).thenAnswer((realInvocation) => ValueNotifier(null));
  when(
    checker.internetStatus,
  ).thenAnswer((realInvocation) => Stream.value(InternetStatus.disconnected));
  return checker;
}

MockInternetChecker createOnlineMockInternetChecker(String ssid, String ip) {
  MockInternetChecker checker = MockInternetChecker();
  when(checker.ssid).thenAnswer((realInvocation) => ValueNotifier(ssid));
  when(checker.ipAddress).thenAnswer((realInvocation) => ValueNotifier(ip));
  when(
    checker.internetStatus,
  ).thenAnswer((realInvocation) => Stream.value(InternetStatus.connected));
  return checker;
}

FakeInternetChecker createFakeInternetChecker() {
  return FakeInternetChecker();
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
