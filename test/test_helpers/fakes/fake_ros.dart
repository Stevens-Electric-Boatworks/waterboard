// Flutter imports:
import 'package:flutter/src/foundation/change_notifier.dart' show ValueNotifier;

// Package imports:
import 'package:clock/clock.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'fake_ros_sub.dart';

class FakeROS extends ROS {
  @override
  late final ValueNotifier<ROSConnectionState> connectionState;
  @override
  Map<String, FakeROSSubscription> subs = {};
  @override
  late final ROSLogsCollector rosLogs;

  FakeROS({ROSConnectionState initialState = ROSConnectionState.noWebsocket}) {
    connectionState = ValueNotifier(initialState);
    rosLogs = ROSLogsCollector(subscription: subscribe("/rosout"));
  }

  @override
  void reconnect() {
    //do nothing
  }

  @override
  void startConnectionLoop() {
    //do nothing
  }

  @override
  FakeROSSubscription subscribe(
    String topic, {
    Map<String, dynamic> initialData = const {},
    int staleDuration = 1000,
  }) {
    if (subs.containsKey(topic)) return subs[topic]!;
    var sub = FakeROSSubscription(topic: topic, initialData: initialData);
    subs[topic] = sub;
    return sub;
  }

  @override
  void propagateData(String topic, Map<String, dynamic> data) {
    if (subs.containsKey(topic)) {
      subs[topic]?.onData(data);
    }
  }

  @override
  ValueNotifier<ROSSubscription?> onSubscription = ValueNotifier(null);

  @override
  DateTime get timeSinceLastMsg => clock.now();
}
