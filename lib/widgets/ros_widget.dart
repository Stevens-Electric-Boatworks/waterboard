// Flutter imports:
import 'package:flutter/material.dart';

class WithData<T> extends StatelessWidget {
  final T? data;
  final Widget Function(T data) builder;
  final Widget empty;

  const WithData({
    super.key,
    required this.data,
    required this.builder,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) return empty;
    return builder(data as T);
  }
}
