// Flutter imports:
import 'package:flutter/src/foundation/change_notifier.dart' show ValueNotifier;

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'fake_ros_sub.dart';

class FakeROS extends ROS {
  @override
  late ValueNotifier<ROSConnectionState> connectionState;
  @override
  Map<String, FakeROSSubscription> subs = {};
  FakeROS({ROSConnectionState initialState = ROSConnectionState.noWebsocket}) {
    connectionState = ValueNotifier(initialState);
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
  ROSSubscription subscribe(
    String topic, {
    Map<String, dynamic> initialData = const {},
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
}
