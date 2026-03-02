// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_map/flutter_map.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

// Project imports:
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/waterboard_colors.dart';
import 'package:waterboard/widgets/ros_widgets/marine_compass.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';

class RadiosPageViewModel extends ChangeNotifier {
  final Services services;
  final MapController mapController = MapController();

  late final Stream<InternetStatus> internetStatusStream;

  // ROS subscriptions
  late final ROSSubscription gpsSub;
  late final ROSSubscription vtgSub;
  late final ROSTextDataSource gpsLat;
  late final ROSTextDataSource gpsLon;
  late final ROSTextDataSource sv;
  late final ROSTextDataSource vtg;
  late final ROSTextDataSource alt;
  late final ROSTextDataSource climb;
  late final ROSTextDataSource cell;
  late final ROSCompassDataSource compass;

  double lat = 0;
  double lon = 0;
  double track = -1;

  bool mapReady = false;
  PmTilesVectorTileProvider? provider;

  RadiosPageViewModel({required this.services}) {
    gpsSub = ros.subscribe("/motion/gps");
    gpsLat = ROSTextDataSource(
      sub: gpsSub,
      valueBuilder: (json) =>
          ((json["lat"] as double).toStringAsPrecision(12), Colors.black),
    );
    gpsLon = ROSTextDataSource(
      sub: gpsSub,
      valueBuilder: (json) =>
          ((json["lon"] as double).toStringAsPrecision(12), Colors.black),
    );
    sv = ROSTextDataSource(
      sub: ros.subscribe("/motion/sv"),
      valueBuilder: (json) => ("${json["sats"]}", Colors.black),
    );
    vtgSub = ros.subscribe("/motion/vtg");
    vtg = ROSTextDataSource(
      sub: vtgSub,
      valueBuilder: (json) =>
          ((json["speed"] as double).toStringAsPrecision(2), Colors.black),
    );
    alt = ROSTextDataSource(
      sub: ros.subscribe("/motion/gps/alt"),
      valueBuilder: (json) =>
          ((json["alt"] as double).toStringAsPrecision(7), Colors.black),
    );
    climb = ROSTextDataSource(
      sub: ros.subscribe("/motion/gps/climb"),
      valueBuilder: (json) =>
          ((json["climb"] as double).toStringAsPrecision(2), Colors.black),
    );
    cell = ROSTextDataSource(
      sub: ros.subscribe("/cell"),
      valueBuilder: (json) => (json["cell_strength"].toString(), Colors.black),
    );
    compass = ROSCompassDataSource(
      sub: vtgSub,
      valueBuilder: (json) => json["true_track"] as double,
    );

    // Update map coordinates whenever GPS changes
    vtgSub.notifier.addListener(() {
      track = vtgSub.notifier.value["true_track"] as double;
    });

    internetStatusStream = connection!.internetStatus;
  }

  InternetChecker? get connection => services.internet;

  ROS get ros => services.ros;

  Log get log => services.logger;

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }
}

class RadiosPage extends StatefulWidget {
  final RadiosPageViewModel model;

  const RadiosPage({super.key, required this.model});

  @override
  State<RadiosPage> createState() => _RadiosPageState();
}

class _RadiosPageState extends State<RadiosPage> {
  RadiosPageViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 3, child: _buildInternetAndCell()),
              const SizedBox(width: 20),
              Flexible(flex: 7, child: _buildGPS()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInternetAndCell() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Internet",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWidgetBackground(
                          !kIsWeb
                              ? ValueListenableBuilder(
                                  valueListenable: model.connection!.ipAddress,
                                  builder: (_, value, __) {
                                    return _buildText(
                                      value ?? "Disconnected",
                                      "IP Address",
                                    );
                                  },
                                )
                              : _buildText("Unsupported", "IP Address"),
                        ),

                        _buildWidgetBackground(
                          StreamBuilder<InternetStatus>(
                            stream: model.internetStatusStream,
                            builder: (_, snapshot) {
                              final connected =
                                  snapshot.data == InternetStatus.connected;

                              return _buildText(
                                connected ? "Reachable" : "Unreachable",
                                "Shore Reachable?",
                                color: connected ? Colors.green : Colors.red,
                              );
                            },
                          ),
                        ),

                        _buildWidgetBackground(
                          !kIsWeb
                              ? ValueListenableBuilder(
                                  valueListenable: model.connection!.ssid,
                                  builder: (_, value, __) {
                                    return _buildText(
                                      value ?? "Disconnected",
                                      "WiFi SSID",
                                    );
                                  },
                                )
                              : _buildText("Unsupported", "WiFi SSID"),
                        ),

                        _buildWidgetBackground(
                          ROSText(
                            dataSource: model.cell,
                            subtext: "Cell Strength",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGPS() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "GPS and Location",
            style: Theme.of(context).textTheme.headlineLarge,
          ),

          // Latitude / Longitude
          Row(
            children: [
              Expanded(
                child: _buildWidgetBackground(
                  ROSText(dataSource: model.gpsLat, subtext: "Latitude"),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildWidgetBackground(
                  ROSText(dataSource: model.gpsLon, subtext: "Longitude"),
                ),
              ),
            ],
          ),

          // Stats Row 1
          Row(
            children: [
              Expanded(
                child: _buildWidgetBackground(
                  ROSText(dataSource: model.sv, subtext: "Satellites"),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildWidgetBackground(
                  ROSText(
                    dataSource: model.vtg,
                    subtext: "Speed (mph)",
                    subTextStyle: Theme.of(context).textTheme.titleLarge!.merge(
                      TextStyle(overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildWidgetBackground(
                  ROSText(dataSource: model.alt, subtext: "Altitude"),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildWidgetBackground(
                  ROSText(dataSource: model.climb, subtext: "Climb"),
                ),
              ),
            ],
          ),

          // Compass
          Expanded(
            child: _buildWidgetBackground(
              MarineCompass(dataSource: model.compass),
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
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildWidgetBackground(Widget inside, {double verticalPadding = 8}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: WaterboardColors.containerForeground,
      ),
      child: inside,
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: WaterboardColors.containerBackground,
      borderRadius: BorderRadius.circular(16),
    );
  }
}
