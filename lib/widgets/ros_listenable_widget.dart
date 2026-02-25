// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:waterboard/services/ros_comms/ros_subscription.dart';

class ROSListenable extends StatefulWidget {
  final ROSSubscription subscription;
  final Widget Function(BuildContext context, Map<String, dynamic> value)
  builder;
  final Widget Function(BuildContext context) _noDataBuilder;

  const ROSListenable({
    super.key,
    required this.subscription,
    required this.builder,
    required Widget Function(BuildContext) noDataBuilder,
  }) : _noDataBuilder = noDataBuilder;

  @override
  State<ROSListenable> createState() => _ROSListenableState();
}

class _ROSListenableState extends State<ROSListenable> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: widget.subscription.notifier,
      builder: (context, value, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(child: getWidget(value)),
            if (widget.subscription.isStale)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomPaint(painter: StaleXPainter()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget getWidget(Map<String, dynamic> value) {
    if (value.isEmpty || value == {}) {
      return widget._noDataBuilder(context);
    }
    return widget.builder(context, value);
  }
}

class StaleXPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  StaleXPainter({this.color = Colors.red, this.strokeWidth = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final scale = size.shortestSide / 200;
    paint.strokeWidth = strokeWidth * scale.clamp(1, 5.0);

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);

    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
