// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/ros_logs_widget.dart';
import 'package:waterboard/widgets/waterboard_logs_widget.dart';

class LogsPageViewModel extends ChangeNotifier {
  final ROS ros;
  late final LogsWidgetViewModel logsWidgetModel;
  late final WaterboardLogsWidgetViewModel waterboardLogsWidgetViewModel;

  LogsPageViewModel({required this.ros});
  void init() {
    logsWidgetModel = LogsWidgetViewModel(ros.subscribe("/rosout"));
    logsWidgetModel.init();

    waterboardLogsWidgetViewModel = WaterboardLogsWidgetViewModel();
    waterboardLogsWidgetViewModel.init();
  }
}

class LogsPage extends StatefulWidget {
  final LogsPageViewModel model;
  const LogsPage({super.key, required this.model});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  LogsPageViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.init();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            flex: 3,
            child: Column(
              children: [
                Text(
                  "ROS System Logs",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Flexible(
                  flex: 3,
                  child: ROSLogsWidget(model: model.logsWidgetModel),
                ),
              ],
            ),
          ),
          SizedBox(width: 5),
          Flexible(
            flex: 2,
            child: Column(
              children: [
                Text(
                  "Waterboard Logs",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Flexible(
                  flex: 2,
                  child: WaterboardLogsWidget(
                    model: model.waterboardLogsWidgetViewModel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
