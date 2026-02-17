// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

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

enum Emitter { ros, waterboard }

class LogsPageViewModel extends ChangeNotifier {
  final ROS ros;
  final List<LogMessage> logMessages = [];
  late ROSSubscription subscription;

  LogsPageViewModel({required this.ros});

  void init() {
    subscription = ros.subscribe("/rosout");
    subscription.notifier.addListener(_onROSLogMsg);
    Log.instance.onMessage.addListener(_onWaterboardLogMsg);
  }

  void _onROSLogMsg() {
    var newData = subscription.notifier.value;
    String toString(int level) {
      switch (level) {
        case 10:
          return "DEBUG";
        case 20:
          return "INFO";
        case 30:
          return "WARN";
        case 40:
          return "ERROR";
      }
      return "UNKNOWN";
    }

    String msg = newData['msg'] as String;
    String file = newData['file'] as String;
    String function = newData['function'] as String;
    int line = newData['line'] as int;
    int level = newData['level'] as int;
    //todo fix datetime
    var logMsg = LogMessage(
      emitter: Emitter.ros,
      message: msg,
      level: toString(level),
      timestamp: DateTime.now(),
      file: file,
      function: function,
      lineNumber: line,
    );
    logMessages.add(logMsg);
    notifyListeners();
  }

  void _onWaterboardLogMsg() {
    var msg = Log.instance.onMessage.value;
    if (msg == null) return;
    var logMsg = LogMessage(
      emitter: Emitter.waterboard,
      message: msg.msg,
      level: msg.level.name.toUpperCase(),
      timestamp: msg.time,
      file: null,
      function: null,
      lineNumber: null,
    );
    logMessages.add(logMsg);
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

  @override
  void initState() {
    super.initState();
    model.init();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: Column(
        children: [
          Text(
            "Control System Logs",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
         `     ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
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
      0: FlexColumnWidth(0.7),
      1: FlexColumnWidth(1.2),
      2: FlexColumnWidth(1.4),
      3: FlexColumnWidth(6),
      4: FlexColumnWidth(3),
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
        _withPadding(Text("Emitter", style: style)),
        _withPadding(Text("Message", style: style)),
        _withPadding(Text("File", style: style)),
        _withPadding(Text("Func.", style: style)),
        _withPadding(Text("Line", style: style)),
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
      Color color = backgroundLevelColor(
        msg.level,
        i % 2 == 0 ? Colors.white : Colors.grey.shade300,
      );
      rows.insert(
        0,
        TableRow(
          decoration: BoxDecoration(
            color: color,
            border: BoxBorder.fromLTRB(bottom: BorderSide(color: Colors.black)),
          ),
          children: [
            _withPadding(
              Text(msg.level, style: TextStyle(color: Colors.black)),
            ),
            _withPadding(Text(_getTimeText(msg.timestamp))),
            _withPadding(
              Text(
                msg.emitter.name.toUpperCase(),
                style: TextStyle(
                  color: msg.emitter == Emitter.waterboard
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
