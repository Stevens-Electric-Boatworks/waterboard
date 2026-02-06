// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:waterboard/services/ros_comms/ros.dart';

// Project imports:
import '../services/ros_comms.dart';

class ROSConnectionStateWidget extends StatelessWidget {
  const ROSConnectionStateWidget({
    super.key,
    required this.value,
    required this.fontSize,
    required this.iconSize,
  });

  final ROSConnectionState value;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    if (value == ROSConnectionState.connected) {
      return Row(
        children: [
          Icon(Icons.wifi, color: Colors.green, size: iconSize),
          Text(
            " Connected",
            style: style.merge(TextStyle(color: Colors.green)),
          ),
        ],
      );
    } else if (value == ROSConnectionState.staleData) {
      return Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: iconSize),
          Text(
            " Stale Data",
            style: style.merge(TextStyle(color: Colors.orange)),
          ),
        ],
      );
    } else if (value == ROSConnectionState.noWebsocket) {
      return Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red, size: iconSize),
          Text(
            " No ROSBridge Connection",
            style: style.merge(TextStyle(color: Colors.red)),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.question_mark, size: iconSize),
          Text("Unknown", style: style),
        ],
      );
    }
  }
}
