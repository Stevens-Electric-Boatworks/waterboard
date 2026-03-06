import 'package:flutter/material.dart';

class DelayedWidget extends StatefulWidget {
  final Widget child;
  const DelayedWidget({super.key, required this.child});

  @override
  State<DelayedWidget> createState() => _DelayedWidgetState();
}

class _DelayedWidgetState extends State<DelayedWidget> {
  bool _isEnabled = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      if(!mounted) return;
      setState(() {
        _isEnabled = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_isEnabled) {
      return widget.child;
    }
    return IgnorePointer(
      ignoring: true,
      child: Chip(
        label: Text("Enabling in 3 seconds..."),
      ),
    );
  }
}
