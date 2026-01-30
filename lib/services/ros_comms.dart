import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
//https://github.com/RobotWebTools/rosbridge_suite/blob/ros2/ROSBRIDGE_PROTOCOL.md

class ROSComms {
  final Map<String, List<ValueNotifier<Map<String, dynamic>>>> _subscriptions = {};
  late var _channel;
  void connect_to_websocket() async {
    print("Attempting connection to websocket.");
    final wsUrl = Uri.parse('ws://127.0.0.1:9090');
    _channel = WebSocketChannel.connect(wsUrl);

    await _channel.ready;
    _channel.stream.listen((message) {
      var msg = json.decode(message);
      if(msg["op"] == "publish") {
        if(_subscriptions.containsKey(msg["topic"])) {
          for (var notifier in _subscriptions[msg["topic"]]!) {
            Map<String, dynamic> data = msg["msg"];
            if(data.isEmpty) continue;
            notifier.value = data;
          }
        }
      }
      else {
        print("Found unknown operation: ${msg["op"]}");
      }
    });
    print("Connected to the websocket!");
  }

  ValueNotifier<Map<String, dynamic>> subscribe(String topic) {
    var notifier = ValueNotifier<Map<String, dynamic>>({});
    if(_subscriptions.containsKey(topic)) {
      _subscriptions[topic]!.add(notifier);
      return notifier;
    }
    //subscribe to new topic
    _channel.sink.add(json.encode(
        {
          "op": "subscribe",
          "topic": topic
        }
    ));
    _subscriptions[topic] = [notifier];
    return notifier;
  }
}