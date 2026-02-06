import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

//https://github.com/RobotWebTools/rosbridge_suite/blob/ros2/ROSBRIDGE_PROTOCOL.md

class ROSBridge {
  final ROS _ros;
  final ValueNotifier<ROSConnectionState> _connectionState = ValueNotifier(ROSConnectionState.unknown);
  ROSBridge(this._ros);
  Timer? _websocketTimer;
  Timer? _rosBridgeTimer;
  WebSocketChannel? _channel;
  int _lastROSBridgeMsg = 0;

  Future<void> startConnectionLoop() async {
    if (_websocketTimer != null) {}
    _websocketTimer?.cancel();
    _connectionState.value = ROSConnectionState.noWebsocket;
    _websocketTimer = Timer(Duration(seconds: 1), _websocketTimerTick);
  }
  Future<void> _websocketTimerTick() async {
    try {
      if (_channel?.closeCode != null) {
        _rosBridgeTimer?.cancel();
        _connectionState.value = ROSConnectionState.noWebsocket;
      }
      if (_connectionState.value == ROSConnectionState.noWebsocket ||
          connectionState.value == ROSConnectionState.unknown) {
        await _attemptConnect();
      }
    } finally {
      _websocketTimer = Timer(Duration(seconds: 1), _websocketTimerTick);
    }
  }

  Future<void> _attemptConnect() async {
    var prefs = await SharedPreferences.getInstance();
    final wsUrl = Uri.parse(
      'ws://${prefs.getString("websocket.ip") ?? "127.0.0.1"}:${prefs.getInt("websocket.port") ?? 9090}',
    );
    _channel = WebSocketChannel.connect(wsUrl);
    try {
      await _channel!.ready;
    } on SocketException {
      _connectionState.value = ROSConnectionState.noWebsocket;
      return;
    } on WebSocketChannelException {
      _connectionState.value = ROSConnectionState.noWebsocket;
      return;
    }

    _connectionState.value = ROSConnectionState.staleData;

    _rosBridgeTimer?.cancel();
    _rosBridgeTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (DateTime.now().millisecondsSinceEpoch - _lastROSBridgeMsg >= 1500) {
        _connectionState.value = ROSConnectionState.staleData;
        _sendAllSubscriptions();
      }
    });
    _sendAllSubscriptions();
    _channel?.stream.listen((message) {
      _lastROSBridgeMsg = DateTime.now().millisecondsSinceEpoch;
      if (_connectionState.value != ROSConnectionState.connected) {
        _sendAllSubscriptions();
      }
      _connectionState.value = ROSConnectionState.connected;
      // print("STATE: ${_connectionState.value}");

      var msg = json.decode(message);
      if (msg["op"] == "publish") {
        _onDataReceive(msg["topic"], msg["msg"]);
      }
      else {

      }
    });
  }

  void reconnect() async {
    _rosBridgeTimer?.cancel();
    _websocketTimer?.cancel();
    await _channel?.sink.close();
    startConnectionLoop();
  }



  ValueNotifier<ROSConnectionState> get connectionState => _connectionState;

  void _onDataReceive(String topic, Map<String, dynamic> data) {
    _ros.propagateData(topic, data);
  }

  void _sendAllSubscriptions() {
    for (var sub in _ros.subs.values) {
      sendSubscription(sub);
    }
  }

  void sendSubscription(ROSSubscription sub) {
    _channel?.sink.add(json.encode({"op": "subscribe", "topic": sub.topic}));
  }
}