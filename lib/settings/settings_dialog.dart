import 'package:flutter/material.dart';
import 'package:waterboard/pages/standby_mode_page.dart';
import 'package:waterboard/services/ros_comms.dart';

class SettingsDialog extends StatelessWidget {
  final ROSComms comms;
  const SettingsDialog({super.key, required this.comms});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          child: Text("Enter Standby Mode"),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
              return StandbyMode(comms: comms,);
            }));
          },
        )
      ],
    );
  }
}
