import 'package:flutter/material.dart';
import 'package:waterboard/keyboard/top_keys.dart';

import '../engine.dart';
import 'bottom_keys.dart';
import 'directional_keys.dart';
import 'fire_key.dart';

class PortraitKeyboard extends StatefulWidget {
  const PortraitKeyboard({super.key});

  @override
  State<PortraitKeyboard> createState() => _PortraitKeyboardState();  
}

class _PortraitKeyboardState extends State<PortraitKeyboard> {
  Engine engine = Engine();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SystemKeys(),
            NumericKeys(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DirectionalKeys(),
                FireKey()
              ]
            ),
            BottomKeys()
          ]
        )
      )
    );
  }
}