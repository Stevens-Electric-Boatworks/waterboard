// Flutter imports:

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:slider_button/slider_button.dart';

// Project imports:
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/ros_widgets/ros_cell_connection_widget.dart';
import 'package:waterboard/widgets/ros_widgets/ros_connection_state_widget.dart';
import 'package:waterboard/widgets/time_text.dart';
import '../pages/page_utils.dart';

class WaterboardAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final Services services;
  final bool Function() layoutLocked;
  final Function() onSettingsChanged;
  final Function() unlockLayout;
  final ROSCellDataSource rosCellDataSource;

  const WaterboardAppBarWidget({
    super.key,
    required this.services,
    required this.layoutLocked,
    required this.onSettingsChanged,
    required this.rosCellDataSource,
    required this.unlockLayout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...getLeading(context),
              Spacer(),
              Spacer(),
              ...getTrailing(context),
            ],
          ),
          Center(child: getTitle(context)),
        ],
      ),
    );
  }

  Widget getTitle(BuildContext context) {
    return Text(
      "Stevens Electric Boatworks",
      style: Theme.of(
        context,
      ).textTheme.titleLarge!.merge(TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  List<Widget> getLeading(BuildContext context) {
    return [
      SizedBox(width: 4),
      Container(
        decoration: BoxDecoration(border: BoxBorder.all(color: Colors.black)),
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClockText(style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
      ),
      if (layoutLocked()) ...[
        SizedBox(width: 10),
        Icon(
          Icons.lock,
          size: Theme.of(context).textTheme.titleLarge!.fontSize!,
        ),
        SizedBox(width: 20),
        SliderButton(
          action: () async {
            unlockLayout();
            return true;
          },
          useGlassEffect: true,

          label: Text(
            "Slide to unlock!",
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          icon: Center(
            child: Icon(Icons.lock_open, color: Colors.white, size: 32.0),
          ),

          width: 300,
          radius: 24,
          buttonColor: Colors.blue.shade800,
          backgroundColor: Colors.blue.shade200,
          highlightedColor: Colors.blue.shade700,
          baseColor: Colors.black,
        ),
      ],
      kIsWeb
          ? Text(
              "         WARNING: Web Support is Experimental!",
              style: Theme.of(context).textTheme.titleSmall?.merge(
                TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )
          : Container(),
    ];
  }

  List<Widget> getTrailing(BuildContext context) {
    return [
      ValueListenableBuilder(
        valueListenable: services.ros.connectionState,
        builder: (context, value, child) => ROSConnectionStateWidget(
          value: value,
          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
          iconSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
        ),
      ),
      SizedBox(width: 15),
      RosCellConnectionWidget(dataSource: rosCellDataSource),
      SizedBox(width: 15),
      IgnorePointer(
        ignoring: layoutLocked(),
        child: IconButton(
          onPressed: () {
            if (layoutLocked()) return;
            PageUtils.showSettingsDialog(context, services, onSettingsChanged);
          },
          icon: Icon(
            Icons.settings,
            size: Theme.of(context).textTheme.titleLarge!.fontSize!,
          ),
        ),
      ),
    ];
  }

  @override
  Size get preferredSize => Size.fromHeight(48);
}
