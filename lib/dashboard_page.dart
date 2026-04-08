// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:waterboard/pages/logs_page.dart';
import 'package:waterboard/pages/main_driver_page.dart';
import 'package:waterboard/pages/motors_page.dart';
import 'package:waterboard/pages/page_utils.dart';
import 'package:waterboard/pages/radios_page.dart';
import 'package:waterboard/pages/system_page.dart';
import 'package:waterboard/pref_keys.dart';
import 'package:waterboard/schemas/cell_message_schema.dart';
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/services/services.dart';
import 'package:waterboard/widgets/custom_app_bar_widget.dart';
import 'package:waterboard/widgets/ros_widgets/ros_cell_connection_widget.dart';

enum ConnectionDialogType { noWebsocket, staleData }

mixin DashboardPageStateMixin on State<DashboardPage> {
  void openSettingsDialog() {
    if (mounted) widget.model.openSettingsDialog(context);
  }
}

class DashboardPageViewModel extends ChangeNotifier {
  int _currentPage = 0;
  final int totalPages = 5;
  final Services services;

  DashboardPageViewModel(this.services);

  late final ROSCellDataSource rosCellDataSource;

  DashboardPageStateMixin? _state;

  DashboardPageStateMixin? get state => _state;

  ROS get ros => services.ros;

  int get currentPage => _currentPage;

  Log get log => services.logger;

  SharedPreferences get _preferences => services.preferences;

  bool get layoutLocked => _preferences.getBool(PrefKeys.layoutLocked) ?? false;

  Future<void> init() async {
    ros.startConnectionLoop();
    rosCellDataSource = ROSCellDataSource(
      sub: ros.subscribe("/cell", staleDuration: 10_000),
      valueBuilder: (json) => CellMessageSchema.fromJson(json),
    );
    services.hotkeys.register(
      LogicalKeyboardKey.keyS,
      callback: () {
        state!.openSettingsDialog();
      },
    );
    services.hotkeys.register(
      LogicalKeyboardKey.arrowRight,
      callback: () {
        moveToNextPage();
      },
    );
    services.hotkeys.register(
      LogicalKeyboardKey.arrowLeft,
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

  void unlockLayout() {
    _preferences.setBool(PrefKeys.layoutLocked, false);
    onSettingsChange();
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
  final PageController _pageController = PageController();
  late final MainDriverPageViewModel _mainDriverPageViewModel;
  late final MotorsPageViewModel _electricsPageViewModel;
  late final RadiosPageViewModel _radiosPageViewModel;
  late final LogsPageViewModel _logsPageViewModel;
  late final SystemPageViewModel _systemPageViewModel;

  @override
  void initState() {
    super.initState();
    _mainDriverPageViewModel = MainDriverPageViewModel(ros: model.ros);
    _electricsPageViewModel = MotorsPageViewModel(ros: model.ros);
    _radiosPageViewModel = RadiosPageViewModel(services: model.services);
    _logsPageViewModel = LogsPageViewModel(services: model.services);
    _systemPageViewModel = SystemPageViewModel(services: model.services);
    model.addListener(_onModelChanged);
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
    return Focus(
      autofocus: false,
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: Scaffold(
        appBar: WaterboardAppBarWidget(
          services: model.services,
          layoutLocked: () => model.layoutLocked,
          onSettingsChanged: model.onSettingsChange,
          rosCellDataSource: model.rosCellDataSource,
          unlockLayout: model.unlockLayout,
        ),

        body: IgnorePointer(
          ignoring: model.layoutLocked,
          child: PageView(
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
              KeepAlivePage(child: MotorsPage(model: _electricsPageViewModel)),
              KeepAlivePage(child: RadiosPage(model: _radiosPageViewModel)),
              KeepAlivePage(child: LogsPage(model: _logsPageViewModel)),
              KeepAlivePage(child: SystemPage(model: _systemPageViewModel)),
            ],
          ),
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
                    icon: Icon(Icons.electrical_services),
                    label: "Motors",
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
                    icon: Icon(Icons.build),
                    label: "System",
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
    );
  }
}
