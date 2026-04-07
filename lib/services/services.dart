// Package imports:
import 'package:clock/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/services/hotkey_manager.dart';
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_logs_collector.dart';
import 'package:waterboard/services/system_power_service.dart';

class Services {
  late final ROS _ros;
  late final Log _logger;
  late final InternetChecker _internetChecker;
  late final SharedPreferences _preferences;
  late final HotKeyManager _hotKeyManager;
  late final SystemPowerService _systemPowerService;
  final Clock clock = Clock();

  ROS get ros => _ros;
  ROSLogsCollector get logsCollector => _ros.rosLogs;
  Log get logger => _logger;
  InternetChecker get internet => _internetChecker;
  SharedPreferences get preferences => _preferences;
  HotKeyManager get hotkeys => _hotKeyManager;
  SystemPowerService get sysPower => _systemPowerService;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _logger = Log(storeLogs: true, clock: clock);
    _logger.initialize();
    _ros = ROSImpl(_logger, _preferences);
    _internetChecker = InternetCheckerImpl();
    _hotKeyManager = HotKeyManager();
    _systemPowerService = SystemPowerService(log: _logger);
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
    _hotKeyManager = HotKeyManager();
    //TODO: Add mocks for sys power service
  }
}
