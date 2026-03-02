import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';

class SystemPageViewModel extends ChangeNotifier {
  final Services services;

  SystemPageViewModel({required this.services});

  ValueNotifier<double> timeSinceLastMsg = ValueNotifier(-1);

  ValueNotifier<ROSSubscription?> get onROSSubscription =>
      services.ros.onSubscription;

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
      decoration: PageUtils.panelDecoration(),
    );
  }
}
