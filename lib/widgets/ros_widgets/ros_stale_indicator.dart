// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class ROSStaleIndicator extends StatefulWidget {
  final ROSSubscription subscription;
  final TextStyle? textStyle;
  const ROSStaleIndicator({
    super.key,
    required this.subscription,
    required this.textStyle,
  });

  @override
  State<ROSStaleIndicator> createState() => _ROSStaleIndicatorState();
}

class _ROSStaleIndicatorState extends State<ROSStaleIndicator> {
  late TextStyle? textStyle;
  @override
  Widget build(BuildContext context) {
    textStyle = widget.textStyle;
    textStyle ??= Theme.of(context).textTheme.bodySmall;
    return ValueListenableBuilder(
      valueListenable: widget.subscription.isStale,
      builder: (context, value, child) {
        return _buildTextWidget(value);
      },
    );
  }

  Widget _buildTextWidget(bool stale) {
    if (!stale) return Container();
    return Chip(
      backgroundColor: Colors.red,
      label: Text(
        "Stale",
        style: textStyle?.merge(TextStyle(color: Colors.white)),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}
