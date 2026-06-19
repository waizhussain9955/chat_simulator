import 'package:intl/intl.dart';

class LogEntry {
  final DateTime timestamp;
  final String message;
  final String type; // 'info', 'success', 'warning', 'error'

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
  });

  String get formattedTime {
    return DateFormat('HH:mm:ss').format(timestamp);
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'type': type,
    };
  }

  factory LogEntry.fromMap(Map<dynamic, dynamic> map) {
    return LogEntry(
      timestamp: DateTime.parse(map['timestamp'] as String),
      message: map['message'] as String,
      type: (map['type'] as String?) ?? 'info',
    );
  }
}
