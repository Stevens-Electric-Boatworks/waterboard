// Package imports:
import 'package:clock/clock.dart';

// Project imports:
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';

class Services {
  late final ROS _ros;
  late final Log _logger;
  late final InternetChecker _internetChecker;
  final Clock clock = Clock();

  ROS get ros => _ros;
  ROSLogsCollector get logsCollector => _ros.rosLogs;
  Log get logger => _logger;
  InternetChecker get internet => _internetChecker;

  void initialize() {
    _logger = Log(storeLogs: true, clock: clock);
    _logger.initialize();
    _ros = ROSImpl(_logger);
    _internetChecker = InternetCheckerImpl();
  }

  void initializeWithMocks({
    required ROS ros,
    required Log logger,
    required InternetChecker internet,
  }) {
    _ros = ros;
    _logger = logger;
    _logger.initialize();
    _internetChecker = internet;
  }
}
