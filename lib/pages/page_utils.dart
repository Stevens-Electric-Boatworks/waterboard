// Flutter imports:
import 'package:flutter/material.dart';
// Project imports:
import 'package:waterboard/services/ros_comms.dart';

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

class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
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
