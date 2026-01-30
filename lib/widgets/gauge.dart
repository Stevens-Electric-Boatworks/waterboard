import 'package:flutter/material.dart';
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
  const Gauge({super.key, required this.value, required this.minimum, required this.maximum, required this.annotationText, required this.ranges, this.thickness = 35, this.positionFactor = 0.7, required this.title, required this.unitText});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      enableLoadingAnimation: true,
      animationDuration: 2000,
      axes: [
        RadialAxis(
          axisLineStyle: AxisLineStyle(
            thickness: thickness,
          ),
          minimum: minimum,
          maximum: maximum,
          ranges: ranges,
          pointers: [
            NeedlePointer(
              value: value,
              needleEndWidth: 5,
              knobStyle: KnobStyle(knobRadius: 0.05),
              enableAnimation: true,
            ),
            RangePointer(
              color: _getRangeColor(value),
              pointerOffset: 10,
              width: thickness-10,
              value: value,
              enableAnimation: true,
            )
          ],
          annotations: [
            //Title
            GaugeAnnotation(
              widget: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              angle: 90,
              positionFactor: 0.35,
            ),
            //Current Value
            GaugeAnnotation(
              widget: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(5))
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
                    SizedBox(width: 5,),
                    Text(
                      unitText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                )
              ),
              angle: 90,
              positionFactor: positionFactor,
            ),
          ],
          axisLabelStyle: GaugeTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold
          ),
          canScaleToFit: true,
        ),
      ],
    );
  }
  Color _getRangeColor(double value) {
    for (final range in ranges) {
      if (value >= range.startValue && value <= range.endValue) {
        return range.color ?? Colors.black;
      }
    }
    // Fallback if value is outside all ranges
    return Colors.black;
  }


}
