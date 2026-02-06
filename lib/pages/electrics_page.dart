// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';
// Project imports:
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/services/ros_comms/ros.dart';

import '../widgets/ros_widgets/gauge.dart';

class ElectricsPage extends StatefulWidget {
  final ROS ros;
  const ElectricsPage({super.key, required this.ros});

  @override
  State<ElectricsPage> createState() => _ElectricsPageState();
}

class _ElectricsPageState extends State<ElectricsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // ROW 1
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Motor Current
                ROSGauge(
                  notifier: widget.ros.subscribe("/motors/can_motor_data").value,
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
                  notifier: widget.ros.subscribe("/motors/can_motor_data").value,
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
                  notifier: widget.ros.subscribe("/motors/can_motor_data").value,
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

          // ROW 2
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Inlet Temp
                ROSGauge(
                  notifier: widget.ros.subscribe(
                    "/electrical/temp_sensors/in",
                  ).value,
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
                  notifier: widget.ros.subscribe(
                    "/electrical/temp_sensors/out",
                  ).value,
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
