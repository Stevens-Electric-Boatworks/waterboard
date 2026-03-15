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
import 'package:waterboard/schemas/cell_message_schema.dart';
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

class GSAInfo {
  final List<int> activeSats;
  final double pDop;
  final double hDop;
  final double vDop;
  final String mode;
  final String opMode;

  GSAInfo({
    required this.activeSats,
    required this.pDop,
    required this.hDop,
    required this.vDop,
    required this.mode,
    required this.opMode,
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
  late final ROSSubscription gsaSub;
  late final ROSSubscription cellSub;

  late final ROSTextDataSource gpsLat;
  late final ROSTextDataSource gpsLon;
  late final ROSTextDataSource sv;
  late final ROSTextDataSource vtg;

  late final ROSCompassDataSource compass;

  late final ValueNotifier<List<SatelliteItem>> sats = ValueNotifier([]);
  late final ValueNotifier<GSAInfo?> gsaInfo = ValueNotifier(null);
  late final ValueNotifier<CellMessageSchema?> cellMessages = ValueNotifier(
    null,
  );

  double lat = 0;
  double lon = 0;
  double track = -1;

  bool mapReady = false;
  PmTilesVectorTileProvider? provider;

  RadiosPageViewModel({required this.services}) {
    gpsSub = ros.subscribe("/motion/gps");
    satsSub = ros.subscribe("/motion/sv");
    gsaSub = ros.subscribe("/motion/gsa");
    satsSub.notifier.addListener(_onSatListData);
    gsaSub.notifier.addListener(_onGSAInfo);
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
    cellSub = ros.subscribe("/cell", staleDuration: 10_000);
    cellSub.notifier.addListener(
      () => cellMessages.value = CellMessageSchema.fromJson(
        cellSub.notifier.value,
      ),
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

  void _onGSAInfo() {
    var gsaInfo = gsaSub.notifier.value;
    List<int> activeSats = [];
    for (var sat in gsaInfo["prn"]) {
      activeSats.add(sat as int);
    }
    double pDop = gsaInfo["pdop"] as double;
    double hDop = gsaInfo["hdop"] as double;
    double vDop = gsaInfo["vdop"] as double;

    //parse mode data
    String opMode = "Unknown";
    String gsaOpMode = gsaInfo["op_mode"] as String;
    if (gsaOpMode == "A") {
      opMode = "AUTO";
    } else if (gsaOpMode == "M") {
      opMode = "MANUAL";
    }
    String mode = "Unknown";

    int gsaMode = gsaInfo["mode"];
    if (gsaMode == 1) {
      mode = "NO FIX";
    } else if (gsaMode == 2) {
      mode = "2D FIX";
    } else if (gsaMode == 3) {
      mode = "3D FIX";
    }

    this.gsaInfo.value = GSAInfo(
      activeSats: activeSats,
      pDop: pDop,
      hDop: hDop,
      vDop: vDop,
      opMode: opMode,
      mode: mode,
    );
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
      child: Column(
        spacing: 20,
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
              spacing: 20,
              children: [
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
                    : PageUtils.buildText(context, "Unsupported", "IP Address"),

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
                    : PageUtils.buildText(context, "Unsupported", "WiFi SSID"),
                StreamBuilder<InternetStatus>(
                  stream: model.internetStatusStream,
                  builder: (_, snapshot) {
                    final connected = snapshot.data == InternetStatus.connected;

                    return PageUtils.buildText(
                      context,
                      connected ? "Reachable" : "Unreachable",
                      "Shore Reachable?",
                      color: connected ? Colors.green : Colors.red,
                    );
                  },
                ),
                Expanded(
                  child: PageUtils.buildWidgetBackground(
                    _buildCellInformationList(),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Text("GPS State", style: Theme.of(context).textTheme.headlineLarge),

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
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

                  final titleStyle = Theme.of(context).textTheme.bodyLarge!
                      .merge(TextStyle(fontWeight: FontWeight.bold));
                  return Flexible(
                    fit: FlexFit.loose,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SingleChildScrollView(
                              child: DataTable(
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                horizontalMargin: 12,
                                columnSpacing: constraints.maxWidth / 12,
                                columns: [
                                  DataColumn(
                                    label: Text('active', style: titleStyle),
                                  ),
                                  DataColumn(
                                    label: Text('prn', style: titleStyle),
                                  ),
                                  DataColumn(
                                    label: Text('elev', style: titleStyle),
                                  ),
                                  DataColumn(
                                    label: Text('azimuth', style: titleStyle),
                                  ),
                                  DataColumn(
                                    label: Text('snr', style: titleStyle),
                                  ),
                                ],
                                rows: value.mapIndexed((index, e) {
                                  WidgetStateProperty<Color> getColor() {
                                    if (index % 2 == 0) {
                                      return WidgetStateProperty.all(
                                        Colors.grey.shade300,
                                      );
                                    }
                                    return WidgetStateProperty.all(
                                      Colors.grey.shade100,
                                    );
                                  }

                                  (String, Color) isActive() {
                                    if (model.gsaInfo.value == null) {
                                      return ("?", Colors.grey);
                                    }
                                    var gsaInfo = model.gsaInfo.value!;
                                    if (gsaInfo.activeSats.contains(e.prn)) {
                                      return ("Y", Colors.green);
                                    }
                                    return ("N", Colors.red);
                                  }

                                  final rowStyle = Theme.of(
                                    context,
                                  ).textTheme.bodyMedium;
                                  return DataRow(
                                    color: getColor(),
                                    cells: [
                                      DataCell(
                                        Text(
                                          isActive().$1,
                                          style: rowStyle!.merge(
                                            TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isActive().$2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text("${e.prn}", style: rowStyle),
                                      ),
                                      DataCell(
                                        Text("${e.elev}", style: rowStyle),
                                      ),
                                      DataCell(
                                        Text("${e.azimuth}", style: rowStyle),
                                      ),
                                      DataCell(
                                        Text("${e.snr}", style: rowStyle),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 5),
              ValueListenableBuilder(
                valueListenable: model.gsaInfo,
                builder: (context, value, child) {
                  if (value == null) {
                    return Text("No GSA Data");
                  }
                  Widget buildDOP(String type, double after) {
                    return Column(
                      children: [
                        Text(
                          after.toStringAsPrecision(1),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          type,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 10,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            buildDOP("VDOP", value.vDop),
                            buildDOP("HDOP", value.hDop),
                            buildDOP("PDOP", value.pDop),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  value.opMode,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                Text(
                                  "Operation Mode",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  value.mode,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                Text(
                                  "Status",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCellInformationList() {
    Widget makeRow(String leading, String trailing) {
      return Row(
        children: [
          Text(
            "$leading:",
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            trailing,
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      spacing: 10,
      children: [
        Center(
          child: Text(
            "Cell Information",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: model.cellMessages,
          builder: (context, value, child) {
            if (value == null) {
              return Expanded(
                child: Column(
                  children: [
                    Spacer(),
                    Center(
                      child: Text(
                        "No Data Received",
                        softWrap: true,
                        style: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              );
            }
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black),
                ),
                padding: EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      makeRow("Bars", value.bars.toString()),
                      makeRow("RSRP", value.rsrp.toString()),
                      makeRow("RSRQ", value.rsrq.toString()),
                      makeRow("IP Address", value.ipAddress),
                      makeRow("APN", value.apn),
                      makeRow("Network", value.network),
                      makeRow("Technology", value.technology),
                      makeRow("Reg. Status", value.regStatus.toString()),
                      makeRow("Pin Status", value.pinStatus),
                    ],
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
