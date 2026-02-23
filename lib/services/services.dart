// Package imports:
import 'package:clock/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';

class Services {
  late final ROS _ros;
  late final Log _logger;
  late final InternetChecker _internetChecker;
  late final SharedPreferences _preferences;
  final Clock clock = Clock();

  ROS get ros => _ros;
  ROSLogsCollector get logsCollector => _ros.rosLogs;
  Log get logger => _logger;
  InternetChecker get internet => _internetChecker;
  SharedPreferences get preferences => _preferences;

  Future<void> initialize() async {
    _logger = Log(storeLogs: true, clock: clock);
    _logger.initialize();
    _ros = ROSImpl(_logger);
    _internetChecker = InternetCheckerImpl();
    _preferences = await SharedPreferences.getInstance();
  }

  Future<void> initializeWithMocks({
    required ROS ros,
    required Log logger,
    required InternetChecker internet,
  }) async {
    _preferences = await SharedPreferences.getInstance();
    _ros = ros;
    _logger = logger;
    _logger.initialize();
    _internetChecker = internet;
  }
}
