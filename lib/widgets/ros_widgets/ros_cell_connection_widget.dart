import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:waterboard/schemas/cell_message_schema.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/widgets/ros_widgets/ros_listenable_widget.dart';

class ROSCellDataSource {
  final ROSSubscription sub;

  // # of bars
  final CellMessageSchema Function(Map<String, dynamic> json) valueBuilder;

  ROSCellDataSource({required this.sub, required this.valueBuilder});
}

class RosCellConnectionWidget extends StatelessWidget {
  final ROSCellDataSource dataSource;

  const RosCellConnectionWidget({super.key, required this.dataSource});

  @override
  Widget build(BuildContext context) {
    final double size = Theme.of(context).textTheme.titleMedium!.fontSize!;
    final TextStyle textStyle = Theme.of(
      context,
    ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold);
    return ROSListenable(
      strokeWidth: 4,
      padding: EdgeInsetsGeometry.all(4),
      subscription: dataSource.sub,
      builder: (context, value) =>
          withData(dataSource.valueBuilder(value), size, textStyle),
      noDataBuilder: (_) => _invalid(size),
    );
  }

  Widget withData(CellMessageSchema msg, double size, TextStyle textStyle) {
    (IconData, Color color)? icon;
    int bars = msg.bars;
    if (bars == 0) {
      icon = (
        Symbols.signal_cellular_connected_no_internet_0_bar,
        Colors.red.shade900,
      );
    } else if (bars == 1) {
      icon = (Symbols.signal_cellular_1_bar, Colors.red);
    } else if (bars == 2) {
      icon = (Symbols.signal_cellular_1_bar, Colors.orange);
    } else if (bars == 3) {
      icon = (Symbols.signal_cellular_1_bar, Colors.orange);
    } else if (bars == 4) {
      icon = (Symbols.signal_cellular_1_bar, Colors.green);
    } else {
      icon = null;
    }
    if (icon == null) return _invalid(size);

    return Tooltip(
      message:
          "Bars: ${msg.bars}\n"
          "RSRP: ${msg.rsrp}\n"
          "RSRQ: ${msg.rsrq}\n"
          "IP Address: ${msg.ipAddress}\n"
          "APN: ${msg.apn}\n"
          "Network: ${msg.network}\n"
          "Technology: ${msg.technology}\n"
          "Reg. Status: ${msg.regStatus}\n"
          "Pin Status: ${msg.pinStatus}",
      child: Row(
        children: [
          Icon(
            icon.$1,
            color: icon.$2,
            size: size,
            weight: 700,
            opticalSize: 20,
          ),
          SizedBox(width: 5),
          Text(
            "${msg.network} ${msg.technology}",
            style: textStyle.copyWith(color: icon.$2),
          ),
        ],
      ),
    );
  }

  Widget _invalid(double size) {
    return Tooltip(
      message: "Cell state not known yet",
      child: Stack(
        children: [
          Icon(Icons.question_mark, size: size, color: Colors.grey),
          Icon(
            Icons.signal_cellular_connected_no_internet_0_bar,
            size: size,
            color: Colors.grey,
            weight: 700,
            opticalSize: 20,
          ),
        ],
      ),
    );
  }
}
