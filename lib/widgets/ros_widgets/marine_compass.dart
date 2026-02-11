// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/widgets/ros_listenable_widget.dart';

import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class ROSCompassDataSource {
  final ROSSubscription sub;
  final double Function(Map<String, dynamic> json) valueBuilder;

  ROSCompassDataSource({required this.sub, required this.valueBuilder});
}
class MarineCompass extends StatelessWidget {
  final double size;
  final ROSCompassDataSource dataSource;

  const MarineCompass({
    super.key,
    this.size = 270,
    required this.dataSource
  });

  @override
  Widget build(BuildContext context) {
    return ROSListenable(
      valueNotifier: dataSource.sub.notifier,
      noDataBuilder: (context) => _buildCompass(0, context),
      builder: (context, value) => _buildCompass(dataSource.valueBuilder(value), context),
    );
  }

  Widget _buildCompass(double heading, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _MarineCompassPainter(heading % 360)),
        ),
        SizedBox(height: 5),
        Text("$heading°", style: Theme.of(context).textTheme.displayMedium),
        Text("Track", style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _MarineCompassPainter extends CustomPainter {
  final double heading;

  _MarineCompassPainter(this.heading);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    canvas.drawCircle(
      center,
      radius - 2,
      circlePaint
        ..style = PaintingStyle.fill
        ..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      radius - 2,
      circlePaint
        ..style = PaintingStyle.stroke
        ..color = Colors.black,
    );

    for (int deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 30 == 0;
      final tickLength = isMajor ? 14.0 : 7.0;
      tickPaint.strokeWidth = isMajor ? 3 : 1.5;

      final angle = (deg - 90) * pi / 180;
      final start = Offset(
        center.dx + (radius - tickLength - 6) * cos(angle),
        center.dy + (radius - tickLength - 6) * sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 6) * cos(angle),
        center.dy + (radius - 6) * sin(angle),
      );

      canvas.drawLine(start, end, tickPaint);
    }

    const labels = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};

    labels.forEach((deg, label) {
      final angle = (deg - 90) * pi / 180;
      final offset = Offset(
        center.dx + (radius - 32) * cos(angle),
        center.dy + (radius - 32) * sin(angle),
      );

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    });

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((heading - 90) * pi / 180);

    final stemPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(-10, 0), Offset(radius * 0.45, 0), stemPaint);

    final path = Path()
      ..moveTo(radius * 0.55, 0)
      ..lineTo(radius * 0.45, -10)
      ..lineTo(radius * 0.45, 10)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.red);

    canvas.restore();

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _MarineCompassPainter oldDelegate) {
    return oldDelegate.heading != heading;
  }
}
