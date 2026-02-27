// Dart imports:

// Flutter imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:latlong2/latlong.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';
import 'package:waterboard/widgets/ros_listenable_widget.dart';

class ROSCompassDataSource {
  final ROSSubscription sub;
  final double Function(Map<String, dynamic> json) valueBuilder;

  ROSCompassDataSource({required this.sub, required this.valueBuilder});
}

class MarineCompass extends StatelessWidget {
  final double size;
  final ROSCompassDataSource dataSource;

  const MarineCompass({super.key, this.size = 270, required this.dataSource});

  @override
  Widget build(BuildContext context) {
    return ROSListenable(
      subscription: dataSource.sub,
      noDataBuilder: (context) => _buildCompass(0, context),
      builder: (context, value) =>
          _buildCompass(dataSource.valueBuilder(value), context),
    );
  }

  Widget _buildCompass(double heading, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.all(8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                width: constraints.maxHeight,
                child: Stack(
                  children: [
                    Transform.rotate(
                      angle: -degToRadian(heading),
                      child: Image.asset("assets/compass/compass.png"),
                    ),
                    Image.asset("assets/compass/overlay.png"),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(width: 100,),
        Text(
          "${heading.round()}°",
          style: Theme.of(context).textTheme.displayLarge,
        ),
        Text("Track", style: Theme.of(context).textTheme.displaySmall)
      ],
    );
  }
}
