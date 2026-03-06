// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/pages/standby_mode_page.dart';
import 'package:waterboard/pref_keys.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/hazard_stripe_border.dart';
import 'package:waterboard/widgets/time_text.dart';

// Package imports:

class SettingsDialog extends StatefulWidget {
  final Services services;
  final Function() onSettingsChanged;

  const SettingsDialog({
    super.key,
    required this.services,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final TextEditingController _ipTextController = TextEditingController();
  final TextEditingController _portTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateIPInSettings();
  }

  void _updateIPInSettings() async {
    var prefs = widget.services.preferences;
    String ip = prefs.getString(PrefKeys.websocketIP) ?? Defaults.websocketIP;
    int? port = prefs.getInt(PrefKeys.websocketPort) ?? Defaults.websocketPort;
    _ipTextController.text = ip;
    _portTextController.text = port.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ip addr prompt
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("IP Address: "),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    key: Key("ip_address"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g 127.0.0.1',
                    ),
                    controller: _ipTextController,
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      widget.services.preferences.setString(
                        PrefKeys.websocketIP,
                        value,
                      );
                      widget.onSettingsChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
          //ip port prompt
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Port: "),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    key: Key("port"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g 9090',
                    ),
                    controller: _portTextController,
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      if (int.tryParse(value) == null) return;
                      widget.services.preferences.setInt(
                        PrefKeys.websocketPort,
                        int.parse(value),
                      );
                      widget.onSettingsChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Text("Lock Layout"),
              SizedBox(width: 10),
              Switch(
                value:
                    widget.services.preferences.getBool(
                      PrefKeys.layoutLocked,
                    ) ??
                    Defaults.layoutLocked,
                onChanged: (value) {
                  setState(() {
                    widget.services.preferences.setBool(
                      PrefKeys.layoutLocked,
                      value,
                    );
                    widget.onSettingsChanged();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 25),
          SizedBox(height: 5),
          Center(
            child: FilledButton(
              child: Text("Enter Standby Mode"),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return StandbyModePage(ros: widget.services.ros);
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: HazardStripeBorder(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade300),
                child: Text("Restart ROSBridge Comms"),
                onPressed: () {
                  widget.services.ros.reconnect();
                },
              ),
            ),
          ),
          Center(
            child: IconButton(
              onPressed: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: "fih",
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return Center(
                      child: Image.asset(
                        "assets/fih.jpg",
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                );
              },
              icon: Text("🐟"),
            ),
          ),
          Center(
            child: ClockText(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
