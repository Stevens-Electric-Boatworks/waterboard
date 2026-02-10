// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_map/flutter_map.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

// Project imports:
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/waterboard_colors.dart';
import 'package:waterboard/widgets/ros_widgets/ros_compass.dart';
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

  final MapController _mapController = MapController();
  late final ValueNotifier _gps;
  double _lat = 0;
  double _lon = 0;
  Timer? _timer;
  bool _mapReady = false;
  PmTilesVectorTileProvider? _provider;

  @override
  void initState() {
    super.initState();
    _gps = widget.ros.subscribe("/motion/gps").value;
    _gps.addListener(() {
      var val = _gps.value;
      if (val == null) return;
      if (!_mapReady) return;
      _lat = val["lat"] as double;
      _lon = val["lon"] as double;
      setState(() {
        _mapController.move(LatLng(_lat, _lon), _mapController.camera.zoom);
      });
    });
    _subscription = internetConnectionChecker.onStatusChange;
    if(kIsWeb) return;
    _prepareMapProvider();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => updateNetworkInfo());
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
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
        mainAxisSize: MainAxisSize.max,
        children: [_buildInternetAndCell(), SizedBox(width: 15), _buildGPS()],
      ),
    );
  }

  Widget _buildInternetAndCell() {
    return Container(
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
                if(kIsWeb) {
                  return _buildText("Unsupported", "IP Address");
                }
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
                if(kIsWeb) {
                  return _buildText("Unsupported", "WiFi SSID");
                }
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
    );
  }

  Widget _buildGPS() {
    return Expanded(
      child: Container(
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
              "GPS and Location",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            //lat and lon
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWidgetBackground(
                  ROSText(
                    notifier: widget.ros.subscribe("/motion/gps").value,
                    valueBuilder: (json) {
                      return (
                        (json["lat"] as double).toStringAsPrecision(12),
                        Colors.black,
                      );
                    },
                    subtext: "Latitude",
                  ),
                  width: 350,
                ),
                _buildWidgetBackground(
                  ROSText(
                    notifier: widget.ros.subscribe("/motion/gps").value,
                    valueBuilder: (json) {
                      return (
                        (json["lon"] as double).toStringAsPrecision(12),
                        Colors.black,
                      );
                    },
                    subtext: "Longitude",
                  ),
                  width: 350,
                ),
              ],
            ),

            //sats, speed, alt, climb
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    _buildWidgetBackground(
                      //not implemented
                      ROSText(
                        notifier: widget.ros
                            .subscribe("/motion/gps/sats")
                            .value,
                        valueBuilder: (json) {
                          return (
                            (json["sats"] as double).toStringAsPrecision(7),
                            Colors.black,
                          );
                        },
                        subtext: "Satellites",
                      ),
                      width: 350 / 2 - 5,
                    ),
                    SizedBox(width: 10),
                    _buildWidgetBackground(
                      ROSText(
                        notifier: widget.ros.subscribe("/motion/vtg").value,
                        valueBuilder: (json) {
                          return (
                            ((json["speed"] as double).toStringAsPrecision(2)),
                            Colors.black,
                          );
                        },
                        subtext: "Speed (mph)",
                      ),
                      width: 350 / 2 - 5,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildWidgetBackground(
                      //not implemented
                      ROSText(
                        notifier: widget.ros.subscribe("/motion/gps/alt").value,
                        valueBuilder: (json) {
                          return (
                            (json["alt"] as double).toStringAsPrecision(7),
                            Colors.black,
                          );
                        },
                        subtext: "Altitude",
                      ),
                      width: 350 / 2 - 5,
                    ),
                    SizedBox(width: 10),
                    _buildWidgetBackground(
                      ROSText(
                        notifier: widget.ros
                            .subscribe("/motion/gps/climb")
                            .value,
                        valueBuilder: (json) {
                          return (
                            ((json["climb"] as double).toStringAsPrecision(2)),
                            Colors.black,
                          );
                        },
                        subtext: "Climb",
                      ),
                      width: 350 / 2 - 5,
                    ),
                  ],
                ),
              ],
            ),

            //compass and GPS map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWidgetBackground(
                    MarineCompass(
                      notifier: widget.ros.subscribe("/motion/vtg").value,
                      valueBuilder: (json) {
                        return json["true_track"] as double;
                      },
                    ),
                    width: 350,
                  ),
                  SizedBox(width: 20),
                  SizedBox(
                    height: 370,
                    child: _buildWidgetBackground(
                      ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(12),
                        child: (_provider == null) && (!kIsWeb)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  Text(
                                    "The map is loading...",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    "(Did you remember to run git lfs pull?)",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ],
                              )
                            : _getMap(),
                      ),

                      width: 350,
                      verticalPadding: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prepareMapProvider() async {
    final byteData = await rootBundle.load(
      'assets/mapdata/hoboken_final.pmtiles',
    );

    final tempDir = await getTemporaryDirectory();
    final filePath = p.join(tempDir.path, 'hoboken_final.pmtiles');

    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    Log.instance.info("Hoboken Offline Map copied to: $filePath");
    _provider = await PmTilesVectorTileProvider.fromSource(filePath);
    Log.instance.info("Hoboken Offline Map loaded");
    setState(() {});
  }

  Widget _getMap() {
    _mapReady = true;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        keepAlive: true,
        initialCenter: LatLng(40.7507, -74.0272),
        interactionOptions: InteractionOptions(
          flags:
              InteractiveFlag.scrollWheelZoom |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.doubleTapDragZoom,
        ),
        initialZoom: 15,
      ),
      children: [
        //C:/Users/Ishaan/School Programming Projects/Electric-Boatworks/Waterboard/assets/mapdata/hoboken2.mbtiles
        _getMapTileLayer(),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_lat, _lon),
              child: Icon(Icons.location_on, size: 32),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getMapTileLayer() {
    if(!kIsWeb) {
      return VectorTileLayer(
        // the map theme
        theme: ProtomapsThemes.lightV4(),

        tileProviders: TileProviders({
          // the awaited vector tile provider
          'protomaps': _provider!,
        }),

        // disable the file cache when you change the PMTiles source
        fileCacheTtl: Duration.zero,
      );
    }
    else {
      return TileLayer(
        urlTemplate:
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName:
        'dev.fleaflet.flutter_map.example',
      );
    }
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

  Widget _buildWidgetBackground(
    Widget inside, {
    double width = 275,
    double verticalPadding = 8,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: WaterboardColors.containerForeground,
      ),
      child: SizedBox(width: width, child: inside),
    );
  }
}
