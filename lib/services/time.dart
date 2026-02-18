// Package imports:
import 'package:clock/clock.dart';

class Time {
  Clock clock = Clock();
  static Time instance = Time._internal();

  Time._internal();
}
