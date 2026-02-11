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
class RadiosPageViewModel extends ChangeNotifier {
  final ROS ros;
  final MapController mapController = MapController();
  final NetworkInfo networkInfo = NetworkInfo();

  late final Stream<InternetStatus> internetStatusStream;
  final ValueNotifier<String?> ssid = ValueNotifier(null);
  final ValueNotifier<String?> ipAddress = ValueNotifier(null);

  // ROS subscriptions
  late final ValueNotifier<Map<String, dynamic>> gps;
  late final ValueNotifier<Map<String, dynamic>> sv;
  late final ValueNotifier<Map<String, dynamic>> vtg;
  late final ValueNotifier<Map<String, dynamic>> alt;
  late final ValueNotifier<Map<String, dynamic>> climb;
  late final ValueNotifier<Map<String, dynamic>> cell;

  double lat = 0;
  double lon = 0;

  Timer? _networkTimer;
  bool mapReady = false;
  PmTilesVectorTileProvider? provider;

  RadiosPageViewModel({required this.ros}) {
    // initialize ROS subscriptions
    gps = ros.subscribe("/motion/gps").value;
    sv = ros.subscribe("/motion/sv").value;
    vtg = ros.subscribe("/motion/vtg").value;
    alt = ros.subscribe("/motion/gps/alt").value;
    climb = ros.subscribe("/motion/gps/climb").value;
    cell = ros.subscribe("/cell").value;

    gps.addListener(_onGpsUpdate);

    // initialize network status stream
    internetStatusStream = InternetConnection.createInstance(
      customCheckOptions: [
        InternetCheckOption(uri: Uri.parse('shore.stevenseboat.org')),
      ],
    ).onStatusChange;

    if (!kIsWeb) {
      _prepareMapProvider();
      _networkTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) => updateNetworkInfo(),
      );
    }
  }

  void _onGpsUpdate() {
    final val = gps.value;
    if (!mapReady) return;

    lat = val["lat"] as double;
    lon = val["lon"] as double;
    mapController.move(LatLng(lat, lon), mapController.camera.zoom);
    notifyListeners();
  }

  Future<void> updateNetworkInfo() async {
    ssid.value = await networkInfo.getWifiName();
    ipAddress.value = await networkInfo.getWifiIP();
  }

  Future<void> _prepareMapProvider() async {
    try {
      final byteData = await rootBundle.load('assets/mapdata/hoboken_final.pmtiles');
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'hoboken_final.pmtiles');
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      Log.instance.info("Hoboken Offline Map copied to: $filePath");
      provider = await PmTilesVectorTileProvider.fromSource(filePath);
      Log.instance.info("Hoboken Offline Map loaded");
      mapReady = true;
      notifyListeners();
    } catch (e) {
      Log.instance.error("Failed to load map: $e");
    }
  }

  @override
  void dispose() {
    gps.removeListener(_onGpsUpdate);
    _networkTimer?.cancel();
    ssid.dispose();
    ipAddress.dispose();
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildInternetAndCell(),
          const SizedBox(width: 15),
          _buildGPS(),
        ],
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
            valueListenable: model.ipAddress,
            builder: (_, value, __) {
              return _buildText(
                value ?? (kIsWeb ? "Unsupported" : "Not Connected"),
                "IP Address",
              );
            },
          ),
          StreamBuilder<InternetStatus>(
            stream: model.internetStatusStream,
            builder: (_, snapshot) {
              final status = snapshot.data;
              if (status == InternetStatus.connected) {
                return _buildText("Reachable", "Shore Reachable?", color: Colors.green);
              } else {
                return _buildText("Unreachable", "Shore Reachable?", color: Colors.red);
              }
            },
          ),
          ValueListenableBuilder(
            valueListenable: model.ssid,
            builder: (_, value, __) {
              return _buildText(
                value ?? (kIsWeb ? "Unsupported" : "Not Connected"),
                "WiFi SSID",
              );
            },
          ),
          _buildWidgetBackground(
            ROSText(
              notifier: model.cell,
              valueBuilder: (json) => (json["cell_strength"].toString(), Colors.black),
              subtext: "Cell Strength",
            ),
          ),
          _buildText("shore.stevenseboat.org", "Shore URL", style: Theme.of(context).textTheme.titleLarge),
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
            Text("GPS and Location", style: Theme.of(context).textTheme.headlineLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWidgetBackground(
                  ROSText(
                    notifier: model.gps,
                    valueBuilder: (json) => ((json["lat"] as double).toStringAsPrecision(12), Colors.black),
                    subtext: "Latitude",
                  ),
                  width: 350,
                ),
                _buildWidgetBackground(
                  ROSText(
                    notifier: model.gps,
                    valueBuilder: (json) => ((json["lon"] as double).toStringAsPrecision(12), Colors.black),
                    subtext: "Longitude",
                  ),
                  width: 350,
                ),
              ],
            ),
            // sats, speed, alt, climb
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    _buildWidgetBackground(
                      ROSText(
                        notifier: model.sv,
                        valueBuilder: (json) => ("${json["sats"]}", Colors.black),
                        subtext: "Satellites",
                      ),
                      width: 172.5 - 5,
                    ),
                    const SizedBox(width: 10),
                    _buildWidgetBackground(
                      ROSText(
                        notifier: model.vtg,
                        valueBuilder: (json) => ((json["speed"] as double).toStringAsPrecision(2), Colors.black),
                        subtext: "Speed (mph)",
                      ),
                      width: 172.5 - 5,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildWidgetBackground(
                      ROSText(
                        notifier: model.alt,
                        valueBuilder: (json) => ((json["alt"] as double).toStringAsPrecision(7), Colors.black),
                        subtext: "Altitude",
                      ),
                      width: 172.5 - 5,
                    ),
                    const SizedBox(width: 10),
                    _buildWidgetBackground(
                      ROSText(
                        notifier: model.ros.subscribe("/motion/gps/climb").value,
                        valueBuilder: (json) => ((json["climb"] as double).toStringAsPrecision(2), Colors.black),
                        subtext: "Climb",
                      ),
                      width: 172.5 - 5,
                    ),
                  ],
                ),
              ],
            ),
            // compass and map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWidgetBackground(
                    MarineCompass(
                      notifier: model.vtg,
                      valueBuilder: (json) => json["true_track"] as double,
                    ),
                    width: 350,
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    height: 370,
                    child: _buildWidgetBackground(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (!kIsWeb && model.provider == null)
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            Text("The map is loading...", style: Theme.of(context).textTheme.titleLarge),
                            Text("(Did you remember to run git lfs pull?)", style: Theme.of(context).textTheme.titleSmall),
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

  Widget _getMap() {
    return FlutterMap(
      mapController: model.mapController,
      options: MapOptions(
        keepAlive: true,
        initialCenter: LatLng(40.7507, -74.0272),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.scrollWheelZoom |
          InteractiveFlag.pinchZoom |
          InteractiveFlag.doubleTapZoom |
          InteractiveFlag.doubleTapDragZoom,
        ),
        initialZoom: 15,
      ),
      children: [
        if (!kIsWeb) VectorTileLayer(
          theme: ProtomapsThemes.lightV4(),
          tileProviders: TileProviders({'protomaps': model.provider!}),
          fileCacheTtl: Duration.zero,
        )
        else TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
        MarkerLayer(
          markers: [
            Marker(point: LatLng(model.lat, model.lon), child: const Icon(Icons.location_on, size: 32)),
          ],
        ),
      ],
    );
  }

  Widget _buildText(String value, String subtitle, {Color color = Colors.black, TextStyle? style}) {
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

  Widget _buildWidgetBackground(Widget inside, {double width = 275, double verticalPadding = 8}) {
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
