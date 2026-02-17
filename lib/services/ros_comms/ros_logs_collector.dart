import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class ROSLog {
  final String msg;
  final String file;
  final String function;
  final int line;
  final String level;
  final DateTime time;

  ROSLog({required this.msg, required this.file, required this.function, required this.line, required this.level, required this.time});
}
class ROSLogsCollector {
  final ROSSubscription subscription;
  final List<ROSLog> logs = [];
  final ValueNotifier<ROSLog?> onLogMessage = ValueNotifier(null);

  ROSLogsCollector({required this.subscription});
  void init() {
    subscription.notifier.addListener(_onDataReceive);
  }
  void _onDataReceive() {
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
    int msSinceEpoch = (newData['stamp']['sec'] as int) * 1000;
    logs.add(ROSLog(msg: msg, file: file, function: function, line: line, level: toString(level), time: DateTime.fromMillisecondsSinceEpoch(msSinceEpoch)));
  }
}