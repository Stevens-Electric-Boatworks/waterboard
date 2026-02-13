class ConnectionDialogMessages {
  static const String websocketDisconnectTitle =
      "ROSBridge Websocket Disconnected";
  static const String websocketDisconnectBody =
      "The websocket was unable to be initialized to connect to ROSBridge, but nothing is known of the state of ROSBridge directly.\nIt is recommended to reboot the Raspberry Pi.";

  static const String staleDataTitle = "ROSBridge Data Stale";
  static const String staleDataBody =
      "The websocket is initialized, but there is stale data from ROSBridge. \nThis means that the ROS Control System is likely down.";
}
class ROSConnectionStateMessages {
  static const String rosConnected = " ROS Connected";
  static const String staleData = " Stale Data";
  static const String noWebsocket = " No ROSBridge Connection";

}
