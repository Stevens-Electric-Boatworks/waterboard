// Flutter imports:
import 'package:flutter/cupertino.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/ros_comms/rosbridge.dart';
import '../log.dart';

// Package imports:


class ROS {
  late ROSBridge _rosBridge;
  final Map<String, ROSSubscription> _subs = {};
  ROS() {
    _rosBridge = ROSBridge(this);
  }

  ValueNotifier<ROSConnectionState> get connectionState =>
      _rosBridge.connectionState;

  Map<String, ROSSubscription> get subs => _subs;

  void startConnectionLoop() {
    _rosBridge.startConnectionLoop();
  }

  void reconnect() {
    Log.instance.info("[ROS] Reconnecting...");
    _rosBridge.reconnect();
  }

  /// Subscribe to a topic
  ROSSubscription subscribe(String topic) {
    if (_subs.containsKey(topic)) {
      return _subs[topic]!;
    }
    Log.instance.info("Subscribing to $topic");
    var sub = ROSSubscription(topic, _rosBridge);
    _rosBridge.sendSubscription(sub);
    _subs[topic] = sub;
    return sub;
  }

  /// This method should be called whenever you want to propagate data to subscriptions
  void propagateData(String topic, Map<String, dynamic> data) {
    if (data.isEmpty) return;
    _subs[topic]?.onData(data);
  }
}

enum ROSConnectionState { unknown, noWebsocket, staleData, connected }
