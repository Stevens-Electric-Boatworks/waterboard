// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/widgets/ros_listenable_widget.dart';

class ROSText extends StatefulWidget {
  final String subtext;
  final ValueNotifier<Map<String, dynamic>> notifier;
  final (String, Color) Function(Map<String, dynamic> json) valueBuilder;

  const ROSText({
    super.key,
    required this.subtext,
    required this.notifier,
    required this.valueBuilder,
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
      valueNotifier: widget.notifier,
      builder: (BuildContext context, Map<String, dynamic> json) {
        var val = widget.valueBuilder(json);
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
