// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:syncfusion_flutter_charts/charts.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/widgets/ros_widgets/ros_listenable_widget.dart';

class GraphDataPoint {
  final DateTime time;
  final double value;

  GraphDataPoint({required this.time, required this.value});
}

class ROSGraphDataSource {
  final ROSSubscription subscription;
  final List<GraphDataPoint> Function(Map<String, dynamic> json) valueBuilder;

  ROSGraphDataSource({required this.subscription, required this.valueBuilder});
}

class ROSGraphWidget extends StatelessWidget {
  final String title;
  final String unit;
  final ROSGraphDataSource dataSource;

  const ROSGraphWidget({
    super.key,
    required this.title,
    required this.unit,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    return ROSListenable(
      subscription: dataSource.subscription,
      builder: (context, value) {
        return _buildGraph(dataSource.valueBuilder(value));
      },
      noDataBuilder: (p0) {
        return _buildGraph([]);
      },
    );
  }

  Widget _buildGraph(List<GraphDataPoint> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 20,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: SfCartesianChart(
                margin: EdgeInsets.only(right: 16),
                series: _getChartData(data),
                crosshairBehavior: CrosshairBehavior(
                  enable: true,
                  activationMode: ActivationMode.singleTap,
                  shouldAlwaysShow: true,
                  lineColor: Colors.black,
                ),
                plotAreaBackgroundColor: Colors.grey.shade300,
                plotAreaBorderColor: Colors.black,
                primaryXAxis: NumericAxis(
                  interval: 10,
                  minimum: 0,
                  maximum: 30,
                  isInversed: true,
                  decimalPlaces: 0,
                  labelFormat: 'T+{value}s',
                  majorGridLines: MajorGridLines(color: Colors.black),
                  majorTickLines: MajorTickLines(color: Colors.black),
                  axisLabelFormatter: (axisLabelRenderArgs) => ChartAxisLabel(
                    axisLabelRenderArgs.text,
                    Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  labelFormat: '{value}$unit',
                  majorTickLines: MajorTickLines(color: Colors.black),
                  majorGridLines: MajorGridLines(color: Colors.black),
                  axisLabelFormatter: (axisLabelRenderArgs) => ChartAxisLabel(
                    axisLabelRenderArgs.text,
                    Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FastLineSeries<GraphDataPoint, double>> _getChartData(
    List<GraphDataPoint> sourceData,
  ) {
    return <FastLineSeries<GraphDataPoint, double>>[
      FastLineSeries<GraphDataPoint, double>(
        animationDuration: 0.0,
        animationDelay: 0.0,
        sortingOrder: SortingOrder.ascending,
        color: Colors.blue,
        width: 4,
        dataSource: sourceData,
        xValueMapper: (value, index) {
          return (DateTime.now().difference(value.time).inSeconds).toDouble();
        },
        yValueMapper: (value, index) {
          return value.value;
        },
        markerSettings: MarkerSettings(
          isVisible: true,
          shape: DataMarkerType.diamond,
        ),
        enableTooltip: true,
      ),
    ];
  }
}
