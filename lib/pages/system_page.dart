// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/services/sys_utils/system_util_service.dart';

class SystemPageViewModel extends ChangeNotifier {
  final Services services;

  SystemPageViewModel({required this.services});

  ValueNotifier<double> timeSinceLastMsg = ValueNotifier(-1);

  ValueNotifier<ROSSubscription?> get onROSSubscription =>
      services.ros.onSubscription;

  ValueNotifier<SystemDaemonState> get daemonState =>
      services.sysUtil.daemonState;

  ValueNotifier<SystemInformation?> get systemInformation =>
      services.sysUtil.systemInformation;

  int get rosSubscriptions => services.ros.subs.length;

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

  void init() {
    _lastPacketTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      Duration timeSince = services.clock.now().difference(
        services.ros.timeSinceLastMsg,
      );
      timeSinceLastMsg.value =
          timeSince.inSeconds + (timeSince.inMilliseconds % 1000) * 0.001;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _lastPacketTimer.cancel();
  }

  void rebootDaemon() {
    services.sysUtil.dispose();
    services.sysUtil.start();
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
                                      "s",
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "System Information",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
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
        },
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
    if (model.daemonState.value == SystemDaemonState.starting) {
      return _buildDaemonErrorScreen("The daemon is starting");
    }
    if (model.daemonState.value == SystemDaemonState.unknown) {
      return _buildDaemonErrorScreen("The daemon is unknown");
    }
    if (model.daemonState.value == SystemDaemonState.error) {
      return _buildDaemonErrorScreen("The daemon has had an error");
    }
    if (model.systemInformation.value == null) {
      return _buildDaemonErrorScreen(
        "The daemon has not given any data yet...",
      );
    }
    var val = model.systemInformation.value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          spacing: 20,
          children: [
            Expanded(
              child: PageUtils.buildText(
                context,
                "${val.cpuUtilPercent}",
                "CPU %",
              ),
            ),
            Expanded(
              child: PageUtils.buildText(
                context,
                "${val.memUsagePercent}",
                "Memory %",
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          spacing: 20,
          children: [
            Expanded(
              child: PageUtils.buildText(
                context,
                "${val.usedMemMB} MB",
                "Memory Usage",
              ),
            ),
            Expanded(
              child: PageUtils.buildText(
                context,
                "${val.totalDiskUsagePercent}",
                "Disk %",
              ),
            ),
          ],
        ),
      ],
    );
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
