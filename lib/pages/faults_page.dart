import 'package:flutter/material.dart';
import 'package:waterboard/schemas/fault_msg_schema.dart';
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/services/services.dart';

class FaultsPageViewModel extends ChangeNotifier {
  List<FaultMsgSchema> faults = [];
  
  final Services services;
  
  late final ROSSubscription faultSub;

  FaultsPageViewModel({required this.services});
  void init() {
    faultSub = services.ros.subscribe("/alarm/shore/publish");
    faultSub.notifier.addListener(() => _onFaultMsgRec(),);
    //request old
    queryAlarms();
  }

  void _onFaultMsgRec() {
    FaultMsgSchema msg = FaultMsgSchema.fromJson(faultSub.notifier.value);
    faults.add(msg);
    notifyListeners();
  }

  void queryAlarms() {
    services.ros.createService("/alarm/query").call((success, json) {
      if(!success) return;
      List<dynamic> alarms = json["alarms"];
      faults.clear();
      for(var alarm in alarms) {
        var a = FaultMsgSchema.fromJson(alarm);
        faults.add(a);
      }
      notifyListeners();
    },);
  }
  @override
  void dispose() {
    super.dispose();
    faultSub.notifier.removeListener(_onFaultMsgRec);
  }
}

class FaultsPage extends StatefulWidget {
  final FaultsPageViewModel model;
  const FaultsPage({super.key, required this.model});

  @override
  State<FaultsPage> createState() => _FaultsPageState();
}

class _FaultsPageState extends State<FaultsPage> {
  FaultsPageViewModel get model => widget.model;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    model.init();
    model.addListener(() => setState(() {}),);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle messageStyle = Theme.of(context).textTheme.labelMedium!;
    final TextStyle headerStyle = Theme.of(
      context,
    ).textTheme.labelSmall!.merge(TextStyle(fontWeight: FontWeight.bold));
    if(model.faults.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("No Faults!", style: Theme.of(context).textTheme.displayLarge,),
          FilledButton(onPressed: () {
            model.queryAlarms();
          }, child: Text("Requery Alarms"))
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Spacer(),
            Text("Faults", style: Theme.of(context).textTheme.headlineMedium,),
            Spacer(),
            IconButton(onPressed: () { model.queryAlarms(); }, icon: Icon(Icons.refresh),)
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey,
                      child: Row(
                        children: [
                          _buildRowEntry(Text("Error Code", style: headerStyle), 1),
                          _buildRowEntry(
                            Text("Timestamp", style: headerStyle),
                            2,
                          ),
                          _buildRowEntry(Text("Description", style: headerStyle), 10),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: _controller,
                        itemCount: model.faults.length,
                        itemBuilder: (context, index) {
                          var msg = model.faults[index];
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              _buildRowEntry(
                                Text(
                                  "${msg.errorCode}",
                                  style: messageStyle.merge(
                                    TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                1,
                              ),
                              _buildRowEntry(
                                Text(
                                  _getTimeText(msg.time),
                                  style: messageStyle,
                                ),
                                2,
                              ),
                              _buildRowEntry(
                                Text(
                                  msg.message,
                                  style: messageStyle
                                ),
                                10,
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(height: 1, thickness: 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildRowEntry(Widget child, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      ),
    );
  }
  String _getTimeText(DateTime now) {
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;

    String two(int n) => n.toString().padLeft(2, '0');
    String amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${two(now.minute)}:${two(now.second)} $amPm';
  }
}
