import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static final List<String> _logs = [];
  static const int _maxLogs = 500;

  static List<String> get logs => List.unmodifiable(_logs);

  static void info(String tag, String message) {
    _addLog('INFO', tag, message);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final fullMsg = error != null ? '$message | Error: $error' : message;
    _addLog('ERROR', tag, fullMsg);
  }

  static void warning(String tag, String message) {
    _addLog('WARN', tag, message);
  }

  static void _addLog(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logLine = '[$timestamp] [$level] [$tag] $message';
    _logs.add(logLine);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    debugPrint(logLine);
  }

  static void clear() {
    _logs.clear();
  }

  static String exportLogs() => _logs.join('\n');
}
