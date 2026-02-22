import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/widgets/ros_connection_state_widget.dart';
import 'package:waterboard/widgets/time_text.dart';

import '../pages/page_utils.dart';

class WaterboardAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final ROS ros;

  const WaterboardAppBarWidget({super.key, required this.ros});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          ...getLeading(context),
          Spacer(),
          getTitle(context),
          Spacer(),
          ...getActions(context)
        ],
      ),
    );
  }

  Widget getTitle(BuildContext context) {
    return Text(
      "Stevens Electric Boatworks",
      style: Theme.of(context).textTheme.titleLarge!.merge(TextStyle(fontWeight: FontWeight.bold)),
    );
  }
  List<Widget> getLeading(BuildContext context) {
    return [SizedBox(width: 4),
      Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.black),
        ),
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClockText(
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall,
            ),
          ),
        ),
      ),
      kIsWeb
          ? Text(
        "         WARNING: Web Support is Experimental!",
        style: Theme
            .of(context)
            .textTheme
            .titleSmall
            ?.merge(
          TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : Container(),
    ];
  }
  List<Widget> getActions(BuildContext context) {
    return [
      ValueListenableBuilder(
        valueListenable: ros.connectionState,
        builder: (context, value, child) =>
            ROSConnectionStateWidget(
              value: value,
              fontSize: Theme
                  .of(context)
                  .textTheme
                  .titleSmall!
                  .fontSize!,
              iconSize: Theme
                  .of(context)
                  .textTheme
                  .titleSmall!
                  .fontSize!,
            ),
      ),
      SizedBox(width: 15),
      IconButton(
        onPressed: () => PageUtils.showSettingsDialog(context, ros),
        icon: Icon(
          Icons.settings,
          size: Theme
              .of(context)
              .textTheme
              .titleLarge!
              .fontSize!,
        ),
      ),
    ];
  }

  @override
  Size get preferredSize => Size.fromHeight(48);
}
