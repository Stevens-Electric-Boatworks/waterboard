import 'package:flutter/material.dart';

class ROSListenable extends StatelessWidget {
  final ValueNotifier<Map<String, dynamic>> valueNotifier;
  final Function(BuildContext context, Map<String, dynamic> value) builder;
  const ROSListenable({super.key, required this.valueNotifier, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: valueNotifier, builder: (context, value, _) {
      if(value.isEmpty) return CircularProgressIndicator();
      return builder(context, value);
    },);
  }
}
