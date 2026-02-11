// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;

// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';

// Project imports:
import '../services/ros_comms/ros.dart';
import '../widgets/ros_widgets/gauge.dart';

class MainDriverPageViewModel extends ChangeNotifier {
  final ROS ros;
  late ValueNotifier<Map<String, dynamic>> motorSub;
  late ValueNotifier<Map<String, dynamic>> inletTempSub;
  late ValueNotifier<Map<String, dynamic>> outletTempSub;
  late ValueNotifier<Map<String, dynamic>> speedSub;

  MainDriverPageViewModel({required this.ros});

  void init() {
    motorSub = ros.subscribe("/motors/can_motor_data").value;
    inletTempSub = ros.subscribe("/electrical/temp_sensors/in").value;
    outletTempSub = ros.subscribe("/electrical/temp_sensors/out").value;
    speedSub = ros.subscribe("/motion/vtg").value;
  }
}

class MainDriverPage extends StatefulWidget {
  final MainDriverPageViewModel model;

  const MainDriverPage({super.key, required this.model});

  @override
  State<MainDriverPage> createState() => _MainDriverPageState();
}

class _MainDriverPageState extends State<MainDriverPage> {
  @override
  void initState() {
    super.initState();
    model.init();
    model.addListener(() => setState(() {}));
  }

  MainDriverPageViewModel get model => widget.model;

  bool get isOnMainPage {
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          //ROW 1
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Motor Current
              ROSGauge(
                notifier: model.motorSub,
                valueBuilder: (json) {
                  return (json["current"] as int).toDouble();
                },
                minimum: 0,
                maximum: 200,
                unitText: "A",
                title: "Motor Current",
                ranges: [
                  GaugeRange(startValue: 0, endValue: 80, color: Colors.green),
                  GaugeRange(
                    startValue: 80,
                    endValue: 120,
                    color: Colors.yellow.shade600,
                  ),
                  GaugeRange(
                    startValue: 120,
                    endValue: 150,
                    color: Colors.red.shade400,
                  ),
                  GaugeRange(
                    startValue: 150,
                    endValue: 200,
                    color: Color.fromRGBO(255, 0, 0, 1.0),
                  ),
                ],
              ),
              //inlet temp
              ROSGauge(
                notifier: model.inletTempSub,
                valueBuilder: (json) {
                  return (json["inlet_temp"] as double).round().toDouble();
                },
                minimum: 0,
                maximum: 100,
                unitText: "°C",
                title: "Inlet Temp",
                ranges: [
                  GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                  GaugeRange(
                    startValue: 50,
                    endValue: 70,
                    color: Colors.yellow.shade600,
                  ),
                  GaugeRange(
                    startValue: 70,
                    endValue: 90,
                    color: Colors.red.shade500,
                  ),
                  GaugeRange(
                    startValue: 90,
                    endValue: 100,
                    color: Color.fromRGBO(255, 0, 0, 1.0),
                  ),
                ],
              ),
              //outlet temp
              ROSGauge(
                notifier: model.outletTempSub,
                valueBuilder: (json) {
                  return (json["outlet_temp"] as double).round().toDouble();
                },
                minimum: 0,
                maximum: 100,
                unitText: "°C",
                title: "Outlet Temp",
                ranges: [
                  GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                  GaugeRange(
                    startValue: 50,
                    endValue: 70,
                    color: Colors.yellow.shade600,
                  ),
                  GaugeRange(
                    startValue: 70,
                    endValue: 90,
                    color: Colors.red.shade500,
                  ),
                  GaugeRange(
                    startValue: 90,
                    endValue: 100,
                    color: Color.fromRGBO(255, 0, 0, 1.0),
                  ),
                ],
              ),
              //Outlet Temp Current
            ],
          ),
          //ROW 2
          // ROW 2
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Motor Temp
              ROSGauge(
                notifier: model.motorSub,
                valueBuilder: (json) {
                  return (json["motor_temp"] as int).toDouble();
                },
                minimum: 0,
                maximum: 60,
                unitText: "°C",
                title: "Motor Temp",
                ranges: [
                  GaugeRange(
                    startValue: 0,
                    endValue: 10,
                    color: Colors.lightBlueAccent,
                  ),
                  GaugeRange(startValue: 10, endValue: 40, color: Colors.green),
                  GaugeRange(
                    startValue: 40,
                    endValue: 50,
                    color: Colors.yellow.shade600,
                  ),
                  GaugeRange(
                    startValue: 50,
                    endValue: 60,
                    color: const Color.fromRGBO(255, 0, 0, 1.0),
                  ),
                ],
              ),

              // Boat Speed
              ROSGauge(
                notifier: model.speedSub,
                valueBuilder: (json) {
                  return (json["speed"] as double).round().toDouble().abs();
                },
                minimum: 0,
                maximum: 50,
                unitText: "kts",
                title: "Speed",
                ranges: [
                  GaugeRange(startValue: 0, endValue: 25, color: Colors.green),
                  GaugeRange(
                    startValue: 25,
                    endValue: 35,
                    color: Colors.yellow.shade600,
                  ),
                  GaugeRange(
                    startValue: 35,
                    endValue: 50,
                    color: const Color.fromRGBO(255, 0, 0, 1.0),
                  ),
                ],
              ),

              // Motor RPM
              ROSGauge(
                notifier: model.motorSub,
                valueBuilder: (json) {
                  return (json["rpm"] as int).toDouble().abs();
                },
                minimum: 0,
                maximum: 2500,
                unitText: "RPM",
                title: "Motor RPM",
                ranges: [
                  GaugeRange(
                    startValue: 0,
                    endValue: 1500,
                    color: Colors.green,
                  ),
                  GaugeRange(
                    startValue: 1500,
                    endValue: 2100,
                    color: Colors.yellow.shade600,
                  ),
                  GaugeRange(
                    startValue: 2100,
                    endValue: 2500,
                    color: const Color.fromRGBO(255, 0, 0, 1.0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
