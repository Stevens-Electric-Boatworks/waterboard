// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:waterboard/services/log.dart';

class SystemPowerService {
  final Log log;

  SystemPowerService({required this.log});

  void shutdown() {
    log.info("Attempting shutdown");
    if (kIsWeb) {
      log.error("No Web shutdown command");
    }
    if (Platform.isWindows) {
      log.warning("Running Windows shutdown command");
      Process.run("shutdown", ["/s", "/t", "0"]);
    }
    if (Platform.isLinux) {
      log.warning("Running Linux shutdown command");
      Process.run("shutdown", ["-h", "now"]);
    }
    if (Platform.isMacOS) {
      log.error("No MacOS shutdown command");
    }
  }

  void reboot() {
    if (kIsWeb) {
      log.error("No Web shutdown command");
    }
    if (Platform.isWindows) {
      log.warning("Running Windows reboot command");
      Process.run("shutdown", ["/r", "/t", "0"]);
    }
    if (Platform.isLinux) {
      log.warning("Running Linux reboot command");
      Process.run("reboot", ["-h", "now"]);
    }
    if (Platform.isMacOS) {
      log.error("No MacOS reboot command");
    }
  }
}
