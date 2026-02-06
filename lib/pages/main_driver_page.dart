// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:waterboard/pages/page_utils.dart';

// Project imports:
import '../services/ros_comms/ros.dart';
import '../widgets/ros_widgets/gauge.dart';

class MainDriverPage extends StatefulWidget {
  final ROS ros;
  const MainDriverPage({super.key, required this.ros});

  @override
  State<MainDriverPage> createState() => _MainDriverPageState();
}

class _MainDriverPageState extends State<MainDriverPage> {
  DialogRoute? _connectionAlertDialog;
  @override
  void initState() {
    super.initState();
    widget.ros.connectionState.addListener(() {
      if (widget.ros.connectionState.value == ROSConnectionState.noWebsocket) {
        showWebsocketDisconnectedDialog();
      } else if (widget.ros.connectionState.value ==
          ROSConnectionState.staleData) {
        showROSBridgeDisconnectedDialog();
      } else if (widget.ros.connectionState.value ==
          ROSConnectionState.connected) {
        //weird race condition fix
        Timer(Duration(milliseconds: 200), () {
          if (widget.ros.connectionState.value == ROSConnectionState.connected) {
            closeConnectionDialog();
          }
        });
      }
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return;
    //   final state = widget.ros.connectionState.value;
    //   if (state == ConnectionState.noWebsocket) {
    //     showWebsocketDisconnectedDialog();
    //   } else if (state == ConnectionState.noROSBridge) {
    //     showROSBridgeDisconnectedDialog();
    //   }
    // });
  }

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
                notifier: widget.ros.subscribe("/motors/can_motor_data").value,
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
                notifier: widget.ros.subscribe("/electrical/temp_sensors/in").value,
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
                notifier: widget.ros.subscribe(
                  "/electrical/temp_sensors/out",
                ).value,
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
                notifier: widget.ros.subscribe("/motors/can_motor_data").value,
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
                notifier: widget.ros.subscribe("/motion/vtg").value,
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
                notifier: widget.ros.subscribe("/motors/can_motor_data").value,
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

  void showWebsocketDisconnectedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      closeConnectionDialog();
      if (!isOnMainPage) return;
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(child: Text("ROSBridge Websocket Disconnected")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              "The websocket was unable to be initialized to connect to ROSBridge, but nothing is known of the state of ROSBridge directly.\nIt is recommended to reboot the Raspberry Pi.",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  PageUtils.showSettingsDialog(context, widget.ros);
                },
                child: Text("Open Settings"),
              ),
              TextButton(
                onPressed: () {
                  closeConnectionDialog();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                child: Text("Close Dialog", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),),
              )
            ],
          );
        },
      );
      Navigator.of(context).push(_connectionAlertDialog!);
    });
  }

  void showROSBridgeDisconnectedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      closeConnectionDialog();
      if (!isOnMainPage) return;
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(child: Text("ROSBridge Data Stale")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              "The websocket is initialized, but there is stale data from ROSBridge. \nThis means that the ROS Control System is likely down.",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  PageUtils.showSettingsDialog(context, widget.ros);
                },
                child: Text("Open Settings"),
              ),
              TextButton(
                onPressed: () {
                  closeConnectionDialog();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                child: Text("Close Dialog", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),),
              )
            ],
          );
        },
      );
      Navigator.of(context).push(_connectionAlertDialog!);
    });
  }

  void closeConnectionDialog() {
    if (_connectionAlertDialog != null) {
      Navigator.of(context).removeRoute(_connectionAlertDialog!);
      _connectionAlertDialog = null;
    }
  }
}
