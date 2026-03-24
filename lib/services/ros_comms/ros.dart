// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:clock/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/ros_comms/rosbridge.dart';
import 'package:waterboard/services/ros_comms/service.dart';
import '../log.dart';

// Package imports:

abstract class ROS {
  ValueNotifier<ROSConnectionState> get connectionState;
  ROSLogsCollector get rosLogs;
  Map<String, ROSSubscription> get subs;

  DateTime get timeSinceLastMsg;
  ValueNotifier<ROSSubscription?> get onSubscription;
  ROSSubscription subscribe(String topic, {int staleDuration = 1000});
  ROSService createService(String topic);
  void startConnectionLoop();
  void reconnect();
  void propagateData(String topic, Map<String, dynamic> data);
}

class ROSImpl extends ROS {
  final Log _log;
  final SharedPreferences _preferences;
  late ROSBridge _rosBridge;
  final Map<String, ROSSubscription> _subs = {};
  final ValueNotifier<ROSSubscription?> _onSubscription = ValueNotifier(null);
  @override
  late final ROSLogsCollector rosLogs;
  ROSImpl(this._log, this._preferences) {
    _rosBridge = ROSBridge(this, _log, _preferences);
    rosLogs = ROSLogsCollector(subscription: subscribe("/rosout"));
    rosLogs.init();
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
    _log.info("[ROS] Reconnecting...");
    _rosBridge.reconnect();
  }

  /// Subscribe to a topic
  @override
  ROSSubscription subscribe(String topic, {int staleDuration = 1000}) {
    if (_subs.containsKey(topic)) {
      return _subs[topic]!;
    }
    _log.info("[ROS] Creating new subscription to '$topic'");
    var sub = ROSSubscriptionImpl(
      topic,
      _rosBridge,
      clock,
      staleDuration: staleDuration,
    );
    _rosBridge.sendSubscription(sub);
    _subs[topic] = sub;
    _onSubscription.value = sub;
    return sub;
  }

  /// This method should be called whenever you want to propagate data to subscriptions
  @override
  void propagateData(String topic, Map<String, dynamic> data) {
    if (data.isEmpty) return;
    _subs[topic]?.onData(data);
  }

  @override
  DateTime get timeSinceLastMsg => _rosBridge.timeSinceLastMsg;

  @override
  ValueNotifier<ROSSubscription?> get onSubscription => _onSubscription;

  @override
  ROSService createService(String topic) {
    return ROSService(topic: topic, rosBridge: _rosBridge);
  }
}

enum ROSConnectionState { noWebsocket, staleData, connected }
