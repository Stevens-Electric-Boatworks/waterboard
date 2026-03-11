// Flutter imports:
import 'package:flutter/material.dart';

class HazardStripeBorder extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;

  const HazardStripeBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HazardPainter(radius: borderRadius, borderWidth: borderWidth),
      child: Padding(padding: EdgeInsets.all(borderWidth), child: child),
    );
  }
}

class _HazardPainter extends CustomPainter {
  final double radius;
  final double borderWidth;

  _HazardPainter({required this.radius, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    const stripeWidth = 6.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final path = Path()..addRRect(rrect);

    canvas.save();
    canvas.clipPath(path);

    final yellow = Paint()
      ..color = Colors.yellow.withAlpha(170)
      ..strokeWidth = stripeWidth;

    final black = Paint()
      ..color = Colors.black.withAlpha(170)
      ..strokeWidth = stripeWidth;

    for (double i = -size.height; i < size.width; i += stripeWidth * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        yellow,
      );

      canvas.drawLine(
        Offset(i + stripeWidth, 0),
        Offset(i + stripeWidth + size.height, size.height),
        black,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}
