// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/ros_logs_widget.dart';

class LogsPageViewModel extends ChangeNotifier {
  final ROS ros;
  late final LogsWidgetViewModel logsWidgetModel;

  LogsPageViewModel({required this.ros});
  void init() {
    logsWidgetModel = LogsWidgetViewModel(ros.subscribe("/rosout"));
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
      child: LogsWidget(model: model.logsWidgetModel),
    );
  }
}
