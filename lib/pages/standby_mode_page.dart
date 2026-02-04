// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
// Package imports:
import 'package:text_gradiate/text_gradiate.dart';
// Project imports:
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/widgets/time_text.dart';

import '../widgets/ros_connection_state_widget.dart';

class StandbyMode extends StatefulWidget {
  final ROSComms comms;

  const StandbyMode({super.key, required this.comms});

  @override
  State<StandbyMode> createState() => _StandbyModeState();
}

class _StandbyModeState extends State<StandbyMode> {
  late final List<(Widget Function(), int)> slides = [
    (() => logoAndTimeSlide(), 20),
    (() => sponsorsSlide(), 10),
  ];
  late Timer _timer;
  bool _paused = false;
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
    if (_paused) return;
    setState(() {
      _currentSlide = (_currentSlide + 1) % slides.length;
      _timer = Timer(
        Duration(seconds: slides[_currentSlide].$2),
        _timerCallback,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_back_rounded),
            ),
            if (_paused) Flexible(child: Icon(Icons.pause)),
          ],
        ),
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              setState(() {
                _currentSlide = (_currentSlide + 1) % slides.length;
              });
              _timer.cancel();
              _timer = Timer(
                Duration(seconds: slides[_currentSlide].$2),
                _timerCallback,
              );
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              setState(() {
                _currentSlide = (_currentSlide - 1) % slides.length;
              });
              _timer.cancel();
              _timer = Timer(
                Duration(seconds: slides[_currentSlide].$2),
                _timerCallback,
              );
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.keyP) {
              setState(() {
                _paused = !_paused;
              });
            }
          }

          return KeyEventResult.ignored;
        },
        // child: logoAndTimeSlide()
        child: slides[_currentSlide].$1(),
      ),
    );
  }

  Widget logoAndTimeSlide() {
    return Container(
      color: Color.fromRGBO(72, 67, 63, 1.0),
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 340,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(85, 81, 76, 1.0),
                borderRadius: BorderRadius.circular(64),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 16),
                ],
              ),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width,
                height: 1000,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 1100,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
                      child: Image.asset("assets/control_systems_logo.png"),
                    ),
                  ),
                  SizedBox(height: 50),
                  ClockText(
                    style: TextStyle(
                      color: Color.fromARGB(255, 206, 206, 206),
                      fontWeight: FontWeight.w700,
                      fontSize: 128,
                    ),
                  ),
                  SizedBox(height: 25),
                  Spacer(),
                  ValueListenableBuilder(
                    valueListenable: widget.comms.connectionState,
                    builder: (context, value, child) =>
                        ROSConnectionStateWidget(
                          value: value,
                          fontSize: 82,
                          iconSize: 82,
                        ),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget sponsorsSlide() {
    TextStyle? theme = Theme.of(context).textTheme.displayLarge?.merge(
      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
    return Container(
      color: Color.fromRGBO(72, 67, 63, 1.0),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(85, 81, 76, 1.0),
                borderRadius: BorderRadiusGeometry.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(125), blurRadius: 5),
                ],
              ),
              padding: EdgeInsets.fromLTRB(12, 18, 18, 12),
              child: SizedBox(
                width: 300,
                child: Image.asset("assets/control_systems_logo.png"),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //"our sponsors"
                  SizedBox(height: 15),
                  Center(
                    child: Text(
                      "Our Sponsors",
                      style: theme?.merge(
                        TextStyle(
                          fontSize: 64,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(150),
                              blurRadius: 15,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  //Plat Sponsors
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Color.fromRGBO(85, 81, 76, 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(125),
                          blurRadius: 10,
                        ),
                      ],
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
                        Row(
                          children: [
                            buildSponsorCard(
                              "plat/asne.png",
                              "American Society of\n Naval Engineers",
                              imageWidth: 100,
                              cardHeight: 175,
                            ),
                            SizedBox(width: 75),
                            buildSponsorCard(
                              "plat/private.png",
                              "Private Sponsor",
                              imageWidth: 100,
                              cardHeight: 175,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  Row(
                    children: [
                      //Gold Sponsors
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color.fromRGBO(85, 81, 76, 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(125),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                TextGradiate(
                                  text: Text(
                                    "Gold ",
                                    style: theme?.merge(
                                      TextStyle(fontSize: 40),
                                    ),
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
                              imageWidth: 125,
                              cardHeight: 180,
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(125),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                TextGradiate(
                                  text: Text(
                                    "Silver ",
                                    style: theme?.merge(
                                      TextStyle(fontSize: 40),
                                    ),
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
                              imageWidth: 350,
                              cardHeight: 180,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  ValueListenableBuilder(
                    valueListenable: widget.comms.connectionState,
                    builder: (context, value, child) =>
                        ROSConnectionStateWidget(
                          value: value,
                          fontSize: 52,
                          iconSize: 52,
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

  Widget buildSponsorCard(
    String assetPath,
    String name, {
    double? imageWidth,
    double? cardHeight,
  }) {
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
