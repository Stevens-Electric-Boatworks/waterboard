// Primarily Elastic Dashboards logging feature, which comes from 3015 PathPlanner's logging feature
// http://github.com/Gold872/elastic_dashboard/blob/main/lib/services/log.dart
// https://github.com/mjansen4857/pathplanner/blob/main/lib/services/log.dart

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class Log extends ChangeNotifier {
  static final DateFormat _dateFormat = DateFormat('HH:mm:ss.S');

  static Log instance = Log._internal();

  Log._internal();

  Logger? _logger;
  List<WaterboardLogMessage> msgs = [];
  final ValueNotifier<WaterboardLogMessage?> onMessage = ValueNotifier(null);

  Future<void> initialize() async {
    _logger = Logger(
      printer: HybridPrinter(
        SimplePrinter(colors: kDebugMode),
        error: PrettyPrinter(methodCount: 5, colors: kDebugMode),
        warning: PrettyPrinter(methodCount: 5, colors: kDebugMode),
      ),
      output: MultiOutput([ConsoleOutput()]),
      filter: ProductionFilter(),
    );
  }

  void log(Level level, dynamic message, [dynamic error, StackTrace? trace]) {
    if (Logger.level.value > level.value) {
      return;
    }
    var msg = WaterboardLogMessage(
      msg: message,
      level: level,
      time: DateTime.now(),
    );
    msgs.add(msg);
    _logger?.log(
      level,
      '[${_dateFormat.format(DateTime.now())}]:  $message',
      error: error,
      stackTrace: trace,
    );
    onMessage.value = msg;
    notifyListeners();
  }

  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.info, message, error, stackTrace);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.error, message, error, stackTrace);
  }

  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.warning, message, error, stackTrace);
  }

  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.debug, message, error, stackTrace);
  }

  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    log(Level.trace, message, error, stackTrace);
  }
}

class WaterboardLogMessage {
  final String msg;
  final Level level;
  final DateTime time;

  WaterboardLogMessage({
    required this.msg,
    required this.level,
    required this.time,
  });
}

Log get logger => Log.instance;
