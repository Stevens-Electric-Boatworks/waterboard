// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:window_manager/window_manager.dart';

// Project imports:
import 'package:waterboard/services/log.dart';
import 'package:waterboard/services/ros_comms/ros.dart';
import 'package:waterboard/waterboard_colors.dart';
import 'dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    if ((Platform.isWindows || Platform.isMacOS || kDebugMode) &&
        !Platform.isLinux) {
      await windowManager.ensureInitialized();
      final windowSize = Size(1200, 820);
      WindowOptions windowOptions = WindowOptions(
        minimumSize: windowSize,
        maximumSize: windowSize,
        size: windowSize,
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }
  await Log.instance.initialize();
  ROS ros = ROS();
  runApp(MyApp(ros));
}

class MyApp extends StatelessWidget {
  final ROS ros;

  const MyApp(this.ros, {super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waterboard',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarThemeData(
          backgroundColor: WaterboardColors.containerBackground,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: WaterboardColors.containerBackground,
          unselectedLabelStyle: TextStyle(color: Colors.grey.shade600),
          selectedItemColor: Colors.red.shade800,

          // selectedLabelStyle: TextStyle(fontSize: 12),
        ),
        fontFamily: "inter",
      ),
      home: MainPage(ros: ros),
    );
  }
}
