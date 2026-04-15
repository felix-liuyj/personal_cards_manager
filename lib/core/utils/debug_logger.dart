import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    final errorStr = error != null ? '\n  错误: $error' : '';
    return '[$timeStr] [$level] $message$errorStr';
  }
}

class DebugLogger extends StateNotifier<List<LogEntry>> {
  DebugLogger() : super([]);

  void log(String level, String message, {Object? error}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error?.toString(),
    );

    // 保留最近 100 条日志
    final newState = [entry, ...state];
    if (newState.length > 100) {
      state = newState.sublist(0, 100);
    } else {
      state = newState;
    }

    // 同时输出到控制台
    print(entry.toString());
  }

  void info(String message) => log('INFO', message);
  void warning(String message) => log('WARN', message);
  void error(String message, {Object? error}) =>
      log('ERROR', message, error: error);
  void debug(String message) => log('DEBUG', message);

  void clear() {
    state = [];
  }
}

final debugLoggerProvider = StateNotifierProvider<DebugLogger, List<LogEntry>>((
  ref,
) {
  return DebugLogger();
});
