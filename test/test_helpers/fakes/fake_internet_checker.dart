import 'dart:async';

import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:waterboard/services/internet_connection.dart';

class FakeInternetChecker extends InternetChecker {
  final StreamController<InternetStatus> controller = StreamController<InternetStatus>();

  @override
  late Stream<InternetStatus> internetStatus = controller.stream;
  @override
  ValueNotifier<String?> ipAddress = ValueNotifier(null);
  @override
  ValueNotifier<String?> ssid = ValueNotifier(null);
  @override
  void dispose() {}
}