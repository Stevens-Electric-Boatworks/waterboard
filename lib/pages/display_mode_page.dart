import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/widgets/time_text.dart';

class DisplayModePage extends StatefulWidget {
  final ROSComms comms;

  const DisplayModePage({super.key, required this.comms});

  @override
  State<DisplayModePage> createState() => _DisplayModePageState();
}

class _DisplayModePageState extends State<DisplayModePage> {
  late final List<Widget> slides = [
    logo_time_slide(),
    // sponsors_slide()
  ];

  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 10), (timer) {
      if(!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentSlide = (_currentSlide + 1) % slides.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: logo_time_slide(),
      // body: slides[_currentSlide]
    );
  }

  Widget logo_time_slide() {
    return Container(
      color: Color.fromRGBO(72, 67, 63, 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 1100,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
                  child: Image.asset("assets/control_systems_logo.png"),
                ),
              ),
              ClockText(
                style: TextStyle(
                  color: Color.fromARGB(255, 206, 206, 206),
                  fontWeight: FontWeight.w700,
                  fontSize: 192,
                ),
              ),
              SizedBox(height: 100,),
              ValueListenableBuilder(
                valueListenable: widget.comms.connectionState,
                builder: (context, value, child) => get_connection_status_widget(value),
              )

            ],
          ),
        ],
      ),
    );
  }

  Widget get_connection_status_widget(ConnectionState value) {
    final TextStyle style = TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w700,
    );
    final double iconSize = 52;
    if(value == ConnectionState.connected) {
      return Row(
        children: [
          Icon(Icons.wifi,color: Colors.green, size: iconSize,),
          Text(" Connected", style: style.merge(TextStyle(color: Colors.green)),)
        ],
      );
    }
    else if(value == ConnectionState.noROSBridge) {
      return Row(
        children: [
          Icon(Icons.wifi_off,color: Colors.yellow, size: iconSize,),
          Text(" Stale Data", style: style.merge(TextStyle(color: Colors.yellow)),)
        ],
      );
    }
    else if(value == ConnectionState.noWebsocket) {
      return Row(
        children: [
          Icon(Icons.wifi_off,color: Colors.red, size: iconSize,),
          Text(" No ROSBridge Connection", style: style.merge(TextStyle(color: Colors.red)),)
        ],
      );
    }
    else {
      return Row(
        children: [
          Icon(Icons.question_mark, size: iconSize ),
          Text("Unknown", style: style,)
        ],
      );
    }
  }

  Widget sponsors_slide() {
    return Center(child: Text("Slide 2"));
  }
}
