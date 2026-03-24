import 'package:waterboard/services/ros_comms/rosbridge.dart';

class ROSService {
  final ROSBridge _rosBridge;
  final String topic;

  ROSService({required this.topic, required ROSBridge rosBridge}) : _rosBridge = rosBridge;
  void call(Function(bool success, Map<String, dynamic> json) onResponse) {
    _rosBridge.callService(topic, onResponse);
  }
}