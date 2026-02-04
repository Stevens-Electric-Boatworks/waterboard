// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:waterboard/widgets/ros_listenable_widget.dart';

class ROSGauge extends StatelessWidget {
  final double minimum;
  final double maximum;
  final ValueNotifier<Map<String, dynamic>> notifier;
  final double Function(Map<String, dynamic> json) valueBuilder;
  final String unitText;
  final List<GaugeRange> ranges;
  final double thickness;
  final double positionFactor;
  final String title;
  final int backgroundOpacity;

  const ROSGauge({
    super.key,
    required this.valueBuilder,
    required this.minimum,
    required this.maximum,
    required this.ranges,
    this.thickness = 40,
    this.positionFactor = 0.65,
    this.backgroundOpacity = 75,
    required this.title,
    required this.unitText,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return ROSListenable(
      valueNotifier: notifier,
      builder: (BuildContext context, Map<String, dynamic> json) {
        double value = valueBuilder(json);
        return _buildGauge(value, true);
      },
      noDataBuilder: (BuildContext context) {
        return _buildGauge(minimum, false, hasData: false);
      },
    );
  }

  SfRadialGauge _buildGauge(
    double value,
    bool enableAnimation, {
    bool hasData = true,
  }) {
    return SfRadialGauge(
      enableLoadingAnimation: enableAnimation,
      backgroundColor: Colors.transparent,
      animationDuration: 2000,
      axes: [
        RadialAxis(
          axisLineStyle: AxisLineStyle(
            thickness: thickness,
            color: Colors.white,
          ),
          minimum: minimum,
          maximum: maximum,
          // ranges: ranges,
          pointers: [
            NeedlePointer(
              value: value,
              needleEndWidth: 5,
              knobStyle: KnobStyle(knobRadius: 0.05),
              needleColor: Colors.grey.withAlpha(150),
              enableAnimation: enableAnimation,
            ),
            RangePointer(
              width: thickness,
              value: maximum,
              enableAnimation: enableAnimation,
              gradient: _buildGradient(),
            ),
            RangePointer(
              color: _getRangeColor(value),
              width: thickness,
              value: value,
              enableAnimation: enableAnimation,
            ),
          ],
          annotations: [
            //Title
            GaugeAnnotation(
              widget: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              angle: 90,
              positionFactor: 0.4,
            ),
            //Current Value
            GaugeAnnotation(
              widget: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasData ? "$value" : "Unknown",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: hasData ? 30 : 24,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    unitText,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: positionFactor,
            ),
          ],
          axisLabelStyle: GaugeTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color? _getRangeColor(double value) {
    for (final range in ranges) {
      if (value >= range.startValue && value <= range.endValue) {
        return range.color ?? Colors.black;
      }
    }
    // Fallback if value is outside all ranges
    return ranges.last.color;
  }

  SweepGradient _buildGradient() {
    if (ranges.isEmpty) {
      return const SweepGradient(colors: [Colors.black]);
    }

    final colors = <Color>[];
    final stops = <double>[];

    for (final range in ranges) {
      final start = ((range.startValue - minimum) / (maximum - minimum)).clamp(
        0.0,
        1.0,
      );
      final end = ((range.endValue - minimum) / (maximum - minimum)).clamp(
        0.0,
        1.0,
      );

      final color = range.color ?? Colors.black;

      colors.add(color.withAlpha(backgroundOpacity));
      stops.add(start);

      colors.add(color.withAlpha(backgroundOpacity));
      stops.add(end);
    }

    return SweepGradient(colors: colors, stops: stops);
  }
}
