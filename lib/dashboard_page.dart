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
import 'package:waterboard/messages.dart';
import 'package:waterboard/pages/electrics_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/services/internet_connection.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'widgets/ros_connection_state_widget.dart';
import 'widgets/time_text.dart';

enum ConnectionDialogType { noWebsocket, staleData }

class DashboardPageViewModel extends ChangeNotifier {
  int _currentPage = 0;
  ValueNotifier<ConnectionDialogType?> connectionDialogType = ValueNotifier(
    null,
  );
  final int totalPages = 6;
  final ROS ros;
  DashboardPageViewModel(this.ros);

  int get currentPage => _currentPage;
  Log get log => Log.instance;

  void init() {
    ros.startConnectionLoop();
    ros.connectionState.addListener(() {
      if (ros.connectionState.value == ROSConnectionState.noWebsocket) {
        showWebsocketDisconnectDialog();
      } else if (ros.connectionState.value == ROSConnectionState.staleData) {
        showStaleDataDialog();
      } else if (ros.connectionState.value == ROSConnectionState.connected) {
        //weird race condition fix
        closeAllDialogs();
        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) => {});
      }
    });
  }

  void moveToPage(int index) {
    if (0 <= index && index < totalPages) {
      _currentPage = index;
      notifyListeners();
    }
  }

  void moveToNextPage() {
    SharedPreferences.getInstance().then((value) {
      if (!(value.getBool("locked_layout") ?? false)) {
        moveToPage(min(_currentPage + 1, totalPages - 1));
      }
    });
  }

  void moveToPreviousPage() {
    SharedPreferences.getInstance().then((value) {
      if (!(value.getBool("locked_layout") ?? false)) {
        moveToPage(max(0, _currentPage - 1));
      }
    });
  }

  void showWebsocketDisconnectDialog() {
    connectionDialogType.value = ConnectionDialogType.noWebsocket;
  }

  void showStaleDataDialog() {
    connectionDialogType.value = ConnectionDialogType.staleData;
  }

  void closeAllDialogs() {
    connectionDialogType.value = null;
  }
}

class DashboardPage extends StatefulWidget {
  final DashboardPageViewModel model;

  const DashboardPage({super.key, required this.model});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Widget? dialogWidget;
  DialogRoute? _connectionAlertDialog;
  final PageController _pageController = PageController();
  late final MainDriverPageViewModel _mainDriverPageViewModel;
  late final ElectricsPageViewModel _electricsPageViewModel;
  late final RadiosPageViewModel _radiosPageViewModel;
  @override
  void initState() {
    super.initState();
    _mainDriverPageViewModel = MainDriverPageViewModel(ros: model.ros);
    _electricsPageViewModel = ElectricsPageViewModel(ros: model.ros);
    _radiosPageViewModel = RadiosPageViewModel(ros: model.ros, connection: InternetCheckerImpl());
    model.addListener(_onModelChanged);
    model.connectionDialogType.addListener(() {
      if (model.connectionDialogType.value ==
          ConnectionDialogType.noWebsocket) {
        showWebsocketDisconnectedDialog();
      } else if (model.connectionDialogType.value ==
          ConnectionDialogType.staleData) {
        showStaleDataDialog();
      } else {
        closeConnectionDialog();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = model.ros.connectionState.value;
      if (state == ROSConnectionState.noWebsocket) {
        showWebsocketDisconnectedDialog();
      } else if (state == ROSConnectionState.staleData) {
        showStaleDataDialog();
      }
    });
    model.init();
  }

  void _onModelChanged() {
    _pageController.animateToPage(
      model.currentPage,
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    model.removeListener(_onModelChanged);
    _pageController.dispose();
    model.dispose();
    _radiosPageViewModel.dispose();
    _electricsPageViewModel.dispose();
    _mainDriverPageViewModel.dispose();
    super.dispose();
  }

  DashboardPageViewModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyS) {
          PageUtils.showSettingsDialog(context, model.ros);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          model.moveToNextPage();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          model.moveToPreviousPage();
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
                  child: ClockText(
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              kIsWeb
                  ? Text(
                      "         WARNING: Web Support is Experimental!",
                      style: Theme.of(context).textTheme.titleSmall?.merge(
                        TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
          actions: [
            ValueListenableBuilder(
              valueListenable: model.ros.connectionState,
              builder: (context, value, child) => ROSConnectionStateWidget(
                value: value,
                fontSize: 18,
                iconSize: 18,
              ),
            ),
            SizedBox(width: 15),
            IconButton(
              onPressed: () => PageUtils.showSettingsDialog(context, model.ros),
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
            KeepAlivePage(
              child: MainDriverPage(model: _mainDriverPageViewModel),
            ),
            KeepAlivePage(child: ElectricsPage(model: _electricsPageViewModel)),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: RadiosPage(model: _radiosPageViewModel)),
            KeepAlivePage(child: Placeholder()),
            KeepAlivePage(child: Placeholder()),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 60,
          child: ListenableBuilder(
            listenable: model,
            builder: (BuildContext context, Widget? child) {
              return BottomNavigationBar(
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
                  BottomNavigationBarItem(
                    icon: Icon(Icons.error),
                    label: "Faults",
                  ),
                ],
                onTap: (value) {
                  model.moveToPage(value);
                },
                currentIndex: model.currentPage,
              );
            },
          ),
        ),
      ),
    );
  }

  void showWebsocketDisconnectedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      closeConnectionDialog();
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(
              child: Text(ConnectionDialogMessages.websocketDisconnectTitle),
            ),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              ConnectionDialogMessages.websocketDisconnectBody,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  PageUtils.showSettingsDialog(context, model.ros);
                },
                child: Text("Open Settings"),
              ),
              TextButton(
                onPressed: () {
                  closeConnectionDialog();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                child: Text(
                  "Close Dialog",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        },
      );
      Navigator.of(context).push(_connectionAlertDialog!);
    });
  }

  void showStaleDataDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      closeConnectionDialog();
      _connectionAlertDialog = DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Center(child: Text(ConnectionDialogMessages.staleDataTitle)),
            titleTextStyle: Theme.of(context).textTheme.displayLarge,
            content: Text(
              ConnectionDialogMessages.staleDataBody,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  PageUtils.showSettingsDialog(context, model.ros);
                },
                child: Text("Open Settings"),
              ),
              TextButton(
                onPressed: () {
                  closeConnectionDialog();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                child: Text(
                  "Close Dialog",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
}
