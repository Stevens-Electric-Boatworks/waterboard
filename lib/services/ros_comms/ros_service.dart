// Project imports:
import 'package:waterboard/services/ros_comms/rosbridge.dart';

class ROSService {
  final ROSBridge _rosBridge;
  final String topic;
  final int timeout;
  final Function(bool success, Map<String, dynamic> json) onResponse;

  ROSService({
    required this.topic,
    required ROSBridge rosBridge,
    required this.onResponse,
    required this.timeout,
  }) : _rosBridge = rosBridge;
  void call() {
    _rosBridge.callService(topic, onResponse, timeout: timeout);
  }
}
