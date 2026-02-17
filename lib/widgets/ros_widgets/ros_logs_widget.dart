// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class LogMessage {
  String msg;
  String file;
  String function;
  int line;

  LogMessage(this.msg, this.file, this.function, this.line);

  @override
  String toString() {
    return 'LogMessage{msg: $msg, file: $file, function: $function, line: $line}';
  }
}

class LogsWidgetViewModel extends ChangeNotifier {
  final ROSSubscription _sub;
  late final ValueNotifier<Map<String, dynamic>> _data;
  final List<LogMessage> _messages = [];

  LogsWidgetViewModel(this._sub) {
    _data = _sub.notifier;
  }

  List<LogMessage> get messages => _messages;

  void init() {
    _data.addListener(onDataReceive);
  }

  void onDataReceive() {
    var newData = _data.value;
    String msg = newData['msg'] as String;
    String file = newData['file'] as String;
    String function = newData['function'] as String;
    int line = newData['line'] as int;
    _messages.add(LogMessage(msg, file, function, line));
    Log.instance.info(_messages.last);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _data.removeListener(onDataReceive);
  }
}

class LogsWidget extends StatefulWidget {
  final LogsWidgetViewModel model;

  const LogsWidget({super.key, required this.model});

  @override
  State<LogsWidget> createState() => _LogsWidgetState();
}

class _LogsWidgetState extends State<LogsWidget> {
  LogsWidgetViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.init();
    model.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return DataTable(
      clipBehavior: Clip.none,
      columns: [
        DataColumn(label: Text("Message")),
        DataColumn(label: Text("Line")),
        DataColumn(label: Text("File")),
        DataColumn(label: Text("Function")),
      ],
      rows: _getRows(),
    );
  }

  List<DataRow> _getRows() {
    List<DataRow> rows = [];
    for (LogMessage msg in model.messages) {
      rows.add(
        DataRow(
          cells: [
            DataCell(Text(msg.msg)),
            DataCell(Text(msg.file)),
            DataCell(Text(msg.function)),
            DataCell(Text("${msg.line}")),
          ],
        ),
      );
    }
    return rows;
  }
}
