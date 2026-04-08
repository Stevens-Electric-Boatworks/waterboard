// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;

// Package imports:
import 'package:syncfusion_flutter_gauges/gauges.dart';

// Project imports:
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/widgets/ros_widgets/responsive_gauge.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';
import '../services/ros_comms/ros.dart';
import '../widgets/ros_widgets/gauge.dart';

class MainDriverPageViewModel extends ChangeNotifier {
  final ROS ros;

  late ROSGaugeDataSource bmsCurrent;
  late ROSGaugeDataSource motorARPM;
  late ROSGaugeDataSource motorATemp;
  late ROSGaugeDataSource motorBTemp;
  late ROSGaugeDataSource speed;
  late ROSTextDataSource motorACurrent;
  late ROSTextDataSource motorBCurrent;

  MainDriverPageViewModel({required this.ros});
  void init() {
    bmsCurrent = ROSGaugeDataSource(
      sub: ros.subscribe("/bms/pack_summary"),
      valueBuilder: (json) => (json["pack_current_raw"] as double),
    );

    motorATemp = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) => (json["motor_temp"] as double),
    );

    motorBTemp = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) => (json["motor_temp"] as double),
    );

    motorARPM = ROSGaugeDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) => (json["rpm"] as int).toDouble().abs(),
    );

    speed = ROSGaugeDataSource(
      sub: ros.subscribe("/motion/vtg", staleDuration: 4500),
      valueBuilder: (json) =>
          (json["speed"] as double).round().toDouble().abs(),
    );

    motorACurrent = ROSTextDataSource(
      sub: ros.subscribe("/motors/motorA"),
      valueBuilder: (json) {
        return ("${json["current"]} A", Colors.black);
      },
    );
    motorBCurrent = ROSTextDataSource(
      sub: ros.subscribe("/motors/motorB"),
      valueBuilder: (json) {
        return ("${json["current"]} A", Colors.black);
      },
    );
  }
}

class MainDriverPage extends StatefulWidget {
  final MainDriverPageViewModel model;

  const MainDriverPage({super.key, required this.model});

  @override
  State<MainDriverPage> createState() => _MainDriverPageState();
}

class _MainDriverPageState extends State<MainDriverPage> {
  @override
  void initState() {
    super.initState();
    model.init();
    model.addListener(() => setState(() {}));
  }

  MainDriverPageViewModel get model => widget.model;

  bool get isOnMainPage {
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ResponsiveROSGauge(
                  config: ROSGaugeConfig(
                    dataSource: model.bmsCurrent,
                    minimum: 0,
                    maximum: 200,
                    unitText: "A",
                    title: "BMS Current",
                    ranges: [
                      GaugeRange(
                        startValue: 0,
                        endValue: 80,
                        color: Colors.green,
                      ),
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
                  thickness: 100,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 16,
                  children: [
                    Expanded(
                      child: PageUtils.buildWidgetBackground(
                        color: Colors.grey.shade300,
                        ROSText(
                          subtext: "Motor A Current",
                          dataSource: model.motorACurrent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageUtils.buildWidgetBackground(
                        color: Colors.grey.shade300,
                        ROSText(
                          subtext: "Motor B Current",
                          dataSource: model.motorBCurrent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ResponsiveGaugeGrid(
          columns: 2,
          gauges: [
            ROSGaugeConfig(
              dataSource: model.speed,
              minimum: 0,
              maximum: 25,
              unitText: "kts",
              title: "Speed",
              ranges: [
                GaugeRange(
                  startValue: 0,
                  endValue: 10,
                  color: Colors.red.shade400,
                ),
                GaugeRange(
                  startValue: 10,
                  endValue: 15,
                  color: Colors.yellow.shade400,
                ),
                GaugeRange(startValue: 15, endValue: 25, color: Colors.green),
              ],
            ),
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
            ROSGaugeConfig(
              dataSource: model.motorARPM,
              minimum: 0,
              maximum: 6000,
              unitText: "RPM",
              title: "Motor RPM",
              ranges: [
                GaugeRange(startValue: 0, endValue: 2000, color: Colors.green),
                GaugeRange(
                  startValue: 2000,
                  endValue: 4000,
                  color: Colors.yellow.shade600,
                ),
                GaugeRange(
                  startValue: 4000,
                  endValue: 6000,
                  color: Colors.red.shade500,
                ),
              ],
            ),
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
      ],
    );
  }
}
