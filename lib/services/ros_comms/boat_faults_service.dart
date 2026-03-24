import 'package:flutter/cupertino.dart';
import 'package:waterboard/schemas/fault_msg_schema.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class BoatFaultsService extends ChangeNotifier {
  final ROS ros;
  late final ROSSubscription faultSub;
  final List<FaultMsgSchema> _faults = [];

  List<FaultMsgSchema> get faults => _faults;

  BoatFaultsService({required this.ros}) {
    faultSub = ros.subscribe("/alarm/shore/publish");
    faultSub.notifier.addListener(() => refresh());
  }

  void refresh() {
    ros.createService("/alarm/query").call((success, json) {
        if (!success) return;
      List<dynamic> alarms = json["alarms"];
      faults.clear();
      for (var alarm in alarms) {
        var a = FaultMsgSchema.fromJson(alarm);
        faults.add(a);
      }
      notifyListeners();
    });
  }
}
