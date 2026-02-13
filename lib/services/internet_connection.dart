// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

abstract class InternetChecker {
  ValueNotifier<String?> get ssid;
  ValueNotifier<String?> get ipAddress;
  Stream<InternetStatus> get internetStatus;
  void dispose();
}

class InternetCheckerImpl extends InternetChecker {
  @override
  late Stream<InternetStatus> internetStatus;
  Timer? _networkTimer;
  final ValueNotifier<String?> _ssid = ValueNotifier(null);
  final ValueNotifier<String?> _ipAddress = ValueNotifier(null);
  final NetworkInfo networkInfo = NetworkInfo();
  InternetCheckerImpl() {
    internetStatus = InternetConnection.createInstance(
      customCheckOptions: [
        InternetCheckOption(uri: Uri.parse('shore.stevenseboat.org')),
      ],
    ).onStatusChange;

    _networkTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateNetworkInfo(),
    );
  }

  Future<void> updateNetworkInfo() async {
    _ssid.value = await networkInfo.getWifiName();
    _ipAddress.value = await networkInfo.getWifiIP();
  }

  @override
  void dispose() {
    _networkTimer?.cancel();
  }

  @override
  ValueNotifier<String?> get ipAddress => _ipAddress;
  @override
  ValueNotifier<String?> get ssid => _ssid;
}
