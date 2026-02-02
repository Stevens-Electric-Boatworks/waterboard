import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:text_gradiate/text_gradiate.dart';
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/widgets/time_text.dart';

class StandbyMode extends StatefulWidget {
  final ROSComms comms;

  const StandbyMode({super.key, required this.comms});

  @override
  State<StandbyMode> createState() => _StandbyModeState();
}

class _StandbyModeState extends State<StandbyMode> {
  late final List<(Widget Function(), int)> slides = [
    (() => logo_time_slide(), 20),
    (() => sponsors_slide(), 10)
  ];

  late Timer _timer;

  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer(Duration(seconds: slides[_currentSlide].$2), _timerCallback);
  }

  void _timerCallback() {
    if (!mounted) {
      _timer.cancel();
      return;
    }
    setState(() {
      print("updating slideshow");
      _currentSlide = (_currentSlide + 1) % slides.length;
      _timer = Timer(Duration(seconds: slides[_currentSlide].$2), _timerCallback);
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
      // body: sponsors_slide(),
      body: slides[_currentSlide].$1()
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
              SizedBox(height: 100),
              ValueListenableBuilder(
                valueListenable: widget.comms.connectionState,
                builder: (context, value, child) =>
                    getConnectionStatusWidget(value, 52, 52),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget getConnectionStatusWidget(
    ConnectionState value,
    double fontSize,
    double iconSize,
  ) {
    final TextStyle style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    if (value == ConnectionState.connected) {
      return Row(
        children: [
          Icon(Icons.wifi, color: Colors.green, size: iconSize),
          Text(
            " Connected",
            style: style.merge(TextStyle(color: Colors.green)),
          ),
        ],
      );
    } else if (value == ConnectionState.noROSBridge) {
      return Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.yellow, size: iconSize),
          Text(
            " Stale Data",
            style: style.merge(TextStyle(color: Colors.yellow)),
          ),
        ],
      );
    } else if (value == ConnectionState.noWebsocket) {
      return Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red, size: iconSize),
          Text(
            " No ROSBridge Connection",
            style: style.merge(TextStyle(color: Colors.red)),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.question_mark, size: iconSize),
          Text("Unknown", style: style),
        ],
      );
    }
  }

  Widget sponsors_slide() {
    TextStyle? theme = Theme.of(context).textTheme.displayLarge?.merge(
      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
    return Container(
      color: Color.fromRGBO(72, 67, 63, 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //"our sponsors"
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
                child: Text(
                  "Our Sponsors",
                  style: theme?.merge(TextStyle(fontSize: 64)),
                ),
              ),
              SizedBox(height: 25),
              //Plat Sponsors
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Color.fromRGBO(85, 81, 76, 1.0),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextGradiate(
                          text: Text(
                            "Platinum ",
                            style: theme?.merge(TextStyle(fontSize: 48)),
                          ),
                          colors: [
                            Color.fromRGBO(225, 232, 238, 1.0),
                            Color.fromRGBO(190, 205, 214, 1.0),
                          ],
                        ),
                        Text(
                          "Sponsors",
                          style: theme?.merge(TextStyle(fontSize: 48)),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      children: [
                        buildSponsorCard(
                          "plat/asne.png",
                          "American Society of\n Naval Engineers",
                          imageWidth: 150,
                        ),
                        SizedBox(width: 75),
                        buildSponsorCard(
                          "plat/private.png",
                          "Private Sponsor",
                          imageWidth: 175,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  //Gold Sponsors
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Color.fromRGBO(85, 81, 76, 1.0),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            TextGradiate(
                              text: Text(
                                "Gold ",
                                style: theme?.merge(TextStyle(fontSize: 40)),
                              ),
                              colors: [
                                Color.fromRGBO(230, 189, 55, 1.0),
                                Color.fromRGBO(211, 175, 55, 0.7),
                              ],
                            ),
                            Text(
                              "Sponsor",
                              style: theme?.merge(TextStyle(fontSize: 40)),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        buildSponsorCard(
                          "gold/sname.png",
                          "Society of Naval Architects and Marine Engineers\nStevens Chapter",
                          imageWidth: 150,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 40),
                  //Silver Sponsor
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Color.fromRGBO(85, 81, 76, 1.0),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            TextGradiate(
                              text: Text(
                                "Silver ",
                                style: theme?.merge(TextStyle(fontSize: 40)),
                              ),
                              colors: [
                                Color.fromRGBO(190, 192, 194, 1.0),
                                Color.fromRGBO(112, 112, 111, 1.0),
                              ],
                            ),
                            Text(
                              "Sponsor",
                              style: theme?.merge(TextStyle(fontSize: 40)),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        buildSponsorCard(
                          "silver/dhx.png",
                          "DHX Machines",
                          imageWidth: 450,
                          cardHeight: 200
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSponsorCard(String assetPath, String name, {double? imageWidth, double? cardHeight} ) {
    TextStyle? theme = Theme.of(
      context,
    ).textTheme.displayLarge?.merge(TextStyle(color: Colors.white));
    return SizedBox(
      height: cardHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: imageWidth,
            child: Image.asset("assets/sponsors/$assetPath"),
          ),
          SizedBox(height: 12),
          Text(
            name,
            style: theme?.merge(TextStyle(fontSize: 20)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
