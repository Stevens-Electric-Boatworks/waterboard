// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/widgets/ros_widgets/responsive_gauge.dart';
import '../services/ros_comms/ros.dart';
import '../settings/settings_dialog.dart';

class ResponsiveGaugeGrid extends StatelessWidget {
  final List<ROSGaugeConfig> gauges;
  final int columns;

  const ResponsiveGaugeGrid({
    super.key,
    required this.gauges,
    this.columns = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = (gauges.length / columns).ceil();
        final rowHeight = constraints.maxHeight / rows;

        final maxWidthBased = constraints.maxWidth / columns;
        final gaugeSize = rowHeight < maxWidthBased
            ? rowHeight * 0.95
            : maxWidthBased * 0.95;

        final thickness = (gaugeSize * 0.1).clamp(8.0, 80.0);

        List<Widget> buildRows() {
          List<Widget> result = [];

          for (int row = 0; row < rows; row++) {
            final start = row * columns;
            final end = (start + columns).clamp(0, gauges.length);

            final rowGauges = gauges.sublist(start, end);

            result.add(
              SizedBox(
                height: rowHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rowGauges
                      .map(
                        (config) => SizedBox(
                          width: gaugeSize,
                          height: gaugeSize,
                          child: ResponsiveROSGauge(
                            config: config,
                            thickness: thickness,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          }

          return result;
        }

        return Column(children: buildRows());
      },
    );
  }
}

class PageUtils {
  static void showSettingsDialog(BuildContext context, ROS ros) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Waterboard Settings"),
          content: SettingsDialog(ros: ros),
        );
      },
    );
  }
}

// Source - https://stackoverflow.com/a/63574708
// Posted by O Thạnh Ldt

class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    /// Dont't forget this
    super.build(context);

    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
