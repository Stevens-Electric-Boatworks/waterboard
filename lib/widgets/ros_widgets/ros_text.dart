// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/widgets/ros_listenable_widget.dart';

class ROSTextDataSource {
  final ROSSubscription sub;
  final (String, Color) Function(Map<String, dynamic> json) valueBuilder;

  ROSTextDataSource({required this.sub, required this.valueBuilder});
}

class ROSText extends StatefulWidget {
  final String subtext;
  final ROSTextDataSource dataSource;
  final TextStyle? valueTextStyle;
  final TextStyle? subTextStyle;
  const ROSText({
    super.key,
    required this.subtext,
    required this.dataSource,
    this.valueTextStyle,
    this.subTextStyle,
  });

  @override
  State<ROSText> createState() => _ROSTextState();
}

class _ROSTextState extends State<ROSText> {
  late TextStyle? valueTextStyle;
  late TextStyle? subTextStyle;
  @override
  Widget build(BuildContext context) {
    valueTextStyle = widget.valueTextStyle;
    subTextStyle = widget.subTextStyle;

    valueTextStyle ??= Theme.of(context).textTheme.displaySmall;
    subTextStyle ??= Theme.of(context).textTheme.titleLarge;
    return ROSListenable(
      valueNotifier: widget.dataSource.sub.notifier,
      builder: (BuildContext context, Map<String, dynamic> json) {
        var val = widget.dataSource.valueBuilder(json);
        return _buildTextWidget(val.$1, val.$2);
      },
      noDataBuilder: (BuildContext context) {
        return _buildTextWidget("N/A", Colors.grey);
      },
    );
  }

  Widget _buildTextWidget(String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: valueTextStyle?.merge(TextStyle(color: color)),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        SizedBox(height: 10),
        Text(widget.subtext, style: subTextStyle),
      ],
    );
  }
}
