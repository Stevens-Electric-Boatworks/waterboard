// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;

// Project imports:
import '../services/ros_comms.dart';

class ROSConnectionStateWidget extends StatelessWidget {
  const ROSConnectionStateWidget({
    super.key,
    required this.value,
    required this.fontSize,
    required this.iconSize,
  });

  final ConnectionState value;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    if (value == ConnectionState.connected) {
      return Row(
        children: [
          Icon(Icons.wifi, color: Colors.green, size: iconSize),
          Text(
            " ROS Connected",
            style: style.merge(TextStyle(color: Colors.green)),
          ),
        ],
      );
    } else if (value == ConnectionState.noROSBridge) {
      return Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: iconSize),
          Text(
            " Stale Data",
            style: style.merge(TextStyle(color: Colors.orange)),
          ),
        ],
      );
    } else if (value == ConnectionState.noWebsocket) {
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
