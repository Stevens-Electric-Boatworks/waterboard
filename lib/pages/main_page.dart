import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/settings/settings_dialog.dart';
import 'package:waterboard/widgets/gauge.dart';
import 'package:waterboard/widgets/ros_listenable_widget.dart';
import 'package:waterboard/widgets/time_text.dart';

class MainPage extends StatefulWidget {
  final ROSComms comms;

  const MainPage({super.key, required this.comms});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Widget? dialogWidget;
  DialogRoute? _connectionAlertDialog;

  @override
  void initState() {
    super.initState();
    widget.comms.connectionState.addListener(() {
      print("Listener State: ${widget.comms.connectionState.value}");
      if (widget.comms.connectionState.value == ConnectionState.noWebsocket) {
        print("Showing websocket dialog!");
        showWebsocketDisconnectedDialog();
      } else if (widget.comms.connectionState.value ==
          ConnectionState.noROSBridge) {
        print("Showing rosbridge dialog!");
        showROSBridgeDisconnectedDialog();
      } else if (widget.comms.connectionState.value ==
          ConnectionState.connected) {
        print("Closing everything!");
        //weird race condition fix
        Timer(Duration(milliseconds: 200), () {
          if (widget.comms.connectionState.value == ConnectionState.connected) {
            closeConnectionDialog();
          }
        });
      }
    });

    widget.comms.startConnectionRoutine();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = widget.comms.connectionState.value;

      if (state == ConnectionState.noWebsocket) {
        showWebsocketDisconnectedDialog();
      } else if (state == ConnectionState.noROSBridge) {
        showROSBridgeDisconnectedDialog();
      }
    });
  }
  bool get isOnMainPage {
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Stevens Electric Boatworks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Container(
          decoration: BoxDecoration(border: BoxBorder.all(color: Colors.black)),
          margin: EdgeInsets.all(4),
          child: Center(
            child: ClockText(style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => showSettingsDialog(),
            icon: Icon(Icons.settings),
          ),
        ],
        leadingWidth: 100,
        toolbarHeight: 40,
      ),
      body: Center(
        child: Column(
          children: [
            //ROW 1
            Row(
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
                //Inlet Temp Current
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
                //Outlet Temp Current
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
            //ROW 2
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Motor Temp
                ROSListenable(
                  valueNotifier: widget.comms.subscribe(
                    "/motors/can_motor_data",
                  ),
                  builder: (context, value) {
                    var data = (value["motor_temp"] as int).toDouble();
                    return Gauge(
                      value: data,
                      minimum: 0,
                      maximum: 60,
                      annotationText: "$data",
                      unitText: "°C",
                      title: "Motor Temp",
                      ranges: [
                        GaugeRange(
                          startValue: 0,
                          endValue: 10,
                          color: Colors.lightBlueAccent,
                        ),
                        GaugeRange(
                          startValue: 10,
                          endValue: 40,
                          color: Colors.green,
                        ),
                        GaugeRange(
                          startValue: 40,
                          endValue: 50,
                          color: Colors.yellow.shade600,
                        ),
                        GaugeRange(
                          startValue: 50,
                          endValue: 60,
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
                //Boat Speed
                ROSListenable(
                  valueNotifier: widget.comms.subscribe("/motion/vtg"),
                  builder: (context, value) {
                    var speed = (value["speed"] as double)
                        .round()
                        .toDouble()
                        .abs();
                    return Gauge(
                      value: speed,
                      minimum: 0,
                      maximum: 50,
                      annotationText: "$speed",
                      unitText: "kts",
                      title: "Speed",
                      ranges: [
                        GaugeRange(
                          startValue: 0,
                          endValue: 25,
                          color: Colors.green,
                        ),
                        GaugeRange(
                          startValue: 25,
                          endValue: 35,
                          color: Colors.yellow.shade600,
                        ),
                        GaugeRange(
                          startValue: 35,
                          endValue: 50,
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
                //Motor RPM
                ROSListenable(
                  valueNotifier: widget.comms.subscribe(
                    "/motors/can_motor_data",
                  ),
                  builder: (context, value) {
                    var data = (value["rpm"] as int).round().toDouble().abs();
                    return Gauge(
                      value: data,
                      minimum: 0,
                      maximum: 2500,
                      annotationText: "$data",
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
                          color: Color.fromRGBO(255, 0, 0, 1.0),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showWebsocketDisconnectedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isOnMainPage) return;
      closeConnectionDialog();
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
                onPressed: () { showSettingsDialog(); },
                child: Text("Open Settings"),
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
      if (!mounted || !isOnMainPage) return;
      closeConnectionDialog();
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(child: Text("ROSBridge Data Stale")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              "The websocket is initalized, but there is stale data from ROSBridge. \nThis means that the ROS Control System is likely down.",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () { showSettingsDialog(); },
                child: Text("Open Settings"),
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

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Waterboard Settings"),
          content: SettingsDialog(comms: widget.comms,),
        );
      },
    );
  }
}
