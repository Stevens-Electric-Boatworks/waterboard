import 'package:flutter/material.dart';
import 'package:waterboard/widgets/ros_listenable_widget.dart';
import 'package:waterboard/services/ros_comms.dart';
import 'package:window_manager/window_manager.dart';

import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();
  final windowSize = Size(1200, 800);
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
  ROSComms comms = ROSComms();
  comms.connect_to_websocket();
  runApp(MyApp(comms));
}

class MyApp extends StatelessWidget {
  final ROSComms comms;
  const MyApp(this.comms, {super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waterboard',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarThemeData(
          backgroundColor: Colors.grey.shade300
        )
      ),
      home: MainPage(comms: comms,)
    );
  }
}
