import 'dart:async';
import 'package:flutter/material.dart';

class ClockText extends StatefulWidget {
  final TextStyle? style;
  const ClockText({super.key, required this.style});

  @override
  State<ClockText> createState() => _ClockTextState();
}

class _ClockTextState extends State<ClockText> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // DO NOT forget this or you’ll leak timers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int hour = _now.hour % 12;
    if (hour == 0) hour = 12;

    String two(int n) => n.toString().padLeft(2, '0');
    String amPm = _now.hour >= 12 ? 'PM' : 'AM';

    return Text(
      '$hour:${two(_now.minute)}:${two(_now.second)} $amPm',
      style: widget.style,
      softWrap: false,
    );
  }
}
