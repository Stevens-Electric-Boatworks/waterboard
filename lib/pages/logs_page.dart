// Flutter imports:
import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
    super.dispose();
    ros.rosLogs.onLogMessage.removeListener(_onROSLogMsg);
    log.onMessage.removeListener(_onWaterboardLogMsg);
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
    logMessages.add(logMsg);
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
    logMessages.add(logMsg);
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

  @override
  void initState() {
    super.initState();
    model.addListener(() => setState(() {}));
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
      padding: EdgeInsetsGeometry.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Table(
                        columnWidths: _getColumnWidths(),
                        children: [
                          TableRow(
                            children: List.generate(
                              7,
                              //empty row thats hidden
                              (index) => Text(" "),
                            ),
                          ),
                          ..._getRows(),
                        ],
                      ),
                    ),
                    Table(
                      columnWidths: _getColumnWidths(),
                      children: [getTopRow()],
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

  Map<int, FlexColumnWidth> _getColumnWidths() {
    return {
      0: FlexColumnWidth(0.8),
      1: FlexColumnWidth(1.2),
      2: FlexColumnWidth(0.8),
      3: FlexColumnWidth(7),
      4: FlexColumnWidth(4),
      5: FlexColumnWidth(1),
      6: FlexColumnWidth(1),
    };
  }

  TableRow getTopRow() {
    const TextStyle style = TextStyle(fontWeight: FontWeight.bold);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade500),
      children: [
        _withPadding(Text("Level", style: style)),
        _withPadding(Text("Timestamp", style: style)),
        _withPadding(Text("Source", style: style)),
        _withPadding(Text("Message", style: style)),
        _withPadding(Text("File", style: style)),
        _withPadding(Text("Function", style: style)),
        _withPadding(Text("Line #", style: style)),
      ],
    );
  }

  Widget _withPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }

  List<TableRow> _getRows() {
    List<TableRow> rows = [];
    int i = 0;
    Color backgroundLevelColor(String level, Color normalColor) {
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

    for (LogMessage msg in model.logMessages) {
      if (model.selectedFilter == Emitter.ros && msg.emitter == Emitter.dash) {
        continue;
      }
      if (model.selectedFilter == Emitter.dash && msg.emitter == Emitter.ros) {
        continue;
      }

      Color color = backgroundLevelColor(
        msg.level,
        i % 2 == 0 ? Colors.white : Colors.grey.shade300,
      );
      rows.insert(
        0,
        TableRow(
          decoration: BoxDecoration(
            color: color,
            border: BoxBorder.fromLTRB(
              bottom: BorderSide(color: Colors.black12),
            ),
          ),
          children: [
            _withPadding(
              Text(
                msg.level,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _withPadding(Text(_getTimeText(msg.timestamp))),
            _withPadding(
              Text(
                msg.emitter.name.toUpperCase(),
                style: TextStyle(
                  color: msg.emitter == Emitter.dash
                      ? Colors.blue
                      : Colors.black,
                ),
              ),
            ),
            _withPadding(
              Text(msg.message, style: TextStyle(fontStyle: FontStyle.italic)),
            ),
            _withPadding(Text(msg.file ?? "")),
            _withPadding(
              Text(
                msg.function ?? "",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            _withPadding(Text("${msg.lineNumber ?? ""}")),
          ],
        ),
      );
      i++;
    }
    return rows;
  }

  String _getTimeText(DateTime now) {
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;

    String two(int n) => n.toString().padLeft(2, '0');
    String amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${two(now.minute)}:${two(now.second)} $amPm';
  }
}
