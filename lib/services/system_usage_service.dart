// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Project imports:
import 'package:waterboard/services/log.dart';

class SystemInformation {
  final double cpuUtilPercent;
  final int totalMemMB;
  final int usedMemMB;
  final double memUsagePercent;
  final double totalDiskUsagePercent;
  final double diskFreeGB;
  final double rxMBPerSec;
  final double txMBPerSec;

  SystemInformation({
    required this.cpuUtilPercent,
    required this.totalMemMB,
    required this.usedMemMB,
    required this.memUsagePercent,
    required this.totalDiskUsagePercent,
    required this.diskFreeGB,
    required this.rxMBPerSec,
    required this.txMBPerSec,
  });

  @override
  String toString() {
    return 'SystemInformation{cpuUtilPercent: $cpuUtilPercent, totalMemMB: $totalMemMB, usedMemMB: $usedMemMB, memUsagePercent: $memUsagePercent, totalDiskUsagePercent: $totalDiskUsagePercent}';
  }
}

enum SystemDaemonState { unknown, starting, online, error }

class SystemUsageService {
  final Log log;
  Process? _process;
  final ValueNotifier<SystemDaemonState> daemonState = ValueNotifier(
    SystemDaemonState.unknown,
  );
  final ValueNotifier<SystemInformation?> systemInformation = ValueNotifier(
    null,
  );

  WebSocketChannel? _channel;

  StreamSubscription? _subscription;

  SystemUsageService({required this.log});

  void start() async {
    if (kIsWeb) {
      return;
    }
    daemonState.value = SystemDaemonState.starting;
    try {
      await _startProcess();
      await Future.delayed(const Duration(milliseconds: 800));
      _connect();
    } catch (e) {
      log.error("Failed to start system util daemon process", e);
      daemonState.value = SystemDaemonState.error;
    }
  }

  Future<(String, List<String>)> _extractExecutable() async {
    final tmpDir = await getTemporaryDirectory();
    final scriptPath = p.join(tmpDir.path, 'system_util_daemon.py');

    final scriptBytes = await rootBundle.load(
      'assets/sys_util/system_util_daemon.py',
    );
    await File(scriptPath).writeAsBytes(scriptBytes.buffer.asUint8List());

    final python = Platform.isWindows ? 'python' : 'python3';
    return (python, [scriptPath]);
  }

  Future<void> _startProcess() async {
    final executablePath = await _extractExecutable();

    _process = await Process.start(executablePath.$1, [
      ...executablePath.$2,
    ], mode: ProcessStartMode.normal);

    _process!.stdout.transform(utf8.decoder).listen((line) {
      log.info('[SysDaemon stdout] $line');
    });
    _process!.stderr.transform(utf8.decoder).listen((line) {
      log.error('[SysDaemon stderr] $line');
    });
  }

  void _connect() {
    final uri = Uri.parse('ws://127.0.0.1:9889');
    _channel = WebSocketChannel.connect(uri);
    daemonState.value = SystemDaemonState.online;

    _subscription = _channel!.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message as String) as Map<String, dynamic>;
          if (json.isEmpty) return;
          //sum up all network stats
          final interfaces = json["network"]["interfaces"];
          num totalTX = 0;
          num totalRX = 0;
          for (var interface in interfaces) {
            totalTX += interface["tx_bytes_per_sec"] as num;
            totalRX += interface["rx_bytes_per_sec"] as num;
          }

          var stats = SystemInformation(
            cpuUtilPercent: json["cpu"]["percent"] as double,
            totalMemMB: (json["memory"]["total_mb"] as double).toInt(),
            usedMemMB: (json["memory"]["used_mb"] as double).toInt(),
            memUsagePercent: json["memory"]["percent"] as double,
            totalDiskUsagePercent: json["disks"][0]["percent"] as double,
            diskFreeGB: (json["disks"][0]["free_mb"] as double) / 1000,
            rxMBPerSec: totalRX / 1e6,
            txMBPerSec: totalTX / 1e6,
          );
          daemonState.value = SystemDaemonState.online;
          systemInformation.value = stats;
        } catch (e) {
          // ignore: avoid_print
          log.error('[StatsDaemonService] parse error: $e');
        }
      },
      onError: (e) {
        daemonState.value = SystemDaemonState.error;
        log.error("[StatsDaemonService] There was an error.", e);
      },
      onDone: () {
        daemonState.value = SystemDaemonState.error;
        log.error("[StatsDaemonService] The connection was closed");
      },
    );
  }

  void dispose() {
    _process?.kill(ProcessSignal.sigkill);
    _subscription?.cancel();
  }
}
