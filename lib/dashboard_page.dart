// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/messages.dart';
import 'package:waterboard/pages/doom_page.dart';
import 'package:waterboard/pages/electrics_page.dart';
import 'package:waterboard/pages/logs_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/pref_keys.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/custom_app_bar_widget.dart';

enum ConnectionDialogType { noWebsocket, staleData }

mixin DashboardPageStateMixin on State<DashboardPage> {
  void openSettingsDialog() {
    if (mounted) widget.model.openSettingsDialog(context);
  }
}

class DashboardPageViewModel extends ChangeNotifier {
  int _currentPage = 0;
  ValueNotifier<ConnectionDialogType?> connectionDialogType = ValueNotifier(
    null,
  );
  final int totalPages = 5;
  final Services services;
  DashboardPageViewModel(this.services);

  DashboardPageStateMixin? _state;
  DashboardPageStateMixin? get state => _state;

  ROS get ros => services.ros;
  int get currentPage => _currentPage;
  Log get log => services.logger;
  SharedPreferences get _preferences => services.preferences;

  bool get layoutLocked => _preferences.getBool(PrefKeys.layoutLocked) ?? false;

  Future<void> init() async {
    ros.startConnectionLoop();
    ros.connectionState.addListener(() {
      if (ros.connectionState.value == ROSConnectionState.noWebsocket) {
        showWebsocketDisconnectDialog();
      } else if (ros.connectionState.value == ROSConnectionState.staleData) {
        showStaleDataDialog();
      } else if (ros.connectionState.value == ROSConnectionState.connected) {
        WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) => closeAllDialogs(),
        );
      }
    });
    // services.hotkeys.register(
    //   LogicalKeyboardKey.keyS,
    //   callback: () {
    //     state!.openSettingsDialog();
    //   },
    // );
    services.hotkeys.register(
      LogicalKeyboardKey.comma,
      callback: () {
        moveToNextPage();
      },
    );
    services.hotkeys.register(
      LogicalKeyboardKey.period,
      callback: () {
        moveToPreviousPage();
      },
    );
  }

  void moveToPage(int index) {
    if (0 <= index && index < totalPages) {
      _currentPage = index;
      notifyListeners();
    }
  }

  void moveToNextPage() {
    if (!layoutLocked) {
      moveToPage(min(_currentPage + 1, totalPages - 1));
    }
  }

  void moveToPreviousPage() {
    if (!layoutLocked) {
      moveToPage(max(0, _currentPage - 1));
    }
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

  void openSettingsDialog(BuildContext context) {
    PageUtils.showSettingsDialog(context, services, () => onSettingsChange());
  }

  void onSettingsChange() {
    notifyListeners();
  }
}

class DashboardPage extends StatefulWidget {
  final DashboardPageViewModel model;

  const DashboardPage({super.key, required this.model});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with DashboardPageStateMixin {
  Widget? dialogWidget;
  DialogRoute? _connectionAlertDialog;
  final PageController _pageController = PageController();
  late final MainDriverPageViewModel _mainDriverPageViewModel;
  late final ElectricsPageViewModel _electricsPageViewModel;
  late final RadiosPageViewModel _radiosPageViewModel;
  late final LogsPageViewModel _logsPageViewModel;

  @override
  void initState() {
    super.initState();
    _mainDriverPageViewModel = MainDriverPageViewModel(ros: model.ros);
    _electricsPageViewModel = ElectricsPageViewModel(ros: model.ros);
    _radiosPageViewModel = RadiosPageViewModel(services: model.services);
    _logsPageViewModel = LogsPageViewModel(services: model.services);
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
    model._state = this;
    model.init();
  }

  void _onModelChanged() {
    setState(() {
      _pageController.jumpToPage(model.currentPage);
    });
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
    return AbsorbPointer(
      absorbing: model.layoutLocked,
      child: Focus(
        // autofocus: false,
        // canRequestFocus: false,
        // descendantsAreFocusable: false,
        child: Scaffold(
          appBar: WaterboardAppBarWidget(
            services: model.services,
            layoutLocked: () => model.layoutLocked,
            onSettingsChanged: model.onSettingsChange,
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
              KeepAlivePage(
                child: ElectricsPage(model: _electricsPageViewModel),
              ),
              KeepAlivePage(child: RadiosPage(model: _radiosPageViewModel)),
              KeepAlivePage(child: LogsPage(model: _logsPageViewModel)),
              KeepAlivePage(child: DoomPage()),
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
                      icon: Icon(Icons.radio),
                      label: "Radios",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notes),
                      label: "Logs",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.access_alarm_rounded),
                      label: "Doom",
                    ),
                  ],
                  onTap: (value) {
                    if (model.layoutLocked) return;
                    model.moveToPage(value);
                  },
                  currentIndex: model.currentPage,
                );
              },
            ),
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
                  if (model.layoutLocked) return;
                  model.openSettingsDialog(context);
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
                  if (model.layoutLocked) return;
                  model.openSettingsDialog(context);
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
