import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Enterprise Log Levels
enum LogLevel { debug, info, warn, error, audit }

/// Structured Log Record
class LogRecord {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Map<String, dynamic>? metadata;
  final String? error;
  final String? stackTrace;
  final String correlationId;

  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.metadata,
    this.error,
    this.stackTrace,
    required this.correlationId,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'lvl': level.name.toUpperCase(),
        'tag': tag,
        'msg': message,
        'cid': correlationId,
        if (metadata != null) 'meta': metadata,
        if (error != null) 'err': error,
        if (stackTrace != null) 'stack': stackTrace,
      };

  @override
  String toString() => jsonEncode(toJson());
}

/// Enterprise Structured Logger & Telemetry Buffer
/// Captures structured operational events, redacts PII, and maintains
/// an in-memory circular log ring buffer for diagnostic exports.
class SanctuaryLogger {
  static final SanctuaryLogger _instance = SanctuaryLogger._internal();
  factory SanctuaryLogger() => _instance;
  SanctuaryLogger._internal();

  final List<LogRecord> _buffer = [];
  static const int _maxBufferSize = 500;
  String _activeCorrelationId = 'SESSION-INIT';

  void setCorrelationId(String id) {
    _activeCorrelationId = id;
  }

  List<LogRecord> get logs => List.unmodifiable(_buffer);

  void debug(String tag, String message, [Map<String, dynamic>? meta]) =>
      _log(LogLevel.debug, tag, message, meta: meta);

  void info(String tag, String message, [Map<String, dynamic>? meta]) =>
      _log(LogLevel.info, tag, message, meta: meta);

  void warn(String tag, String message, [Map<String, dynamic>? meta]) =>
      _log(LogLevel.warn, tag, message, meta: meta);

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? meta,
  }) =>
      _log(
        LogLevel.error,
        tag,
        message,
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
        meta: meta,
      );

  void audit(String tag, String message, Map<String, dynamic> auditData) =>
      _log(LogLevel.audit, tag, message, meta: auditData);

  void _log(
    LogLevel level,
    String tag,
    String message, {
    String? error,
    String? stackTrace,
    Map<String, dynamic>? meta,
  }) {
    final sanitizedMeta = meta != null ? _redactPii(meta) : null;

    final record = LogRecord(
      timestamp: DateTime.now().toUtc(),
      level: level,
      tag: tag,
      message: message,
      metadata: sanitizedMeta,
      error: error,
      stackTrace: stackTrace,
      correlationId: _activeCorrelationId,
    );

    _buffer.add(record);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    if (kDebugMode || level == LogLevel.error || level == LogLevel.audit) {
      debugPrint('[${record.level.name.toUpperCase()}] [${record.tag}] ${record.message}');
      if (error != null) debugPrint('   ↳ Error: $error');
    }
  }

  /// PII Redaction Filter
  Map<String, dynamic> _redactPii(Map<String, dynamic> input) {
    final clean = <String, dynamic>{};
    const sensitiveKeys = {
      'password',
      'secret',
      'pin',
      'token',
      'key',
      'card',
      'auth',
      'bearer',
    };

    input.forEach((k, v) {
      if (sensitiveKeys.any((s) => k.toLowerCase().contains(s))) {
        clean[k] = '***REDACTED***';
      } else if (v is Map<String, dynamic>) {
        clean[k] = _redactPii(v);
      } else {
        clean[k] = v;
      }
    });
    return clean;
  }

  /// Exports entire circular buffer as structured JSON lines (JSONL)
  String exportJsonl() {
    return _buffer.map((r) => r.toString()).join('\n');
  }

  void clear() {
    _buffer.clear();
  }
}
