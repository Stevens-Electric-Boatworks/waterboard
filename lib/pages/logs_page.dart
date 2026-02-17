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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Table(
                        columnWidths: _getColumnWidths(),
                        children: [getTopRow(), ..._getRows()],
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
      0: FlexColumnWidth(1),
      1: FlexColumnWidth(1.4),
      2: FlexColumnWidth(6),
      3: FlexColumnWidth(3),
      4: FlexColumnWidth(1),
      5: FlexColumnWidth(1),
    };
  }

  TableRow getTopRow() {
    const TextStyle style = TextStyle(fontWeight: FontWeight.bold);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade500),
      children: [
        Row(
          children: [
            SizedBox(width: 2),
            Text("Level", style: style),
          ],
        ),
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
    Color levelColor(String level) {
      if(level == "ERROR") return Colors.red;
      else if (level == "INFO") return Colors.black;
      else if (level == "WARN") return Colors.orange;
      else return Colors.black;
    }
    for (LogMessage msg in model.logMessages) {
      // Log.instance.info("building row");
      final Color color = i % 2 == 0 ? Colors.white : Colors.grey.shade300;
      rows.insert(
        0,
        TableRow(
          decoration: BoxDecoration(color: color),
          children: [
            Row(children: [SizedBox(width: 2), Text(msg.level, style: TextStyle(color: levelColor(msg.level)),)]),
    _withPadding(Text(msg.emitter.name.toUpperCase(), style: TextStyle(color: msg.emitter == Emitter.waterboard ? Colors.blue : Colors.black),)),
    _withPadding(Text(msg.message, style: TextStyle(fontStyle: FontStyle.italic))),
    _withPadding(Text(msg.file ?? "")),
    _withPadding(Text(msg.function ?? "", style: TextStyle(fontStyle: FontStyle.italic))),
    _withPadding(Text("${msg.lineNumber ?? ""}")),
          ],
        ),
      );
      i++;
    }
    return rows;
  }
}
