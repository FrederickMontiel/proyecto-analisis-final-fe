import 'package:flutter/foundation.dart';

class DebugService {
  static final List<String> _logs = [];

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _logs.add(logMessage);
    if (kDebugMode) print(logMessage);
  }

  static List<String> getLogs() => List.from(_logs);

  static void clear() => _logs.clear();

  static String getAllLogs() => _logs.join('\n');
}
