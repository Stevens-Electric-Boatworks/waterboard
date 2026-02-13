// Flutter imports:
import 'package:flutter/cupertino.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/ros_comms/rosbridge.dart';
import '../log.dart';

// Package imports:

abstract class ROS {
  ValueNotifier<ROSConnectionState> get connectionState;

  Map<String, ROSSubscription> get subs;
  ROSSubscription subscribe(String topic);
  void startConnectionLoop();
  void reconnect();
  void propagateData(String topic, Map<String, dynamic> data);
}

class ROSImpl extends ROS {
  late ROSBridge _rosBridge;
  final Map<String, ROSSubscription> _subs = {};
  ROSImpl() {
    _rosBridge = ROSBridge(this);
  }

  @override
  ValueNotifier<ROSConnectionState> get connectionState =>
      _rosBridge.connectionState;

  @override
  Map<String, ROSSubscription> get subs => _subs;

  @override
  void startConnectionLoop() {
    _rosBridge.startConnectionLoop();
  }

  @override
  void reconnect() {
    Log.instance.info("[ROS] Reconnecting...");
    _rosBridge.reconnect();
  }

  /// Subscribe to a topic
  @override
  ROSSubscription subscribe(String topic) {
    if (_subs.containsKey(topic)) {
      return _subs[topic]!;
    }
    Log.instance.info("Subscribing to $topic");
    var sub = ROSSubscriptionImpl(topic, _rosBridge);
    _rosBridge.sendSubscription(sub);
    _subs[topic] = sub;
    return sub;
  }

  /// This method should be called whenever you want to propagate data to subscriptions
  @override
  void propagateData(String topic, Map<String, dynamic> data) {
    if (data.isEmpty) return;
    _subs[topic]?.onData(data);
  }
}

enum ROSConnectionState { noWebsocket, staleData, connected }
