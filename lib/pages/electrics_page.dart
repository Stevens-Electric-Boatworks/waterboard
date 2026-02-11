// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';
// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';

import '../waterboard_colors.dart';
import '../widgets/ros_widgets/gauge.dart';

class ElectricsPageViewModel extends ChangeNotifier {
  final ROS ros;

  late ValueNotifier<Map<String, dynamic>> motorSub;
  late ValueNotifier<Map<String, dynamic>> inletTempSub;
  late ValueNotifier<Map<String, dynamic>> outletTempSub;

  ElectricsPageViewModel({required this.ros});

  void init() {
    motorSub = ros.subscribe("/motors/can_motor_data").value;
    inletTempSub = ros.subscribe("/electrical/temp_sensors/in").value;
    outletTempSub = ros.subscribe("/electrical/temp_sensors/out").value;
  }
}

class ElectricsPage extends StatefulWidget {
  final ElectricsPageViewModel model;

  const ElectricsPage({super.key, required this.model});

  @override
  State<ElectricsPage> createState() => _ElectricsPageState();
}

class _ElectricsPageState extends State<ElectricsPage> {
  @override
  void initState() {
    super.initState();
    model.init();
    model.addListener(() => setState(() {}));
  }

  ElectricsPageViewModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // ROW 1: Motor metrics
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: WaterboardColors.containerBackground,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Motor Current
                ROSGauge(
                  notifier: model.motorSub,
                  valueBuilder: (json) => (json["current"] as int).toDouble(),
                  minimum: 0,
                  maximum: 200,
                  unitText: "A",
                  title: "Motor Current",
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: 80,
                      color: Colors.green,
                    ),
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
                      color: const Color.fromRGBO(255, 0, 0, 1),
                    ),
                  ],
                ),

                // Motor Voltage
                ROSGauge(
                  notifier: model.motorSub,
                  valueBuilder: (json) => (json["voltage"] as int).toDouble(),
                  minimum: 0,
                  maximum: 90,
                  unitText: "V",
                  title: "Motor Voltage",
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: 30,
                      color: Colors.green,
                    ),
                    GaugeRange(
                      startValue: 50,
                      endValue: 70,
                      color: Colors.yellow.shade600,
                    ),
                    GaugeRange(
                      startValue: 70,
                      endValue: 90,
                      color: const Color.fromRGBO(255, 0, 0, 1),
                    ),
                  ],
                ),

                // Motor Power
                ROSGauge(
                  notifier: model.motorSub,
                  valueBuilder: (json) => (json["power"] as num).toDouble(),
                  minimum: 0,
                  maximum: 1200,
                  unitText: "W",
                  title: "Motor Power",
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: 500,
                      color: Colors.green,
                    ),
                    GaugeRange(
                      startValue: 500,
                      endValue: 1000,
                      color: Colors.yellow.shade600,
                    ),
                    GaugeRange(
                      startValue: 1000,
                      endValue: 1200,
                      color: const Color.fromRGBO(255, 0, 0, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ROW 2: Temp metrics
          Container(
            decoration: BoxDecoration(
              color: WaterboardColors.containerBackground,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Inlet Temp
                ROSGauge(
                  notifier: model.inletTempSub,
                  valueBuilder: (json) =>
                      (json["inlet_temp"] as double).round().toDouble(),
                  minimum: 0,
                  maximum: 100,
                  unitText: "°C",
                  title: "Inlet Temp",
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: 50,
                      color: Colors.green,
                    ),
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
                      color: const Color.fromRGBO(255, 0, 0, 1),
                    ),
                  ],
                ),

                // Outlet Temp
                ROSGauge(
                  notifier: model.outletTempSub,
                  valueBuilder: (json) =>
                      (json["outlet_temp"] as double).round().toDouble(),
                  minimum: 0,
                  maximum: 100,
                  unitText: "°C",
                  title: "Outlet Temp",
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: 50,
                      color: Colors.green,
                    ),
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
                      color: const Color.fromRGBO(255, 0, 0, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
