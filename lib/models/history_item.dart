class HistoryItem {
  final String id;
  final String message;
  final DateTime timestamp;
  final String sessionId;
  final String status;

  HistoryItem({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.sessionId,
    this.status = 'Sent',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'status': status,
    };
  }

  factory HistoryItem.fromMap(Map<dynamic, dynamic> map) {
    return HistoryItem(
      id: map['id'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      sessionId: map['sessionId'] as String,
      status: (map['status'] as String?) ?? 'Sent',
    );
  }
}
