// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/rosbridge.dart';

class ROSSubscription {
  final String _topic;
  final ROSBridge _rosBridge;
  final ValueNotifier<Map<String, dynamic>> _valueNotifier = ValueNotifier({});
  int _timeOfLastMessage = 0;

  ROSSubscription(this._topic, this._rosBridge) {
    _valueNotifier.addListener(() {
      _timeOfLastMessage = DateTime.now().millisecondsSinceEpoch;
    });
    Timer(Duration(seconds: 1), () {
      if (isStale) {
        _rosBridge.sendSubscription(this);
      }
    });
  }

  ValueNotifier<Map<String, dynamic>> get value => _valueNotifier;

  String get topic => _topic;

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - _timeOfLastMessage > 1000;

  void onData(Map<String, dynamic> data) {
    _valueNotifier.value = data;
  }
}
