// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:clock/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Project imports:
import 'package:waterboard/pref_keys.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

//https://github.com/RobotWebTools/rosbridge_suite/blob/ros2/ROSBRIDGE_PROTOCOL.md

class ROSBridge {
  final ROS _ros;
  final Log _log;
  final SharedPreferences _preferences;
  final ValueNotifier<ROSConnectionState> _connectionState = ValueNotifier(
    ROSConnectionState.noWebsocket,
  );
  ROSBridge(this._ros, this._log, this._preferences);
  Timer? _websocketTimer;
  Timer? _rosBridgeTimer;
  WebSocketChannel? _channel;
  int _lastROSBridgeMsg = clock
      .now()
      .add(Duration(seconds: -2))
      .millisecondsSinceEpoch;
  bool _sinkClosed = true;

  //id, function to call on service call success
  final Map<String, Function(bool success, Map<String, dynamic> json)>
  _serviceCalls = {};

  Future<void> startConnectionLoop() async {
    _rosBridgeTimer?.cancel();
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
      if (_connectionState.value == ROSConnectionState.noWebsocket) {
        await _attemptConnect();
      }
    } finally {
      _websocketTimer = Timer(Duration(seconds: 1), _websocketTimerTick);
    }
  }

  Future<void> _attemptConnect() async {
    final wsUrl = Uri.parse(
      'ws://${_preferences.getString(PrefKeys.websocketIP) ?? Defaults.websocketIP}:${_preferences.getInt(PrefKeys.websocketPort) ?? Defaults.websocketPort}',
    );
    _log.info("[ROS] Connecting to $wsUrl");
    _channel = WebSocketChannel.connect(wsUrl);
    try {
      await _channel!.ready;
    } on SocketException {
      _log.error("[ROS] Socket error while connecting");
      _connectionState.value = ROSConnectionState.noWebsocket;
      return;
    } on WebSocketChannelException {
      _log.info("[ROS] WebsocketChannelException while connecting");
      _connectionState.value = ROSConnectionState.noWebsocket;
      return;
    }

    _connectionState.value = ROSConnectionState.staleData;
    _log.info("[ROS] Connected to Websocket!");
    _rosBridgeTimer?.cancel();
    _rosBridgeTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (DateTime.now().millisecondsSinceEpoch - _lastROSBridgeMsg >= 1500) {
        _log.info("[ROS] Stale data from ROSBridge");
        _connectionState.value = ROSConnectionState.staleData;
      }
    });
    _sinkClosed = false;
    _channel?.sink.done.onError((error, stackTrace) {
      _sinkClosed = true;
    });
    _channel?.sink.done.then((error) {
      _sinkClosed = true;
    });
    _channel?.stream.listen((message) {
      var msg = json.decode(message);
      if (msg["topic"] != '/rosout') {
        //ignore /rosout since it doesn't tell us any data about the state of ros, since rosbridge can send /rosout logs
        _lastROSBridgeMsg = DateTime.now().millisecondsSinceEpoch;
        if (_connectionState.value != ROSConnectionState.connected) {}
        _connectionState.value = ROSConnectionState.connected;
      }
      if (msg["op"] == "publish") {
        _onDataReceive(msg["topic"], msg["msg"]);
      } else if (msg["op"] == "service_response") {
        if (_serviceCalls.containsKey(msg["id"])) {
          if (!(msg["result"] as bool)) {
            _log.error("Service called failed because ${msg["values"]}");
            return;
          }
          _serviceCalls[msg["id"]]!(
            true,
            msg["values"] as Map<String, dynamic>,
          );
        } else {
          _log.error(
            "A random service call for '${msg["service"]}' was received, but ROSBridge is not tracking it...",
          );
        }
      } else {
        _log.warning("[ROS] Unknown message from ROSBridge: $msg");
      }
    });
  }

  void reconnect() async {
    _rosBridgeTimer?.cancel();
    _websocketTimer?.cancel();
    _channel?.sink.close();
    startConnectionLoop();
  }

  ValueNotifier<ROSConnectionState> get connectionState => _connectionState;

  DateTime get timeSinceLastMsg {
    if (_lastROSBridgeMsg == 0) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(_lastROSBridgeMsg);
  }

  void _onDataReceive(String topic, Map<String, dynamic> data) {
    _ros.propagateData(topic, data);
  }

  void sendSubscription(ROSSubscription sub) {
    if (_sinkClosed) return;
    _channel?.sink.add(json.encode({"op": "subscribe", "topic": sub.topic}));
  }

  void callService(
    String topic,
    Function(bool success, Map<String, dynamic> json) func,
  ) {
    String id = Random().nextInt(10000).toString();
    _serviceCalls[id] = func;

    _channel?.sink.add(
      json.encode({"op": "call_service", "service": topic, "id": id}),
    );
  }
}
