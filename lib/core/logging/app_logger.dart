import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String format() {
    final timeStr = timestamp.toIso8601String().substring(11, 23);
    final levelStr = level.name.toUpperCase().padRight(5);
    final errStr = error != null ? ' | Error: $error' : '';
    return '[$timeStr] [$levelStr] [$tag] $message$errStr';
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final List<LogEntry> _logs = [];
  static const int _maxInMemoryLogs = 1000;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void _addLog(LogLevel level, String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: _sanitize(message),
      error: error != null ? _sanitize(error.toString()) : null,
      stackTrace: stackTrace,
    );

    if (_logs.length >= _maxInMemoryLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);

    if (kDebugMode) {
      dev.log(
        entry.message,
        time: entry.timestamp,
        level: _levelToInt(level),
        name: tag,
        error: entry.error,
        stackTrace: stackTrace,
      );
    }
  }

  // Sanitize to prevent accidental secret or key leaks
  String _sanitize(String text) {
    var sanitized = text;
    final secretPatterns = [
      RegExp(r'(key|token|password|secret|bearer)[\s:=]+[\w\-]{8,}', caseSensitive: false),
    ];
    for (final pattern in secretPatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    return sanitized;
  }

  int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  static void d(String tag, String message) => AppLogger()._addLog(LogLevel.debug, tag, message);
  static void i(String tag, String message) => AppLogger()._addLog(LogLevel.info, tag, message);
  static void w(String tag, String message, [dynamic error]) => AppLogger()._addLog(LogLevel.warning, tag, message, error);
  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) =>
      AppLogger()._addLog(LogLevel.error, tag, message, error, stackTrace);

  void clear() => _logs.clear();
}
