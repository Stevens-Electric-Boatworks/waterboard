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

  List<UsageDataPoint> cpuUsage = [];
  List<UsageDataPoint> ramUsage = [];

  void init() {
    _lastPacketTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      Duration timeSince = services.clock.now().difference(
        services.ros.timeSinceLastMsg,
      );
      timeSinceLastMsg.value =
          timeSince.inSeconds + (timeSince.inMilliseconds % 1000) * 0.001;
    });
  }

  void _addToUsageList(List<UsageDataPoint> usageList, double data) {
    usageList.insert(0, UsageDataPoint(time: DateTime.now(), usage: data));
    if (usageList.length > 31) {
      usageList.removeAt(usageList.length - 1);
      usageList.removeRange(31, usageList.length);
    }
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                "System Information",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              Spacer(),
              ValueListenableBuilder(
                valueListenable: model.daemonState,
                builder: (context, value, child) {
                  if (model.daemonState.value == SystemDaemonState.online) {
                    return IconButton(
                      onPressed: () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Center(child: Text("Reboot Python Daemon?")),
                            content: Text(
                              "This action will stop the python system usage daemon, and attempt to rerun the command to start it.",
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reboot'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != null && confirm) {
                          model.rebootDaemon();
                        }
                      },
                      icon: Icon(
                        Icons.restart_alt,
                        size: Theme.of(context).textTheme.titleLarge!.fontSize!,
                      ),
                      tooltip: "Restart Python Daemon",
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
          SizedBox(height: 10),
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
    if (kIsWeb) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            color: Colors.blue,
            size: Theme.of(context).textTheme.displaySmall!.fontSize,
          ),
          Text(
            "This feature is unsupported on Web",
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          Text(
            "Please use Windows, Linux, MacOS, or FlutterPi",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    List<Widget> body = [];
    if (model.daemonState.value == SystemDaemonState.starting) {
      body = [_buildDaemonErrorScreen("The daemon process is starting...")];
    } else if (model.daemonState.value == SystemDaemonState.unknown) {
      body = [_buildDaemonErrorScreen("The daemon state is unknown...")];
    } else if (model.daemonState.value == SystemDaemonState.error) {
      body = [
        _buildDaemonErrorScreen(
          "The daemon process encountered an error causing termination...",
        ),
      ];
    } else if (model.systemInformation.value == null) {
      body = [
        _buildDaemonErrorScreen("The daemon has not given any data yet..."),
      ];
    } else {
      body = [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            spacing: 20,
            children: [
              Expanded(
                child: PageUtils.buildWidgetBackground(
                  _buildChart("CPU Usage (%)", _getChartData(model.cpuUsage)),
                ),
              ),
              Expanded(
                child: PageUtils.buildWidgetBackground(
                  _buildChart(
                    "Memory Usage (%)",
                    _getChartData(model.ramUsage),
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
                child: PageUtils.buildText(
                  context,
                  "↑${model.systemInformation.value?.txMBPerSec.toStringAsFixed(1) ?? "Unknown"}/↓${(model.systemInformation.value?.rxMBPerSec.toStringAsFixed(1)) ?? "Unknown"} MB",
                  "TX/RX",
                ),
              ),
              Expanded(
                child: PageUtils.buildText(
                  context,
                  "${model.systemInformation.value?.totalDiskUsagePercent ?? "N/A"}% (${model.systemInformation.value?.diskFreeGB.toInt() ?? "N/A"}GB Free)",
                  style: Theme.of(context).textTheme.headlineLarge!.merge(
                    TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                  "Disk Usage",
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        ...body,
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

  Widget _buildChart(
    String title,
    List<FastLineSeries<UsageDataPoint, double>> data,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              height: constraints.maxHeight / 1.2,
              child: SfCartesianChart(
                series: data,
                crosshairBehavior: CrosshairBehavior(
                  enable: true,
                  activationMode: ActivationMode.singleTap,
                  shouldAlwaysShow: true,
                  lineColor: Colors.black,
                ),
                plotAreaBackgroundColor: Colors.grey.shade300,
                plotAreaBorderColor: Colors.black,
                primaryXAxis: NumericAxis(
                  interval: 10,
                  minimum: 0,
                  maximum: 30,
                  isInversed: true,
                  decimalPlaces: 0,
                  labelFormat: 'T+{value}s',
                  majorGridLines: MajorGridLines(color: Colors.black),
                  majorTickLines: MajorTickLines(color: Colors.black),
                  axisLabelFormatter: (axisLabelRenderArgs) => ChartAxisLabel(
                    axisLabelRenderArgs.text,
                    Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  labelFormat: '{value}%',
                  majorTickLines: MajorTickLines(color: Colors.black),
                  majorGridLines: MajorGridLines(color: Colors.black),
                  axisLabelFormatter: (axisLabelRenderArgs) => ChartAxisLabel(
                    axisLabelRenderArgs.text,
                    Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FastLineSeries<UsageDataPoint, double>> _getChartData(
    List<UsageDataPoint> sourceData,
  ) {
    return <FastLineSeries<UsageDataPoint, double>>[
      FastLineSeries<UsageDataPoint, double>(
        animationDuration: 0.0,
        animationDelay: 0.0,
        sortingOrder: SortingOrder.ascending,
        color: Colors.blue,
        width: 4,
        dataSource: sourceData,
        xValueMapper: (value, index) {
          return (DateTime.now().difference(value.time).inSeconds).toDouble();
        },
        yValueMapper: (value, index) {
          return value.usage;
        },
        markerSettings: MarkerSettings(
          isVisible: true,
          shape: DataMarkerType.diamond,
        ),
        enableTooltip: true,
      ),
    ];
  }

  Widget _buildDaemonErrorScreen(String message) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.error,
          color: Colors.red,
          size: Theme.of(context).textTheme.displaySmall!.fontSize,
        ),
        Text(
          message,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            model.rebootDaemon();
          },
          child: Text(
            "Reboot Daemon Process",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class UsageDataPoint {
  final DateTime time;
  final double usage;

  UsageDataPoint({required this.time, required this.usage});
}
