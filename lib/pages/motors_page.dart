// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';

// Project imports:
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../widgets/ros_widgets/gauge.dart';
import '../widgets/ros_widgets/responsive_gauge.dart';

// Package imports:

class MotorsPageViewModel extends ChangeNotifier {
  final ROS ros;

  late ROSGaugeDataSource motorACurrent;
  late ROSGaugeDataSource motorAVoltage;
  late ROSGaugeDataSource motorARPM;
  late ROSGaugeDataSource motorATemp;
  late ROSTextDataSource motorAEnabled;

  late ROSGaugeDataSource motorBCurrent;
  late ROSGaugeDataSource motorBVoltage;
  late ROSGaugeDataSource motorBRPM;
  late ROSGaugeDataSource motorBTemp;
  late ROSTextDataSource motorBEnabled;

  MotorsPageViewModel({required this.ros});

  void init() {
    motorACurrent = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) => (json["current"] as double).toDouble(),
    );

    motorAVoltage = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) => (json["voltage"] as double).toDouble(),
    );

    motorARPM = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) => (json["rpm"] as num).toDouble(),
    );

    motorATemp = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) => (json["motor_temp"] as num).toDouble(),
    );
    motorBCurrent = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) => (json["current"] as double).toDouble(),
    );

    motorBVoltage = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) => (json["voltage"] as double).toDouble(),
    );

    motorBRPM = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) => (json["rpm"] as num).toDouble(),
    );

    motorBTemp = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) => (json["motor_temp"] as num).toDouble(),
    );

    motorAEnabled = ROSTextDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) {
        if (json["enabled"] as bool) {
          return ("ENABLED", Colors.green);
        } else {
          return ("DISABLED", Colors.red);
        }
      },
    );

    motorBEnabled = ROSTextDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) {
        if (json["enabled"] as bool) {
          return ("ENABLED", Colors.green);
        } else {
          return ("DISABLED", Colors.red);
        }
      },
    );
  }
}

class MotorsPage extends StatefulWidget {
  final MotorsPageViewModel model;

  const MotorsPage({super.key, required this.model});

  @override
  State<MotorsPage> createState() => _MotorsPageState();
}

class _MotorsPageState extends State<MotorsPage> {
  @override
  void initState() {
    super.initState();
    model.init();
    model.addListener(() => setState(() {}));
  }

  MotorsPageViewModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveGaugeGrid(
          columns: 4,
          gauges: [
            //MOTOR A

            // Motor Current
            ROSGaugeConfig(
              dataSource: model.motorACurrent,
              minimum: 0,
              maximum: 200,
              unitText: "A",
              title: "Motor A Current",
              ranges: [
                GaugeRange(startValue: 0, endValue: 80, color: Colors.green),
                GaugeRange(
                  startValue: 80,
                  endValue: 120,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 120,
                  endValue: 150,
                  color: Colors.red.shade400,
                ),
                GaugeRange(
                  startValue: 150,
                  endValue: 200,
                  color: const Color.fromRGBO(255, 0, 0, 1),
                ),
              ],
            ),

            // Motor Voltage
            ROSGaugeConfig(
              dataSource: model.motorAVoltage,
              minimum: 0,
              maximum: 90,
              unitText: "V",
              title: "Motor A Voltage",
              ranges: [
                GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                GaugeRange(
                  startValue: 50,
                  endValue: 70,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(startValue: 70, endValue: 90, color: Colors.red),
              ],
            ),

            // Motor RPM
            ROSGaugeConfig(
              dataSource: model.motorARPM,
              minimum: 0,
              maximum: 4000,
              unitText: "RPM",
              title: "Motor A RPM",
              ranges: [
                GaugeRange(startValue: 0, endValue: 2000, color: Colors.green),
                GaugeRange(
                  startValue: 2000,
                  endValue: 3000,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 3000,
                  endValue: 4000,
                  color: const Color.fromRGBO(255, 0, 0, 1),
                ),
              ],
            ),

            // Inlet Temp
            ROSGaugeConfig(
              dataSource: model.motorATemp,
              minimum: 0,
              maximum: 100,
              unitText: "°C",
              title: "Motor A Temp",
              ranges: [
                GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                GaugeRange(
                  startValue: 50,
                  endValue: 70,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 70,
                  endValue: 90,
                  color: Colors.red.shade500,
                ),
                GaugeRange(
                  startValue: 90,
                  endValue: 100,
                  color: const Color.fromRGBO(255, 0, 0, 1),
                ),
              ],
            ),

            //MOTOR B
            // Motor Current
            ROSGaugeConfig(
              dataSource: model.motorBCurrent,
              minimum: 0,
              maximum: 200,
              unitText: "A",
              title: "Motor B Current",
              ranges: [
                GaugeRange(startValue: 0, endValue: 80, color: Colors.green),
                GaugeRange(
                  startValue: 80,
                  endValue: 120,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 120,
                  endValue: 150,
                  color: Colors.red.shade400,
                ),
                GaugeRange(
                  startValue: 150,
                  endValue: 200,
                  color: const Color.fromRGBO(255, 0, 0, 1),
                ),
              ],
            ),

            // Motor Voltage
            ROSGaugeConfig(
              dataSource: model.motorBVoltage,
              minimum: 0,
              maximum: 90,
              unitText: "V",
              title: "Motor B Voltage",
              ranges: [
                GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                GaugeRange(
                  startValue: 50,
                  endValue: 70,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(startValue: 70, endValue: 90, color: Colors.red),
              ],
            ),

            // Motor Power
            ROSGaugeConfig(
              dataSource: model.motorBRPM,
              minimum: 0,
              maximum: 4000,
              unitText: "RPM",
              title: "Motor B RPM",
              ranges: [
                GaugeRange(startValue: 0, endValue: 2000, color: Colors.green),
                GaugeRange(
                  startValue: 2000,
                  endValue: 3000,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 3000,
                  endValue: 4000,
                  color: const Color.fromRGBO(255, 0, 0, 1),
                ),
              ],
            ),

            // Inlet Temp
            ROSGaugeConfig(
              dataSource: model.motorBTemp,
              minimum: 0,
              maximum: 100,
              unitText: "°C",
              title: "Motor B Temp",
              ranges: [
                GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                GaugeRange(
                  startValue: 50,
                  endValue: 70,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 70,
                  endValue: 90,
                  color: Colors.red.shade500,
                ),
                GaugeRange(
                  startValue: 90,
                  endValue: 100,
                  color: const Color.fromRGBO(255, 0, 0, 1),
                ),
              ],
            ),
          ],
        ),
        Row(
          spacing: 25,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ROSText(
              subtext: "Motor A",
              dataSource: model.motorAEnabled,
              subTextStyle: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              valueTextStyle: Theme.of(context).textTheme.headlineMedium,
            ),
            ROSText(
              subtext: "Motor B",
              dataSource: model.motorBEnabled,
              subTextStyle: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              valueTextStyle: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ],
    );
  }
}
