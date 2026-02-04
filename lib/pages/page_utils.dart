import 'package:flutter/material.dart';
import 'package:waterboard/services/ros_comms.dart';
import 'package:flutter/material.dart';

import '../settings/settings_dialog.dart';
class PageUtils {

  static void showSettingsDialog(BuildContext context, ROSComms comms) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Waterboard Settings"),
          content: SettingsDialog(comms: comms),
        );
      },
    );
  }
}

// Source - https://stackoverflow.com/a/63574708
// Posted by O Thạnh Ldt
// Retrieved 2026-02-03, License - CC BY-SA 4.0


class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child,});

  final Widget child;

  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    /// Dont't forget this
    super.build(context);

    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
