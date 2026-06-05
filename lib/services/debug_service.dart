import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugService {
  static final List<String> _logs = [];

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _logs.add(logMessage);
    if (kDebugMode || kIsWeb) print(logMessage);
  }

  static List<String> getLogs() => List.from(_logs);

  static void clear() => _logs.clear();

  static String getAllLogs() => _logs.join('\n');

  static void showLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Debug Logs'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: [
              Text(getAllLogs(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
