import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:collection/collection.dart';
// Based off of the Elastic hotkey manager -> https://github.com/Gold872/elastic_dashboard/blob/main/lib/services/hotkey_manager.dart
class HotKeyManager {

  bool _initialized = false;
  final List<LogicalKeyboardKey> _hotKeyList = [];
  final Map<LogicalKeyboardKey, void Function()> _callbackMap = {};

  void _init() {
    HardwareKeyboard.instance.addHandler(_handleRawKeyEvent);
    _initialized = true;
  }

  @visibleForTesting
  void tearDown() {
    _initialized = false;
    _hotKeyList.clear();
    _callbackMap.clear();
  }

  bool _handleRawKeyEvent(KeyEvent value) {
    if (value is KeyUpEvent) {
      if (value is KeyRepeatEvent) return false;
      LogicalKeyboardKey? hotKey = _hotKeyList.firstWhereOrNull((e) {
        if (value.logicalKey != e) {
          return false;
        }
        return true;
      });

      if (hotKey != null) {
        var callback = _callbackMap[hotKey];
        if (callback != null) {
          callback();
          return true;
        }
      } else {
        return false;
      }
    }
    return false;
  }

  List<LogicalKeyboardKey> get registeredHotKeyList => _hotKeyList;

  void register(LogicalKeyboardKey shortcut, {void Function()? callback}) {
    if (!_initialized) _init();

    if (callback != null) {
      _callbackMap.update(
        shortcut,
            (_) => callback,
        ifAbsent: () => callback,
      );
    }
    _hotKeyList.add(shortcut);
  }

  void unregister(LogicalKeyboardKey hotKey) {
    if (!_initialized) _init();

    if (_callbackMap.containsKey(hotKey)) {
      _callbackMap.remove(hotKey);
    }

    _hotKeyList.removeWhere((e) => e == hotKey);
  }

  void unregisterAll() {
    if (!_initialized) _init();

    _callbackMap.clear();
    _hotKeyList.clear();
  }

  Future<void> resetKeysPressed() async {
    await HardwareKeyboard.instance.syncKeyboardState();
  }
}