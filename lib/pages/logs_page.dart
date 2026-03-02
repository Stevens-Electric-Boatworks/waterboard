// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';

import '../services/log.dart';

class LogMessage {
  final Emitter emitter;
  final String message;
  final DateTime timestamp;
  final String level;
  final int? lineNumber;
  final String? file;
  final String? function;

  LogMessage({
    required this.emitter,
    required this.message,
    required this.timestamp,
    required this.level,
    required this.lineNumber,
    required this.file,
    required this.function,
  });
}

enum Emitter { ros, dash, none }

class LogsPageViewModel extends ChangeNotifier {
  final Services services;
  final List<LogMessage> logMessages = [];
  late ROSSubscription subscription;

  Emitter selectedFilter = Emitter.none;

  LogsPageViewModel({required this.services});

  ROS get ros => services.ros;

  Log get log => services.logger;

  void init() {
    ros.rosLogs.onLogMessage.addListener(_onROSLogMsg);
    log.onMessage.addListener(_onWaterboardLogMsg);
    //go through all previous logs
    for (var element in ros.rosLogs.logs) {
      _addROSLogToList(element);
    }
    for (var element in log.msgs) {
      _addWaterboardLogToList(element);
    }
    //sort by time
    logMessages.sort((a, b) {
      return a.timestamp.compareTo(b.timestamp);
    });
    services.hotkeys.register(
      LogicalKeyboardKey.keyA,
      callback: () {
        selectedFilter = Emitter.none;
        notifyListeners();
      },
    );
    services.hotkeys.register(
      LogicalKeyboardKey.keyW,
      callback: () {
        selectedFilter = Emitter.dash;
        notifyListeners();
      },
    );
    services.hotkeys.register(
      LogicalKeyboardKey.keyR,
      callback: () {
        selectedFilter = Emitter.ros;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    ros.rosLogs.onLogMessage.removeListener(_onROSLogMsg);
    log.onMessage.removeListener(_onWaterboardLogMsg);
  }

  List<LogMessage> get filteredLogs {
    if (selectedFilter == Emitter.none) {
      return logMessages;
    }

    return logMessages
        .where((log) => log.emitter == selectedFilter)
        .toList(growable: false);
  }

  void _onROSLogMsg() {
    var log = ros.rosLogs.onLogMessage.value;
    if (log == null) return;
    _addROSLogToList(log);
    notifyListeners();
  }

  void _addROSLogToList(ROSLog log) {
    var logMsg = LogMessage(
      emitter: Emitter.ros,
      message: log.msg,
      level: log.level,
      timestamp: log.time,
      file: log.file,
      function: log.function,
      lineNumber: log.line,
    );
    _addToList(logMsg);
  }

  void _addToList(LogMessage message) {
    logMessages.add(message);
    if (logMessages.length == 2000) {
      logMessages.removeAt(0);
    }
  }

  void _onWaterboardLogMsg() {
    var msg = log.onMessage.value;
    if (msg == null) return;
    _addWaterboardLogToList(msg);
    notifyListeners();
  }

  void _addWaterboardLogToList(WaterboardLogMessage log) {
    var logMsg = LogMessage(
      emitter: Emitter.dash,
      message: log.msg,
      level: log.level.name.toUpperCase(),
      timestamp: log.time,
      file: null,
      function: null,
      lineNumber: null,
    );
    _addToList(logMsg);
  }

  void clearLogs() {
    logMessages.clear();
    notifyListeners();
  }
}

class LogsPage extends StatefulWidget {
  final LogsPageViewModel model;

  const LogsPage({super.key, required this.model});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  LogsPageViewModel get model => widget.model;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    model.addListener(
      () => setState(() {
        _checkScrollState();
      }),
    );
    model.init();
  }

  @override
  void dispose() {
    super.dispose();
    model.dispose();
  }

  void _checkScrollState() {
    if (!_controller.hasClients) return;

    final threshold = 50.0;
    final isNearBottom =
        _controller.position.pixels >=
        _controller.position.maxScrollExtent - threshold;

    if (!isNearBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle messageStyle = Theme.of(context).textTheme.labelMedium!;
    final TextStyle headerStyle = Theme.of(
      context,
    ).textTheme.labelSmall!.merge(TextStyle(fontWeight: FontWeight.bold));
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  model.clearLogs();
                },
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 5),
                    Text("Clear Logs"),
                  ],
                ),
              ),
              SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (timeStamp) => _controller.position.jumpTo(
                      _controller.position.maxScrollExtent + 500,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward),
                    SizedBox(width: 5),
                    Text("Jump To Bottom"),
                  ],
                ),
              ),
              Spacer(),
              Center(
                child: Text(
                  "Control System Logs",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Spacer(),
              SegmentedButton<Emitter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: Emitter.none,
                    label: Text("All"),
                    icon: Icon(Icons.remove_red_eye),
                  ),
                  ButtonSegment(
                    value: Emitter.ros,
                    label: Text("ROS"),
                    icon: Icon(Icons.computer),
                  ),
                  ButtonSegment(
                    value: Emitter.dash,
                    label: Text("Waterboard"),
                    icon: Icon(Icons.water_drop),
                  ),
                ],
                selected: {model.selectedFilter},
                onSelectionChanged: (Set<Emitter> newSelection) {
                  setState(() {
                    model.selectedFilter = newSelection.first;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 5),
          //Log Viewer
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey,
                      child: Row(
                        children: [
                          _buildRowEntry(Text("Level", style: headerStyle), 1),
                          _buildRowEntry(
                            Text("Timestamp", style: headerStyle),
                            2,
                          ),
                          _buildRowEntry(Text("Source", style: headerStyle), 1),
                          _buildRowEntry(
                            Text("Message", style: headerStyle),
                            13,
                          ),
                          _buildRowEntry(Text("File", style: headerStyle), 4),
                          _buildRowEntry(
                            Text("Function", style: headerStyle),
                            2,
                          ),
                          _buildRowEntry(Text("Line", style: headerStyle), 1),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: _controller,
                        itemCount: model.filteredLogs.length,
                        itemBuilder: (context, index) {
                          Color backgroundLevelColor(
                            String level,
                            Color normalColor,
                          ) {
                            if (level == "ERROR") {
                              return Colors.red.shade100;
                            } else if (level == "INFO") {
                              return normalColor;
                            } else if (level == "WARN") {
                              return Colors.orange.shade100;
                            } else {
                              return normalColor;
                            }
                          }

                          var msg = model.filteredLogs[index];
                          Color color = backgroundLevelColor(
                            msg.level,
                            index % 2 == 0
                                ? Colors.white
                                : Colors.grey.shade300,
                          );
                          return Container(
                            color: color,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                _buildRowEntry(
                                  Text(
                                    msg.level,
                                    style: messageStyle.merge(
                                      TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  1,
                                ),
                                _buildRowEntry(
                                  Text(
                                    _getTimeText(msg.timestamp),
                                    style: messageStyle,
                                  ),
                                  2,
                                ),
                                _buildRowEntry(
                                  Text(
                                    msg.emitter.name.toUpperCase(),
                                    style: messageStyle.merge(
                                      TextStyle(
                                        color: msg.emitter == Emitter.dash
                                            ? Colors.blue
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  1,
                                ),
                                _buildRowEntry(
                                  Text(
                                    msg.message,
                                    style: messageStyle.merge(
                                      TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  13,
                                ),
                                _buildRowEntry(
                                  Text(msg.file ?? "", style: messageStyle),
                                  4,
                                ),
                                _buildRowEntry(
                                  Text(
                                    msg.function ?? "",
                                    style: messageStyle.merge(
                                      TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  2,
                                ),
                                _buildRowEntry(
                                  Text(
                                    "${msg.lineNumber ?? ""}",
                                    style: messageStyle.merge(
                                      TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  1,
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(height: 1, thickness: 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowEntry(Widget child, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      ),
    );
  }

  String _getTimeText(DateTime now) {
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;

    String two(int n) => n.toString().padLeft(2, '0');
    String amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${two(now.minute)}:${two(now.second)} $amPm';
  }
}
