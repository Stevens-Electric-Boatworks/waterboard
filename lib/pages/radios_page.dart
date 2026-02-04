import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class RadiosPage extends StatefulWidget {
  const RadiosPage({super.key});

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

  late final Timer _timer;



  @override
  void initState() {
    super.initState();
    _subscription = internetConnectionChecker.onStatusChange;
    _timer = Timer.periodic(
      Duration(seconds: 1),
          (_) => updateBSSID(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _ssid.dispose();
  }

  Future<void> updateBSSID() async {
    _ssid.value = await info.getWifiName();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PI Connectivity State
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      "Internet Connection State",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 10),
                    //Internet Reachable?
                    buildRow(
                      Icon(Icons.beach_access),
                      "Shore Reachable?",
                      StreamBuilder(
                        stream: _subscription,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "Unknown",
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          var state = snapshot.data;
                          if (state == InternetStatus.connected) {
                            return Text(
                              "Reachable",
                              style: TextStyle(color: Colors.green),
                            );
                          }
                          return Text(
                            "Cannot Connect",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    //Wifi State
                    buildRow(
                      Icon(Icons.network_wifi),
                      "SSID:",
                      ValueListenableBuilder<String?>(
                        valueListenable: _ssid,
                        builder: (context, value, _) {
                          return Text(value ?? "No WiFi");
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRow(Widget icon, String text, Widget result) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        icon,
        SizedBox(width: 10),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(width: 5),
        result,
      ],
    );
  }
}
