abstract class PrefKeys {
  static const String layoutLocked = "locked_layout";
  static const String websocketIP = "websocket_ip";
  static const String websocketPort = "websocket_port";
}

abstract class Defaults {
  static const bool layoutLocked = false;
  static const String websocketIP = "127.0.0.1";
  static const int websocketPort = 9090;
}
