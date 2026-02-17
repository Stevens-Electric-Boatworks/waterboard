// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class ROSLogMessage {
  String msg;
  String file;
  String function;
  int line;
  int level;

  ROSLogMessage(this.msg, this.file, this.function, this.line, this.level);

  String get levelString {
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

  @override
  String toString() {
    return 'LogMessage{msg: $msg, file: $file, function: $function, line: $line, level: $level}';
  }
}

class LogsWidgetViewModel extends ChangeNotifier {
  final ROSSubscription _sub;
  late final ValueNotifier<Map<String, dynamic>> _data;
  final List<ROSLogMessage> _messages = [];

  LogsWidgetViewModel(this._sub) {
    _data = _sub.notifier;
  }

  List<ROSLogMessage> get messages => _messages;

  void init() {
    _data.addListener(onDataReceive);
  }

  void onDataReceive() {
    var newData = _data.value;
    String msg = newData['msg'] as String;
    String file = newData['file'] as String;
    String function = newData['function'] as String;
    int line = newData['line'] as int;
    int level = newData['level'] as int;
    _messages.add(ROSLogMessage(msg, file, function, line, level));
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _data.removeListener(onDataReceive);
  }
}

class ROSLogsWidget extends StatefulWidget {
  final LogsWidgetViewModel model;

  const ROSLogsWidget({super.key, required this.model});

  @override
  State<ROSLogsWidget> createState() => _ROSLogsWidgetState();
}

class _ROSLogsWidgetState extends State<ROSLogsWidget> {
  LogsWidgetViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Table(columnWidths: _getColumnWidths(), children: [getTopRow()]),
          ],
        ),
      ),
    );
  }

  Map<int, FlexColumnWidth> _getColumnWidths() {
    return {
      0: FlexColumnWidth(1),
      1: FlexColumnWidth(7),
      2: FlexColumnWidth(3),
      3: FlexColumnWidth(1),
      4: FlexColumnWidth(1),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("Message", style: style),
        ),
        Text("File", style: style),
        Text("Func.", style: style),
        Text("Line", style: style),
      ],
    );
  }

  List<TableRow> _getRows() {
    List<TableRow> rows = [];
    int i = 0;
    for (ROSLogMessage msg in model.messages) {
      final Color color = i % 2 == 0 ? Colors.white : Colors.grey.shade300;
      rows.insert(
        0,
        TableRow(
          decoration: BoxDecoration(color: color),
          children: [
            Row(children: [SizedBox(width: 2), Text(msg.levelString)]),
            Text(msg.msg, style: TextStyle(fontStyle: FontStyle.italic)),
            Text(msg.file),
            Text(msg.function, style: TextStyle(fontStyle: FontStyle.italic)),
            Text("${msg.line}"),
          ],
        ),
      );
      i++;
    }
    return rows;
  }
}
