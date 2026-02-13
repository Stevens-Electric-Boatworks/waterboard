import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class FakeROSSubscription extends ROSSubscription {
  @override
  final String topic;
  @override
  ValueNotifier<Map<String, dynamic>> notifier = ValueNotifier({});

  FakeROSSubscription({required this.topic});

  @override
  bool get isStale => false;

  @override
  void onData(Map<String, dynamic> data) {
    notifier.value = data;
  }
}