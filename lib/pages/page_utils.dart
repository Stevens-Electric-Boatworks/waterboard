// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/delayed_button.dart';
import 'package:waterboard/widgets/ros_widgets/responsive_gauge.dart';
import '../settings/settings_dialog.dart';
import '../waterboard_colors.dart';

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

        final thickness = (gaugeSize * 0.12).clamp(8.0, 90.0);

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
  static void showSettingsDialog(
    BuildContext context,
    Services services,
    Function() onSettingsChange,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Waterboard Settings"),
          content: SettingsDialog(
            services: services,
            onSettingsChanged: onSettingsChange,
          ),
        );
      },
    );
  }

  static Widget buildWidgetBackground(
    Widget inside, {
    double verticalPadding = 8,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: WaterboardColors.containerForeground,
      ),
      child: inside,
    );
  }

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: WaterboardColors.containerBackground,
      borderRadius: BorderRadius.circular(16),
    );
  }

  static Widget buildText(
    BuildContext context,
    String value,
    String subtitle, {
    Color color = Colors.black,
    TextStyle? style,
  }) {
    style ??= Theme.of(context).textTheme.displaySmall;
    return PageUtils.buildWidgetBackground(
      Column(
        children: [
          Text(
            value,
            style: style?.merge(TextStyle(color: color)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  static void dangerConfirmDialog(
    BuildContext context,
    String title,
    String body,
    Function onConfirm, {
    Color backgroundColor = Colors.white,
  }) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Center(
          child: Text("DANGER\n$title", textAlign: TextAlign.center),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(body)],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          DelayedWidget(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('⚠️ CONFIRM ⚠️'),
            ),
          ),
        ],
      ),
    );
    if (confirm != null && confirm) {
      onConfirm();
    }
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
