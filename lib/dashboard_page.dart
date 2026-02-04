// Dart imports:

// Flutter imports:
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterboard/pages/electrics_page.dart';

// Package imports:
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/page_utils.dart';

// Project imports:
import 'package:waterboard/services/ros_comms.dart';
import 'package:waterboard/settings/settings_dialog.dart';

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
  DialogRoute? _connectionAlertDialog;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    widget.comms.connectionState.addListener(() {
      if (widget.comms.connectionState.value == ConnectionState.noWebsocket) {
        showWebsocketDisconnectedDialog();
      } else if (widget.comms.connectionState.value ==
          ConnectionState.noROSBridge) {
        showROSBridgeDisconnectedDialog();
      } else if (widget.comms.connectionState.value ==
          ConnectionState.connected) {
        //weird race condition fix
        Timer(Duration(milliseconds: 200), () {
          if (widget.comms.connectionState.value == ConnectionState.connected) {
            closeConnectionDialog();
          }
        });
      }
    });
    widget.comms.startConnectionRoutine();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = widget.comms.connectionState.value;
      if (state == ConnectionState.noWebsocket) {
        showWebsocketDisconnectedDialog();
      } else if (state == ConnectionState.noROSBridge) {
        showROSBridgeDisconnectedDialog();
      }
    });
  }

  bool get isOnMainPage {
    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
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
          children: [
            KeepAlivePage(child: MainDriverPage(comms: widget.comms)),
            KeepAlivePage(child: ElectricsPage(comms: widget.comms)),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: Placeholder()),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 60,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.sports_motorsports), label: "Primary",),
              BottomNavigationBarItem(icon: Icon(Icons.electric_bolt), label: "Electric"),
              BottomNavigationBarItem(icon: Icon(Icons.water_rounded), label: "Motors"),
              BottomNavigationBarItem(icon: Icon(Icons.connect_without_contact), label: "Connectivity"),
              BottomNavigationBarItem(icon: Icon(Icons.code), label: "Software"),
              BottomNavigationBarItem(icon: Icon(Icons.error), label: "Faults"),
            ],
            currentIndex: _pageController.hasClients ? _currentPage : 0,
          ),
        ),
      ),
    );
  }

  void showWebsocketDisconnectedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      closeConnectionDialog();
      if (!isOnMainPage) return;
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(child: Text("ROSBridge Websocket Disconnected")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              "The websocket was unable to be initialized to connect to ROSBridge, but nothing is known of the state of ROSBridge directly.\nIt is recommended to reboot the Raspberry Pi.",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  PageUtils.showSettingsDialog(context, widget.comms);
                },
                child: Text("Open Settings"),
              ),
            ],
          );
        },
      );
      Navigator.of(context).push(_connectionAlertDialog!);
    });
  }

  void showROSBridgeDisconnectedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      closeConnectionDialog();
      if (!isOnMainPage) return;
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(child: Text("ROSBridge Data Stale")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              "The websocket is initialized, but there is stale data from ROSBridge. \nThis means that the ROS Control System is likely down.",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  PageUtils.showSettingsDialog(context, widget.comms);
                },
                child: Text("Open Settings"),
              ),
            ],
          );
        },
      );
      Navigator.of(context).push(_connectionAlertDialog!);
    });
  }

  void closeConnectionDialog() {
    if (_connectionAlertDialog != null) {
      Navigator.of(context).removeRoute(_connectionAlertDialog!);
      _connectionAlertDialog = null;
    }
  }

  void moveToNextPage() {
    SharedPreferences.getInstance().then((value) {
      if(!(value.getBool("locked_layout") ?? false)) {
        setState(() {
          _currentPage = min(_currentPage + 1, _totalPages - 1);
          _pageController.animateToPage(
            _currentPage,
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        });
      }
    },);
  }

  void moveToPreviousPage() {
    SharedPreferences.getInstance().then((value) {
      if(!(value.getBool("locked_layout") ?? false)) {
        setState(() {
          _currentPage = max(0, _currentPage - 1);
          _pageController.animateToPage(
            _currentPage,
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        });
      }
    },);
  }
}
