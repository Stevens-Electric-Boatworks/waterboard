// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/hazard_stripe_border.dart';

class ActionsPageViewModel extends ChangeNotifier {
  final Services services;

  ROS get ros => services.ros;

  ActionsPageViewModel({required this.services});

  void init() {}

  Future<void> runServiceAction({
    required BuildContext context,
    required String serviceName,
    String loadingText = "Performing operation...",
    String successText = "Operation Success",
    String errorText = "Something went wrong...",
  }) async {
    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Center(child: Text("Executing Operation")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Making service call to $serviceName!",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );

    (bool, String) success = (false, "Unknown Error");

    try {
      success = await callRosService(serviceName);
    } catch (e) {
      success = (false, "Unknown Error");
    }

    if (!context.mounted) return;

    Navigator.of(context).pop(); // close loading
    if (!success.$1) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              Spacer(),
              Text("Error"),
              Spacer(),
            ],
          ),
          content: Text(success.$2),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Center(
            child: Text(
              "Success",
              style: Theme.of(
                context,
              ).textTheme.displayMedium!.copyWith(color: Colors.green),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                successText,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              Text(
                "NOTE: A success response only means that ROS responded to our service call,\nnot that the underlying operation was successful.",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<(bool, String msg)> callRosService(String serviceName) {
    final completer = Completer<(bool, String)>();

    ros.createService(serviceName, (acknowledged, json) {
      completer.complete((
        acknowledged,
        json["msg"] != null ? json["msg"] as String : "",
      ));
    }).call();

    return completer.future;
  }

  void flushCANBuffer(BuildContext context) {
    runServiceAction(
      context: context,
      loadingText: "Flushing CAN buffer...",
      successText: "CAN Flush Operation Acknowledged",
      errorText: "CAN Flush Failed",
      serviceName: "/can/flush_bus",
    );
  }

  void restartCANBus(BuildContext context) => runServiceAction(
    context: context,
    serviceName: "/can/restart_bus",
    successText: "CAN Restart Operation Acknowledged",
    errorText: "CAN Restart Failed",
  );

  void reconfigureGPS(BuildContext context) => runServiceAction(
    context: context,
    serviceName: "/cell/reconfigure",
    successText: "GPS Reconfiguration Operation Acknowledged",
    errorText: "Unable to Send Service Call",
  );
}

class ActionsPage extends StatefulWidget {
  final ActionsPageViewModel model;

  const ActionsPage({super.key, required this.model});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  ActionsPageViewModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(spacing: 20, children: [Expanded(child: _buildCANSection())]),
    );
  }

  Widget _buildCANSection() {
    return Column(
      children: [
        Text(
          "System Operations",
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 20),

        // First row
        Expanded(
          child: Flex(
            spacing: 16,
            direction: Axis.horizontal,
            children: [
              Expanded(
                child: Flexible(
                  flex: 1,
                  child: HazardStripeBorder(
                    child: ActionTile(
                      title: "Flush CAN TX Buffer",
                      subTitle:
                          "This will flush the CAN TX buffer to allow messages to be sent again. \n\nCAUTION: UNIMPLEMENTED FOR SOCKETCAN!!!!",
                      icon: Icons.delete,
                      color: Colors.blue,
                      onPressed: () => model.flushCANBuffer(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Flexible(
                  flex: 1,
                  child: ActionTile(
                    title: "Restart CAN Network",
                    subTitle:
                        "This will reconstruct the whole CAN bus in code, and try to add motorA and motorB to the bus.",
                    icon: Icons.refresh,
                    color: Colors.orange,
                    onPressed: () => model.restartCANBus(context),
                  ),
                ),
              ),
              Expanded(
                child: Flexible(
                  flex: 1,
                  child: ActionTile(
                    title: "Resend GPS Commands",
                    subTitle:
                        "It will resend the cell_node serial commands to configure and wake up the GPS submodule.",
                    icon: Icons.satellite_alt,
                    color: Colors.green,
                    onPressed: () => model.reconfigureGPS(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActionTile extends StatelessWidget {
  final String title;
  final String subTitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const ActionTile({
    super.key,
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.blue.shade100,
          border: Border.all(color: Colors.black, width: 4),
        ),
        padding: EdgeInsetsGeometry.all(24),
        child: InkWell(
          splashColor: Colors.green,
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.black),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                subTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
