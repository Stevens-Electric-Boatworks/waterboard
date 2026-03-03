import 'package:flutter/material.dart';
import 'package:waterboard/debug_vars.dart';

import '../doom.dart';
import '../keyboard/portrait_keyboard.dart';

class DoomPage extends StatelessWidget {
  const DoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    print("PATH: " + DebugVariables.WAD_Path);
    return SafeArea(
      child: Focus(
        autofocus: true,
        canRequestFocus: true,
        child: SizedBox(
          width: 900,
          height: 900,
          child: Doom(wadPath: DebugVariables.WAD_Path),
        ),
      ),
    );
  }
}
