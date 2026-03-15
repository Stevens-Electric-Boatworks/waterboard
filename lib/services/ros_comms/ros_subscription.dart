// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:clock/clock.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/rosbridge.dart';

abstract class ROSSubscription {
  ValueNotifier<Map<String, dynamic>> get notifier;
  String get topic;
  ValueNotifier<bool> get isStale;
  void onData(Map<String, dynamic> data);
}

class ROSSubscriptionImpl extends ROSSubscription {
  final String _topic;
  final ROSBridge _rosBridge;
  final Clock clock;
  final ValueNotifier<Map<String, dynamic>> _valueNotifier = ValueNotifier({});
  int _timeOfLastMessage = 0;

  final int staleDuration;
  final ValueNotifier<bool> _isStale = ValueNotifier(true);

  ROSSubscriptionImpl(
    this._topic,
    this._rosBridge,
    this.clock, {
    this.staleDuration = 1000,
  }) {
    _valueNotifier.addListener(() {
      _timeOfLastMessage = DateTime.now().millisecondsSinceEpoch;
      _isStale.value = false;
    });
    Timer.periodic(Duration(seconds: 1), (var timer) {
      updateStale();
      if (isStale.value) {
        _rosBridge.sendSubscription(this);
      }
    });
  }

  void updateStale() {
    _isStale.value =
        clock.now().millisecondsSinceEpoch - _timeOfLastMessage > staleDuration;
  }

  @override
  ValueNotifier<Map<String, dynamic>> get notifier => _valueNotifier;

  @override
  String get topic => _topic;

  @override
  ValueNotifier<bool> get isStale => _isStale;

  @override
  void onData(Map<String, dynamic> data) {
    _valueNotifier.value = data;
  }
}
