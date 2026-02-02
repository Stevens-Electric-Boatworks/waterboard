import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
//https://github.com/RobotWebTools/rosbridge_suite/blob/ros2/ROSBRIDGE_PROTOCOL.md

class ROSComms {
  final Map<String, ValueNotifier<Map<String, dynamic>>> _subscriptions =
      {};
  WebSocketChannel? _channel;
  final ValueNotifier<ConnectionState> _connectionState = ValueNotifier(ConnectionState.unknown);

  final List<String> _subscribedTopics = [];
  Timer? _websocketTimer;
  Timer? _rosbridgeTimer;

  int _last_rosbridge_msg = 0;


  ValueNotifier<ConnectionState> get connectionState => _connectionState;


  void startConnectionRoutine() async {
    if(_websocketTimer != null) {
    }
    _websocketTimer?.cancel();
    _websocketTimer = Timer(Duration(seconds: 1), _websocketTimerTick);
    _connectionState.value = ConnectionState.noWebsocket;
  }

  Future<void> _websocketTimerTick() async {
    try {
      if(_channel?.closeCode != null) {
        print("Socket Closed");
        _rosbridgeTimer?.cancel();
        _connectionState.value = ConnectionState.noWebsocket;
      }
      if (_connectionState.value == ConnectionState.noWebsocket || connectionState.value == ConnectionState.unknown) {
        await _connect();
      }
    } finally {
      _websocketTimer = Timer(Duration(seconds: 1), _websocketTimerTick);
    }
  }

  Future<void> _connect() async {
    print("Attempting connection to websocket.");
    var prefs = await SharedPreferences.getInstance();
    final wsUrl = Uri.parse('ws://${prefs.getString("websocket.ip") ?? "127.0.0.1"}:${prefs.getInt("websocket.port") ?? 9090}');
    _channel = WebSocketChannel.connect(wsUrl);
    try {
      await _channel!.ready;
    } on SocketException catch (e) {
      _connectionState.value = ConnectionState.noWebsocket;
      print(
        "Failed to connect to the socket: ${e.message}: ERROR_CODE: ${e.osError}",
      );
      return;
    } on WebSocketChannelException catch (e) {
      _connectionState.value = ConnectionState.noWebsocket;
      print("Failed to connect to the websocket channel: ${e.message}}");
      return;
    }
    print("Connected to the websocket!");

    _connectionState.value = ConnectionState.noROSBridge;

    _rosbridgeTimer?.cancel();
    _rosbridgeTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (DateTime.now().millisecondsSinceEpoch - _last_rosbridge_msg >= 1500) {
        _connectionState.value = ConnectionState.noROSBridge;
        _socket_send_subcriptions();
        print("ROS Bridge is detected as being offline.");
      }
    });

    print("Sending test message.");

    _socket_send_subcriptions();
    _channel?.stream.listen((message) {
      _last_rosbridge_msg = DateTime.now().millisecondsSinceEpoch;
      if(_connectionState.value != ConnectionState.connected) {
        _socket_send_subcriptions();
      }
      _connectionState.value = ConnectionState.connected;
      // print("STATE: ${_connectionState.value}");

      var msg = json.decode(message);
      if (msg["op"] == "publish") {
        if (_subscriptions.containsKey(msg["topic"])) {
          ValueNotifier notifier = _subscriptions[msg["topic"]]!;
          Map<String, dynamic> data = msg["msg"];
          if (data.isEmpty) return;
          notifier.value = data;

        }
      } else {
        print("Found unknown operation: ${msg["op"]}");
      }
    });

  }

  void reconnect() async {
    print("Reconnecting to websocket");
    _rosbridgeTimer?.cancel();
    _websocketTimer?.cancel();
    await _channel?.sink.close();
    startConnectionRoutine();
  }

  ValueNotifier<Map<String, dynamic>> subscribe(String topic) {
    var notifier = ValueNotifier<Map<String, dynamic>>({});
    if (_subscriptions.containsKey(topic)) {
      print("sending old value notifier for $topic");
      return _subscriptions[topic]!;
    }
    //subscribe to new topic
    _subscribedTopics.add(topic);
    _subscriptions[topic] = notifier;
    return notifier;
  }

  void _socket_send_subcriptions() {
    for(var topic in _subscribedTopics) {
      _channel?.sink.add(json.encode({"op": "subscribe", "topic": topic}));
    }
  }
}

enum ConnectionState { unknown, noWebsocket, noROSBridge, connected }
