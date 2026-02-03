// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';

class Gauge extends StatelessWidget {
  final double minimum;
  final double maximum;
  final double value;
  final String annotationText;
  final String unitText;
  final List<GaugeRange> ranges;
  final double thickness;
  final double positionFactor;
  final String title;
  final int backgroundOpacity;
  const Gauge({
    super.key,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.annotationText,
    required this.ranges,
    this.thickness = 35,
    this.positionFactor = 0.69,
    this.backgroundOpacity = 50,
    required this.title,
    required this.unitText,
  });

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      enableLoadingAnimation: true,
      backgroundColor: Colors.white,
      animationDuration: 2000,
      axes: [
        RadialAxis(
          axisLineStyle: AxisLineStyle(
            thickness: thickness,
            color: Colors.white,
            cornerStyle: CornerStyle.bothCurve,
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
              enableAnimation: true,
            ),
            RangePointer(
              width: thickness,
              value: maximum,
              enableAnimation: true,
              gradient: _buildGradient(),
            ),
            RangePointer(
              color: _getRangeColor(value),
              width: thickness,
              value: value,

              enableAnimation: true,
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
              widget: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      annotationText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      unitText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
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
