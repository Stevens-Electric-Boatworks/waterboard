// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:syncfusion_flutter_charts/charts.dart';

// Project imports:
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/services/system_usage_service.dart';
import 'package:waterboard/widgets/hazard_stripe_border.dart';
import 'package:waterboard/widgets/ros_widgets/ros_graph_widget.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';

class SystemPageViewModel extends ChangeNotifier {
  final Services services;

  SystemPageViewModel({required this.services}) {
    //initialize the counter, and start on application startup
    services.sysUtil.systemInformation.addListener(() {
      var val = services.sysUtil.systemInformation.value;
      if (val != null) {
        _addToUsageList(cpuUsage, val.cpuUtilPercent);
        _addToUsageList(ramUsage, val.memUsagePercent);
        notifyListeners();
      }
    });
  }

  ValueNotifier<double> timeSinceLastMsg = ValueNotifier(-1);

  ValueNotifier<ROSSubscription?> get onROSSubscription =>
      services.ros.onSubscription;

  ValueNotifier<SystemDaemonState> get daemonState =>
      services.sysUtil.daemonState;

  ValueNotifier<SystemInformation?> get systemInformation =>
      services.sysUtil.systemInformation;

  int get rosSubscriptions => services.ros.subs.length;

  List<GraphDataPoint> cpuUsage = [];
  List<GraphDataPoint> ramUsage = [];

  late ROSGraphDataSource cpuDataSource;
  late ROSGraphDataSource ramDataSource;

  late ROSTextDataSource diskUsageDataSource;
  late ROSTextDataSource txRxDataSource;

  void init() {
    cpuDataSource = ROSGraphDataSource(
      subscription: services.ros.subscribe("/sys_utilization"),
      valueBuilder: (json) {
        _addToUsageList(cpuUsage, json["cpu_percent"]);
        return cpuUsage;
      },
    );
    ramDataSource = ROSGraphDataSource(
      subscription: services.ros.subscribe("/sys_utilization"),
      valueBuilder: (json) {
        _addToUsageList(ramUsage, json["percent_mem"]);
        return ramUsage;
      },
    );

    diskUsageDataSource = ROSTextDataSource(
      sub: services.ros.subscribe("/sys_utilization"),
      valueBuilder: (json) {
        return (
          "${(json["disk_percent"] as double).toStringAsFixed(1)}% (${((json["disk_total"] - json["disk_used"]) / 1e7 as double).toInt()}GB Free)",
          Colors.black,
        );
      },
    );
    txRxDataSource = ROSTextDataSource(
      sub: services.ros.subscribe("/sys_utilization"),
      valueBuilder: (json) {
        return (
          "↑${(json["tx_mb"] as double).toStringAsFixed(1)}/↓${(json["rx_mb"] as double).toStringAsFixed(1)} MB",
          Colors.black,
        );
      },
    );

    _lastPacketTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      Duration timeSince = services.clock.now().difference(
        services.ros.timeSinceLastMsg,
      );
      timeSinceLastMsg.value =
          timeSince.inSeconds + (timeSince.inMilliseconds % 1000) * 0.001;
    });
  }

  void _addToUsageList(List<GraphDataPoint> usageList, double data) {
    usageList.insert(0, GraphDataPoint(time: DateTime.now(), value: data));
    // if (usageList.length > 31) {
    //   usageList.removeAt(usageList.length - 1);
    //   usageList.removeRange(31, usageList.length);
    // }
  }

  List<String> get rosSubList {
    List<String> subs = [];

    for (var value in services.ros.subs.keys) {
      subs.add(value);
    }
    return subs;
  }

  ROSSubscription? getSubscription(String name) {
    return services.ros.subs[name];
  }

  late final Timer _lastPacketTimer;

  @override
  void dispose() {
    super.dispose();
    _lastPacketTimer.cancel();
  }

  void rebootDaemon() {
    services.sysUtil.dispose();
    services.sysUtil.start();
  }

  void shutdownSystem() {
    services.sysPower.shutdown();
  }

  void rebootSystem() {
    services.sysPower.reboot();
  }
}

class SystemPage extends StatefulWidget {
  final SystemPageViewModel model;

  const SystemPage({super.key, required this.model});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  SystemPageViewModel get model => widget.model;

  @override
  void initState() {
    print("initalized!");
    super.initState();
    model.init();
    model.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    model.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 4, child: _buildROSSystemStatus()),
          const SizedBox(width: 20),
          Flexible(flex: 7, child: _buildSysInfo()),
        ],
      ),
    );
  }

  Widget _buildROSSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: PageUtils.panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "ROS Status",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      spacing: 20,
                      children: [
                        // Watchdog Timer
                        ValueListenableBuilder(
                          valueListenable: model.timeSinceLastMsg,
                          builder:
                              (BuildContext context, value, Widget? child) {
                                Color color;
                                if (value < 0.3) {
                                  color = Colors.green;
                                } else if (value <= 3) {
                                  color = Colors.orange.shade700;
                                } else {
                                  color = Colors.red.shade700;
                                }
                                if (value == -1) {
                                  return PageUtils.buildWidgetBackground(
                                    PageUtils.buildText(
                                      context,
                                      "Unknown",
                                      color: color,
                                      "Time Since Last Packet",
                                    ),
                                  );
                                }
                                return PageUtils.buildWidgetBackground(
                                  PageUtils.buildText(
                                    context,
                                    "${value.toStringAsFixed(1)}s",
                                    color: color,
                                    "Time Since Last Packet",
                                  ),
                                );
                              },
                        ),
                        //ROS Sub Count
                        ValueListenableBuilder(
                          valueListenable: model.onROSSubscription,
                          builder:
                              (BuildContext context, value, Widget? child) {
                                return PageUtils.buildWidgetBackground(
                                  PageUtils.buildText(
                                    context,
                                    "${model.rosSubscriptions} Subscriptions",
                                    "# of ROS Subscriptions",
                                  ),
                                );
                              },
                        ),
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: model.onROSSubscription,
                            builder:
                                (BuildContext context, value, Widget? child) {
                                  return PageUtils.buildWidgetBackground(
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Subscriptions List",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.displaySmall,
                                        ),
                                        SizedBox(height: 10),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: BoxBorder.all(
                                                color: Colors.black,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsetsGeometry.all(16),
                                            child: ListView.builder(
                                              itemCount: model.rosSubscriptions,
                                              itemBuilder: (context, index) {
                                                String name =
                                                    model.rosSubList[index];
                                                ROSSubscription sub = model
                                                    .getSubscription(name)!;
                                                return ValueListenableBuilder(
                                                  valueListenable: sub.isStale,
                                                  builder:
                                                      (context, value, child) {
                                                        String staleText = value
                                                            ? "Stale"
                                                            : "Alive";
                                                        Color color = value
                                                            ? Colors
                                                                  .red
                                                                  .shade700
                                                            : Colors
                                                                  .green
                                                                  .shade500;
                                                        TextStyle style =
                                                            Theme.of(context)
                                                                .textTheme
                                                                .titleMedium!;
                                                        return Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style: style,
                                                            ),
                                                            Spacer(),
                                                            Text(
                                                              staleText,
                                                              style: style
                                                                  .merge(
                                                                    TextStyle(
                                                                      color:
                                                                          color,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSysInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: PageUtils.panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "System Information",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                model.systemInformation,
                model.daemonState,
              ]),
              builder: (context, child) {
                return _buildSystemStats();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      spacing: 20,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            spacing: 20,
            children: [
              Expanded(
                child: PageUtils.buildWidgetBackground(
                  ROSGraphWidget(
                    title: "CPU Usage (%)",
                    unit: "%",
                    dataSource: model.cpuDataSource,
                  ),
                ),
              ),
              Expanded(
                child: PageUtils.buildWidgetBackground(
                  ROSGraphWidget(
                    title: "RAM Usage (%)",
                    unit: "%",
                    dataSource: model.ramDataSource,
                  ),
                ),
              ),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            spacing: 20,
            children: [
              Expanded(
                child: PageUtils.buildWidgetBackground(
                  ROSText(
                    dataSource: model.txRxDataSource,
                    subtext: "Network TX/RX",
                  ),
                ),
              ),
              Expanded(
                child: PageUtils.buildWidgetBackground(
                  ROSText(
                    dataSource: model.diskUsageDataSource,
                    subtext: "Disk Usage",
                    valueTextStyle: Theme.of(context).textTheme.headlineLarge!
                        .merge(TextStyle(overflow: TextOverflow.ellipsis)),
                  ),
                ),
              ),
            ],
          ),
        ),
        //Reboot Buttons
        Row(
          spacing: 20,
          children: [
            Expanded(
              child: HazardStripeBorder(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    padding: EdgeInsetsGeometry.all(12),
                  ),
                  onPressed: () async {
                    PageUtils.dangerConfirmDialog(
                      context,
                      "Shutdown System?",
                      "This will shutdown the host OS.",
                      model.shutdownSystem,
                      backgroundColor: Colors.red.shade100,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 15,
                    children: [Icon(Icons.warning), Text("Shutdown System")],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade300,
                  foregroundColor: Colors.white,
                  textStyle: Theme.of(context).textTheme.titleMedium,
                  padding: EdgeInsetsGeometry.all(12),
                ),
                onPressed: () async {
                  PageUtils.dangerConfirmDialog(
                    context,
                    "Reboot System?",
                    "This will reboot the host OS.",
                    model.rebootSystem,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 15,
                  children: [Icon(Icons.warning), Text("Reboot System")],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
