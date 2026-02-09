// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/waterboard_colors.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';

class RadiosPage extends StatefulWidget {
  final ROS ros;
  const RadiosPage({super.key, required this.ros});

  @override
  State<RadiosPage> createState() => _RadiosPageState();
}

class _RadiosPageState extends State<RadiosPage> {
  var internetConnectionChecker = InternetConnection.createInstance(
    customCheckOptions: [
      InternetCheckOption(uri: Uri.parse('shore.stevenseboat.org')),
    ],
  );
  final info = NetworkInfo();
  late Stream<InternetStatus> _subscription;
  final ValueNotifier<String?> _ssid = ValueNotifier(null);
  final ValueNotifier<String?> _ipAddress = ValueNotifier(null);

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _subscription = internetConnectionChecker.onStatusChange;
    _timer = Timer.periodic(Duration(seconds: 1), (_) => updateNetworkInfo());
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _ssid.dispose();
    _ipAddress.dispose();
  }

  Future<void> updateNetworkInfo() async {
    _ssid.value = await info.getWifiName();
    _ipAddress.value = await info.getWifiIP();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
            decoration: BoxDecoration(
              color: WaterboardColors.containerBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 20,
              children: [
                Text(
                  "Internet and Cellular",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                ValueListenableBuilder(
                  valueListenable: _ipAddress,
                  builder: (context, value, child) {
                    if (value == null) {
                      return _buildText("Not Connected", "IP Address");
                    }
                    return _buildText(value, "IP Address");
                  },
                ),
                StreamBuilder(
                  stream: _subscription,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildText(
                        "Unreachable",
                        "Shore Reachable?",
                        color: Colors.red,
                      );
                    }
                    if (snapshot.data == InternetStatus.connected) {
                      return _buildText(
                        "Reachable",
                        "Shore Reachable?",
                        color: Colors.green,
                      );
                    }
                    return _buildText(
                      "Unreachable",
                      "Shore Reachable?",
                      color: Colors.red,
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _ssid,
                  builder: (context, value, child) {
                    if (value == null) {
                      return _buildText("Not Connected", "WiFi SSID");
                    }
                    return _buildText(value, "WiFi SSID");
                  },
                ),
                //Currently not implemented
                _buildWidgetBackground(
                  ROSText(
                    notifier: widget.ros.subscribe("/cell/data").value,
                    valueBuilder: (json) {
                      return (json["cell_strength"].toString(), Colors.black);
                    },
                    subtext: "Cell Strength",
                  ),
                ),
                _buildText(
                  "shore.stevenseboat.org",
                  "Shore URL",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(
    String value,
    String subtitle, {
    Color color = Colors.black,
    TextStyle? style,
  }) {
    style ??= Theme.of(context).textTheme.displaySmall;
    return _buildWidgetBackground(
      Column(
        children: [
          Text(value, style: style?.merge(TextStyle(color: color))),
          SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildWidgetBackground(Widget inside, {double width = 275}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: WaterboardColors.containerForeground,
      ),
      child: SizedBox(width: width, child: inside),
    );
  }
}
