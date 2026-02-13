// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/rosbridge.dart';

abstract class ROSSubscription {
  ValueNotifier<Map<String, dynamic>> get notifier;
  String get topic;
  bool get isStale;
  void onData(Map<String, dynamic> data);
}

class ROSSubscriptionImpl extends ROSSubscription {
  final String _topic;
  final ROSBridge _rosBridge;
  final ValueNotifier<Map<String, dynamic>> _valueNotifier = ValueNotifier({});
  int _timeOfLastMessage = 0;

  ROSSubscriptionImpl(this._topic, this._rosBridge) {
    _valueNotifier.addListener(() {
      _timeOfLastMessage = DateTime.now().millisecondsSinceEpoch;
    });
    Timer(Duration(seconds: 1), () {
      if (isStale) {
        _rosBridge.sendSubscription(this);
      }
    });
  }

  @override
  ValueNotifier<Map<String, dynamic>> get notifier => _valueNotifier;

  @override
  String get topic => _topic;

  @override
  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - _timeOfLastMessage > 1000;

  @override
  void onData(Map<String, dynamic> data) {
    _valueNotifier.value = data;
  }
}
