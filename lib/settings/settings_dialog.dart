// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/pages/standby_mode_page.dart';
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/widgets/time_text.dart';

class SettingsDialog extends StatefulWidget {
  final ROSComms comms;
  const SettingsDialog({super.key, required this.comms});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final TextEditingController _ipTextController = TextEditingController();
  final TextEditingController _portTextController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _updateIPInSettings();
  }

  void _updateIPInSettings() async {
    var prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString("websocket.ip") ?? "127.0.0.1";
    int? port = prefs.getInt("websocket.port") ?? 9090;
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g 127.0.0.1',
                    ),
                    controller: _ipTextController,
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setString("websocket.ip", value);
                      });
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g 9090',
                    ),
                    controller: _portTextController,
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      if (int.tryParse(value) == null) return;
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setInt("websocket.port", int.parse(value));
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 25),
          Center(
            child: FilledButton(
              child: Text("Restart ROSBridge Comms"),
              onPressed: () {
                widget.comms.reconnect();
              },
            ),
          ),
          SizedBox(height: 5),
          Center(
            child: FilledButton(
              child: Text("Enter Standby Mode"),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return StandbyMode(comms: widget.comms);
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
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
