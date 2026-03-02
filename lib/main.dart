// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:window_manager/window_manager.dart';

// Project imports:
import 'package:waterboard/services/services.dart';
import 'package:waterboard/waterboard_colors.dart';
import 'dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    if ((Platform.isWindows || Platform.isMacOS || kDebugMode) &&
        !Platform.isLinux) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = WindowOptions(
        center: true,
        title: "Waterboard Driver Dashboard | Stevens Electric Boatworks",
        backgroundColor: Colors.blue,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }
  Services services = Services();
  await services.initialize();
  services.logger.info(
    "Finished app services initialization. Running flutter...",
  );
  runApp(WaterboardApp(services));
}

class WaterboardApp extends StatefulWidget {
  final Services services;

  const WaterboardApp(this.services, {super.key});

  @override
  State<WaterboardApp> createState() => _WaterboardAppState();
}

class _WaterboardAppState extends State<WaterboardApp> {
  late DashboardPageViewModel _mainPageViewModel;

  @override
  void initState() {
    super.initState();
    _mainPageViewModel = DashboardPageViewModel(widget.services);
  }

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
        ),
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: Colors.blue.shade500,
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.black,
            selectedForegroundColor: Colors.black,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.black,
          ),
        ),
        fontFamily: "inter",
      ),
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        final scale = width / 1200;

        final baseTheme = Theme.of(context);

        return Theme(
          data: baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(
              fontSizeFactor: scale.clamp(0.5, 1.5),
            ),
          ),
          child: child!,
        );
      },
      home: DashboardPage(model: _mainPageViewModel),
    );
  }
}
