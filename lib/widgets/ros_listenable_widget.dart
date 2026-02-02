import 'dart:async';
import 'package:flutter/material.dart';

class ROSListenable extends StatefulWidget {
  final ValueNotifier<Map<String, dynamic>> valueNotifier;
  final Widget Function(BuildContext context, Map<String, dynamic> value) builder;

  const ROSListenable({
    super.key,
    required this.valueNotifier,
    required this.builder,
  });

  @override
  State<ROSListenable> createState() => _ROSListenableState();
}

class _ROSListenableState extends State<ROSListenable> {
  static const staleAfter = Duration(seconds: 2);

  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();

    widget.valueNotifier.addListener(() {
      _lastUpdate = DateTime.now();
    });

    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
          (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  bool get _isStale =>
      DateTime.now().difference(_lastUpdate) > staleAfter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: widget.valueNotifier,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return const CircularProgressIndicator();
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              child: widget.builder(context, value),
            ),

            if (_isStale)
              Positioned.fill(
                child: IgnorePointer(
                  child: const Icon(
                    Icons.close_sharp,
                    color: Colors.red,
                    size: 350,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
