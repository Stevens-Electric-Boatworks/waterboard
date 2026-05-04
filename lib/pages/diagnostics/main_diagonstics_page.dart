// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/appbars/diagonstics_page_appbar.dart';
import 'package:waterboard/widgets/waterboard_table_widget.dart';
import '../../schemas/cell_message_schema.dart';
import '../../widgets/ros_widgets/ros_cell_connection_widget.dart';
import '../page_utils.dart';

class MainDiagnosticsPageViewModel extends ChangeNotifier {
  bool _init = false;
  final Services services;
  late final ROSCellDataSource rosCellDataSource;

  MainDiagnosticsPageViewModel({required this.services});

  void init() {
    if (_init) return;
    rosCellDataSource = ROSCellDataSource(
      sub: services.ros.subscribe("/cell", staleDuration: 10_000),
      valueBuilder: (json) => CellMessageSchema.fromJson(json),
    );
    _init = true;
  }
}

class MainDiagnosticsPage extends StatefulWidget {
  final MainDiagnosticsPageViewModel model;

  const MainDiagnosticsPage({super.key, required this.model});

  @override
  State<MainDiagnosticsPage> createState() => _MainDiagnosticsPageState();
}

class _MainDiagnosticsPageState extends State<MainDiagnosticsPage> {
  MainDiagnosticsPageViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.init();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: DiagnosticsAppbar(
          services: model.services,
          rosCellDataSource: model.rosCellDataSource,
        ),
        body: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(flex: 9, child: _criticalData()),
            Expanded(flex: 1, child: _quickActions()),
            Expanded(flex: 8, child: _diagnosticButtons()),
          ],
        ),
      ),
    );
  }

  Widget _criticalData() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        spacing: 20,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response for 5.2s", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                ],
              ),
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response for 5.2s", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                ],
              ),
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response for 5.2s", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                ],
              ),
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy", Colors.green),
                  ("Healthy", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response", Colors.red.shade800),
                  ("Active", Colors.red.shade800),
                  ("Active", Colors.red.shade800),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response for 5.2s", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                ],
              ),
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response for 5.2s", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                ],
              ),
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (SDO 0.1s, PDO 0.04s)", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response for 5.2s", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                  ("Active Faults Detected", Colors.red.shade800),
                ],
              ),
              WaterboardTableWidget(
                title: "CAN Subsystem",
                labels: [
                  "CAN Interface",
                  "Motor A?",
                  "Motor B?",
                  "Cooling Temp?",
                  "BMS?",
                  "Motor A Fault?",
                  "Motor B Fault?",
                ],
                values: [
                  ("can", Colors.green),
                  ("Healthy", Colors.green),
                  ("Healthy", Colors.green),
                  ("Healthy (0.5s)", Colors.green),
                  ("No Response", Colors.red.shade800),
                  ("Active", Colors.red.shade800),
                  ("Active", Colors.red.shade800),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    Widget buildButton(String text, IconData icon, VoidCallback callback) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue.shade500,
          foregroundColor: Colors.white,
          textStyle: Theme.of(context).textTheme.titleMedium,
          padding: EdgeInsetsGeometry.all(12),
        ),
        onPressed: callback,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [Icon(icon), Text(text)],
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Stack(
          alignment: AlignmentGeometry.center,
          children: [
            Row(
              spacing: 8,
              children: [
                buildButton("Restart CAN", Icons.restart_alt, () {}),
                buildButton("CAN TX Flush", Icons.restart_alt, () {}),
                Spacer(),
                buildButton("GPS Send Cmds", Icons.gps_fixed, () {}),
                buildButton("Cell Reconfigure", Icons.cell_tower, () {}),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    padding: EdgeInsetsGeometry.all(12),
                  ),
                  onPressed: () async {
                    PageUtils.dangerConfirmDialog(
                      context,
                      "Shutdown System?",
                      "This will shutdown the host OS.",
                      () => {},
                      backgroundColor: Colors.red.shade100,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 15,
                    children: [Icon(Icons.warning), Text("Shutdown System")],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade300,
                    foregroundColor: Colors.white,
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    padding: EdgeInsetsGeometry.all(12),
                  ),
                  onPressed: () async {
                    PageUtils.dangerConfirmDialog(
                      context,
                      "Reboot System?",
                      "This will reboot the host OS.",
                      () => {},
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 15,
                    children: [Icon(Icons.warning), Text("Reboot System")],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagnosticButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        spacing: 16,
        children: [
          Expanded(
            child: Row(
              spacing: 20,
              children: [
                _createDiagnosticButton(
                  () => {},
                  "System Stats",
                  "CPU, RAM, Disk, Network Usage, Temperature",
                  Icons.computer,
                ),
                _createDiagnosticButton(
                  () => {},
                  "GNSS",
                  "Satellites, GNSS Status, Longitude, Latitude",
                  Icons.satellite_alt,
                ),
                _createDiagnosticButton(
                  () => {},
                  "Internet",
                  "Modem State, Shore Connectivity, Reconfig Actions",
                  Icons.cell_tower,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              spacing: 20,
              children: [
                _createDiagnosticButton(
                  () => {},
                  "ROS Backend",
                  "CPU, RAM, Disk, Network Usage, Temperature",
                  Icons.rocket,
                ),
                _createDiagnosticButton(
                  () => {},
                  "Tidal Logs",
                  "CPU, RAM, Disk, Network Usage, Temperature",
                  Icons.edit_document,
                ),
                _createDiagnosticButton(
                  () => {},
                  "Tidal Faults",
                  "CPU, RAM, Disk, Network Usage, Temperature",
                  Icons.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createDiagnosticButton(
    Function onPressed,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: () {},
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 5,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: Colors.black),
                  ),
                ],
              ),
            ),
            Center(
              child: Icon(icon, size: 152, color: Colors.black.withAlpha(15)),
            ),
          ],
        ),
      ),
    );
  }
}
