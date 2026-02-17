// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/log.dart';

class WaterboardLogsWidgetViewModel extends ChangeNotifier {
  List<WaterboardLogMessage> get messages => Log.instance.msgs;

  void init() {
    Log.instance.addListener(() {
      notifyListeners();
    });
  }
}

class WaterboardLogsWidget extends StatefulWidget {
  final WaterboardLogsWidgetViewModel model;

  const WaterboardLogsWidget({super.key, required this.model});

  @override
  State<WaterboardLogsWidget> createState() => _WaterboardLogsWidgetState();
}

class _WaterboardLogsWidgetState extends State<WaterboardLogsWidget> {
  WaterboardLogsWidgetViewModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontWeight: FontWeight.bold);
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SingleChildScrollView(
          child: Table(
            columnWidths: {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(6),
              2: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade500),
                children: [
                  Row(
                    children: [
                      SizedBox(width: 2),
                      Text("Level", style: style),
                    ],
                  ),
                  Text("Message", style: style),
                  Text("Timestamp", style: style),
                ],
              ),
              ..._getRows(),
            ],
          ),
        ),
      ),
    );
  }

  List<TableRow> _getRows() {
    List<TableRow> rows = [];
    int i = 0;
    for (WaterboardLogMessage msg in model.messages) {
      final Color color = i % 2 == 0 ? Colors.white : Colors.grey.shade300;
      rows.insert(
        0,
        TableRow(
          decoration: BoxDecoration(color: color),
          children: [
            Row(
              children: [
                SizedBox(width: 2),
                Text(msg.level.name.toUpperCase()),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                msg.msg,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            Text(_getTimeText(msg.time)),
          ],
        ),
      );
      i++;
    }
    return rows;
  }

  String _getTimeText(DateTime now) {
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;

    String two(int n) => n.toString().padLeft(2, '0');
    String amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${two(now.minute)}:${two(now.second)} $amPm';
  }
}
