import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:waterboard/services/ros_comms.dart';

import '../widgets/gauge.dart';
import '../widgets/ros_listenable_widget.dart';

class ElectricsPage extends StatefulWidget {
  final ROSComms comms;
  const ElectricsPage({super.key, required this.comms});

  @override
  State<ElectricsPage> createState() => _ElectricsPageState();
}

class _ElectricsPageState extends State<ElectricsPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          //ROW 1
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(32),
              border: BoxBorder.all(
                color: Colors.black
              )
            ),
            margin: EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Motor Current
                ROSListenable(
                  valueNotifier: widget.comms.subscribe(
                    "/motors/can_motor_data",
                  ),
                  builder: (context, value) {
                    var current = (value["current"] as int).toDouble();
                    return Gauge(
                      value: current,
                      minimum: 0,
                      maximum: 200,
                      annotationText: "$current",
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
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
                //Motor Voltage
                ROSListenable(
                  valueNotifier: widget.comms.subscribe(
                    "/motors/can_motor_data",
                  ),
                  builder: (context, value) {
                    var data = (value["voltage"] as int).toDouble();
                    return Gauge(
                      value: data,
                      minimum: 0,
                      maximum: 90,
                      annotationText: "$data",
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
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
                //Motor Power
                ROSListenable(
                  valueNotifier: widget.comms.subscribe("/motors/can_motor_data"),
                  builder: (context, value) {
                    var power = value["power"]
                        .toDouble();
                    return Gauge(
                      value: power,
                      minimum: 0,
                      maximum: 1200,
                      annotationText: "$power",
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
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          //ROW 2
          Container(
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(32),
                border: BoxBorder.all(
                    color: Colors.black
                )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                //Inlet Temp
                ROSListenable(
                  valueNotifier: widget.comms.subscribe(
                    "/electrical/temp_sensors/in",
                  ),
                  builder: (context, value) {
                    var current = (value["inlet_temp"] as double)
                        .round()
                        .toDouble();
                    return Gauge(
                      value: current,
                      minimum: 0,
                      maximum: 100,
                      annotationText: "$current",
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
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
                //Outlet Temp
                ROSListenable(
                  valueNotifier: widget.comms.subscribe(
                    "/electrical/temp_sensors/out",
                  ),
                  builder: (context, value) {
                    var data = (value["outlet_temp"] as double)
                        .round()
                        .toDouble();
                    return Gauge(
                      value: data,
                      minimum: 0,
                      maximum: 100,
                      annotationText: "$data",
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
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
