// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

// Project imports:
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/ros_widgets/marine_compass.dart';
import 'package:waterboard/widgets/ros_widgets/ros_text.dart';

class SatelliteItem {
  final int prn;
  final int elev;
  final int azimuth;
  final int snr;

  SatelliteItem({
    required this.prn,
    required this.elev,
    required this.azimuth,
    required this.snr,
  });
}

class RadiosPageViewModel extends ChangeNotifier {
  final Services services;
  final MapController mapController = MapController();

  late final Stream<InternetStatus> internetStatusStream;

  // ROS subscriptions
  late final ROSSubscription gpsSub;
  late final ROSSubscription vtgSub;
  late final ROSSubscription satsSub;

  late final ROSTextDataSource gpsLat;
  late final ROSTextDataSource gpsLon;
  late final ROSTextDataSource sv;
  late final ROSTextDataSource vtg;
  late final ROSTextDataSource alt;
  late final ROSTextDataSource climb;
  late final ROSTextDataSource cell;

  late final ROSCompassDataSource compass;

  late final ValueNotifier<List<SatelliteItem>> sats = ValueNotifier([]);

  double lat = 0;
  double lon = 0;
  double track = -1;

  bool mapReady = false;
  PmTilesVectorTileProvider? provider;

  RadiosPageViewModel({required this.services}) {
    gpsSub = ros.subscribe("/motion/gps");
    satsSub = ros.subscribe("/motion/sv");
    satsSub.notifier.addListener(_onSatListData);
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
      sub: satsSub,
      valueBuilder: (json) => ("${json["sats"].length}", Colors.black),
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

  void _onSatListData() {
    var satData = satsSub.notifier.value;
    List<SatelliteItem> sats = [];
    for (var sat in satData["sats"]) {
      sats.add(
        SatelliteItem(
          prn: sat["prn"] as int,
          elev: sat["elev"] as int,
          azimuth: sat["azimuth"] as int,
          snr: sat["snr"] as int,
        ),
      );
    }
    this.sats.value = sats;
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
      decoration: PageUtils.panelDecoration(),
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
                        PageUtils.buildWidgetBackground(
                          !kIsWeb
                              ? ValueListenableBuilder(
                                  valueListenable: model.connection!.ipAddress,
                                  builder: (_, value, __) {
                                    return PageUtils.buildText(
                                      context,
                                      value ?? "Disconnected",
                                      "IP Address",
                                    );
                                  },
                                )
                              : PageUtils.buildText(
                                  context,
                                  "Unsupported",
                                  "IP Address",
                                ),
                        ),

                        PageUtils.buildWidgetBackground(
                          StreamBuilder<InternetStatus>(
                            stream: model.internetStatusStream,
                            builder: (_, snapshot) {
                              final connected =
                                  snapshot.data == InternetStatus.connected;

                              return PageUtils.buildText(
                                context,
                                connected ? "Reachable" : "Unreachable",
                                "Shore Reachable?",
                                color: connected ? Colors.green : Colors.red,
                              );
                            },
                          ),
                        ),

                        PageUtils.buildWidgetBackground(
                          !kIsWeb
                              ? ValueListenableBuilder(
                                  valueListenable: model.connection!.ssid,
                                  builder: (_, value, __) {
                                    return PageUtils.buildText(
                                      context,
                                      value ?? "Disconnected",
                                      "WiFi SSID",
                                    );
                                  },
                                )
                              : PageUtils.buildText(
                                  context,
                                  "Unsupported",
                                  "WiFi SSID",
                                ),
                        ),

                        PageUtils.buildWidgetBackground(
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
      decoration: PageUtils.panelDecoration(),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "GPS and Location",
            style: Theme.of(context).textTheme.headlineLarge,
          ),

          Expanded(
            child: Row(
              spacing: 20,
              mainAxisSize: MainAxisSize.max,
              children: [
                //Left Side
                Expanded(
                  flex: 1,
                  child: Column(
                    spacing: 20,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: PageUtils.buildWidgetBackground(
                              ROSText(
                                dataSource: model.gpsLon,
                                subtext: "Longitude",
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 20,
                        children: [
                          Expanded(
                            child: PageUtils.buildWidgetBackground(
                              ROSText(
                                dataSource: model.sv,
                                subtext: "Satellites",
                              ),
                            ),
                          ),
                          Expanded(
                            child: PageUtils.buildWidgetBackground(
                              ROSText(
                                dataSource: model.vtg,
                                subtext: "Speed (mph)",
                                subTextStyle: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .merge(
                                      TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          spacing: 20,
                          children: [
                            Expanded(
                              child: PageUtils.buildWidgetBackground(
                                MarineCompass(dataSource: model.compass),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                //Right Side
                Expanded(
                  flex: 1,
                  child: Column(
                    spacing: 20,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: PageUtils.buildWidgetBackground(
                              ROSText(
                                dataSource: model.gpsLat,
                                subtext: "Latitude",
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: PageUtils.buildWidgetBackground(
                                _buildSatellitesList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Compass
        ],
      ),
    );
  }

  Widget _buildSatellitesList() {
    return Column(
      spacing: 20,
      children: [
        Stack(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.satellite_alt, size: 32),
                ),
              ],
            ),
            Center(
              child: Text(
                "GPS Satellites",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: model.sats,
          builder: (context, value, child) {
            if (value.isEmpty) {
              return Expanded(
                child: Column(
                  children: [
                    Spacer(),
                    Center(
                      child: Text(
                        "No GPS Satellites Connected",
                        style: Theme.of(context).textTheme.displayMedium!
                            .copyWith(color: Colors.red.shade900),
                        softWrap: true,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              );
            }

            final titleStyle = Theme.of(context).textTheme.bodyLarge!.merge(
              TextStyle(fontWeight: FontWeight.bold),
            );
            return Flexible(
              fit: FlexFit.loose,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    child: DataTable(
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.black),
                      ),
                      columns: [
                        DataColumn(label: Container()),
                        DataColumn(
                          label: Expanded(
                            child: Text('prn', style: titleStyle),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text('elev', style: titleStyle),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text('azimuth', style: titleStyle),
                          ),
                        ),
                        DataColumn(
                          label: Expanded(
                            child: Text('snr', style: titleStyle),
                          ),
                        ),
                      ],
                      rows: value.mapIndexed((index, e) {
                        WidgetStateProperty<Color> getColor() {
                          if (index % 2 == 0) {
                            return WidgetStateProperty.all(
                              Colors.grey.shade300,
                            );
                          }
                          return WidgetStateProperty.all(Colors.grey.shade100);
                        }

                        final rowStyle = Theme.of(context).textTheme.bodyMedium;
                        return DataRow(
                          color: getColor(),
                          cells: [
                            DataCell(
                              Text(
                                "${index + 1}.",
                                style: rowStyle!.merge(
                                  TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                            DataCell(Text("${e.prn}", style: rowStyle)),
                            DataCell(Text("${e.elev}", style: rowStyle)),
                            DataCell(Text("${e.azimuth}", style: rowStyle)),
                            DataCell(Text("${e.snr}", style: rowStyle)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
