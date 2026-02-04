// Dart imports:

// Dart imports:
import 'dart:async';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/pages/electrics_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/ros_comms.dart';

import 'widgets/ros_connection_state_widget.dart';
import 'widgets/time_text.dart';

class MainPage extends StatefulWidget {
  final ROSComms comms;

  const MainPage({super.key, required this.comms});

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
    widget.comms.startConnectionRoutine();
  }


  @override
  Widget build(BuildContext context) {
    // print(
    //   "current page: ${_pageController.hasClients ? _pageController.page!.toInt() : 0}",
    // );
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          PageUtils.showSettingsDialog(context, widget.comms);
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
          leading: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(color: Colors.black),
            ),
            margin: EdgeInsets.all(4),
            child: Center(
              child: ClockText(style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          actions: [
            ValueListenableBuilder(
              valueListenable: widget.comms.connectionState,
              builder: (context, value, child) => ROSConnectionStateWidget(
                value: value,
                fontSize: 18,
                iconSize: 18,
              ),
            ),
            SizedBox(width: 15),
            IconButton(
              onPressed: () =>
                  PageUtils.showSettingsDialog(context, widget.comms),
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
            KeepAlivePage(child: MainDriverPage(comms: widget.comms)),
            KeepAlivePage(child: ElectricsPage(comms: widget.comms)),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: RadiosPage()),
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
              BottomNavigationBarItem(
                icon: Icon(Icons.radio),
                label: "Radios",
              ),
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
