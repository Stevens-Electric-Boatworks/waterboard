// Flutter imports:
import 'package:flutter/material.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

// Project imports:
import 'package:waterboard/widgets/ros_listenable_widget.dart';

class ROSTextDataSource {
  final ROSSubscription sub;
  final (String, Color) Function(Map<String, dynamic> json) valueBuilder;

  ROSTextDataSource({required this.sub, required this.valueBuilder});
}
class ROSText extends StatefulWidget {
  final String subtext;
  final ROSTextDataSource dataSource;

  const ROSText({
    super.key,
    required this.subtext,
    required this.dataSource
  });

  @override
  State<ROSText> createState() => _ROSTextState();
}

class _ROSTextState extends State<ROSText> {
  TextStyle? valueTextStyle;
  TextStyle? subTextStyle;
  @override
  Widget build(BuildContext context) {
    valueTextStyle ??= Theme.of(context).textTheme.displaySmall;
    subTextStyle ??= Theme.of(context).textTheme.titleLarge;
    return ROSListenable(
      valueNotifier: widget.dataSource.sub.notifier,
      builder: (BuildContext context, Map<String, dynamic> json) {
        var val = widget.dataSource.valueBuilder(json);
        return _buildTextWidget(val.$1, val.$2);
      },
      noDataBuilder: (BuildContext context) {
        return _buildTextWidget("Unknown", Colors.grey);
      },
    );
  }

  Widget _buildTextWidget(String value, Color color) {
    return Column(
      children: [
        Text(value, style: valueTextStyle?.merge(TextStyle(color: color))),
        SizedBox(height: 10),
        Text(widget.subtext, style: subTextStyle),
      ],
    );
  }
}
