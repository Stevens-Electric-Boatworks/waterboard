// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';

// Project imports:
import 'package:waterboard/widgets/ros_widgets/gauge.dart';

class ROSGaugeConfig {
  final ROSGaugeDataSource dataSource;
  final double minimum;
  final double maximum;
  final String unitText;
  final String title;
  final List<GaugeRange> ranges;

  const ROSGaugeConfig({
    required this.dataSource,
    required this.minimum,
    required this.maximum,
    required this.unitText,
    required this.title,
    required this.ranges,
  });
}

class ResponsiveROSGauge extends StatelessWidget {
  final ROSGaugeConfig config;
  final double thickness;

  const ResponsiveROSGauge({
    super.key,
    required this.config,
    required this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    return ROSGauge(
      thickness: thickness,
      dataSource: config.dataSource,
      minimum: config.minimum,
      maximum: config.maximum,
      unitText: config.unitText,
      title: config.title,
      ranges: config.ranges,
    );
  }
}
