class Message {
  final String id;
  final String message;
  final String category;
  final bool isFavorite;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.message,
    required this.category,
    this.isFavorite = false,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? message,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      message: message ?? this.message,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0, // Store as int for cross-compat
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<dynamic, dynamic> map) {
    return Message(
      id: map['id'] as String,
      message: map['message'] as String,
      category: (map['category'] as String?) ?? 'Custom',
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
