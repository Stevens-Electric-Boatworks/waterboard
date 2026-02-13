// Flutter imports:
import 'package:flutter/src/foundation/change_notifier.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class FakeROSSubscription extends ROSSubscription {
  @override
  final String topic;
  @override
  late final ValueNotifier<Map<String, dynamic>> notifier;

  FakeROSSubscription({
    required this.topic,
    required Map<String, dynamic> initialData,
  }) {
    notifier = ValueNotifier(initialData);
  }

  @override
  bool isStale = false;

  @override
  void onData(Map<String, dynamic> data) {
    notifier.value = data;
  }
}
