// Dart imports:

// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/pages/electrics_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'widgets/ros_connection_state_widget.dart';
import 'widgets/time_text.dart';

class MainPage extends StatefulWidget {
  final ROS ros;

  const MainPage({super.key, required this.ros});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Widget? dialogWidget;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    widget.ros.startConnectionLoop();
  }

  bool get isOnMainPage {
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          PageUtils.showSettingsDialog(context, widget.ros);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          moveToNextPage();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          moveToPreviousPage();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Stevens Electric Boatworks",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.black),
                ),
                margin: EdgeInsets.all(4),
                child: Center(
                  child: ClockText(style: Theme.of(context).textTheme.titleSmall),
                ),
              ),
              kIsWeb ? Text("         WARNING: Web Support is Experimental!", style: Theme.of(context).textTheme.titleSmall?.merge(TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),) : Container()
            ],
          ),
          actions: [
            ValueListenableBuilder(
              valueListenable: widget.ros.connectionState,
              builder: (context, value, child) => ROSConnectionStateWidget(
                value: value,
                fontSize: 18,
                iconSize: 18,
              ),
            ),
            SizedBox(width: 15),
            IconButton(
              onPressed: () =>
                  PageUtils.showSettingsDialog(context, widget.ros),
              icon: Icon(Icons.settings),
            ),
          ],
          leadingWidth: 100,
          toolbarHeight: 35,
        ),
        body: PageView(
          controller: _pageController,
          scrollBehavior: ScrollBehavior().copyWith(
            physics: NeverScrollableScrollPhysics(),
            scrollbars: false,
            overscroll: false,
          ),
          children: [
            KeepAlivePage(child: MainDriverPage(ros: widget.ros)),
            KeepAlivePage(child: ElectricsPage(ros: widget.ros)),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: RadiosPage(ros: widget.ros)),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: Placeholder()),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_motorsports),
                label: "Primary",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.electric_bolt),
                label: "Electric",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.water_rounded),
                label: "Motors",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.radio), label: "Radios"),
              BottomNavigationBarItem(
                icon: Icon(Icons.code),
                label: "Software",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.error), label: "Faults"),
            ],
            currentIndex: _pageController.hasClients ? _currentPage : 0,
          ),
        ),
      ),
    );
  }

  void moveToNextPage() {
    SharedPreferences.getInstance().then((value) {
      if (!(value.getBool("locked_layout") ?? false)) {
        setState(() {
          _currentPage = min(_currentPage + 1, _totalPages - 1);
          _pageController.animateToPage(
            _currentPage,
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        });
      }
    });
  }

  void moveToPreviousPage() {
    SharedPreferences.getInstance().then((value) {
      if (!(value.getBool("locked_layout") ?? false)) {
        setState(() {
          _currentPage = max(0, _currentPage - 1);
          _pageController.animateToPage(
            _currentPage,
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        });
      }
    });
  }
}
