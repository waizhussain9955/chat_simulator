class ProjectSettings {
  final int countdown;
  final String themeMode;
  final String sendingMode; // 'human', 'fast', 'instant'
  final int typingSpeed; // character typing delay in milliseconds (useful for Human/Fast)
  final String storagePath;
  final bool autoSave;
  final String customChatAppUrl;
  final int interMessageDelay; // delay between consecutive messages in seconds

  ProjectSettings({
    this.countdown = 5,
    this.themeMode = 'dark',
    this.sendingMode = 'human',
    this.typingSpeed = 100,
    this.storagePath = '',
    this.autoSave = true,
    this.customChatAppUrl = 'whatsapp://send?text={text}',
    this.interMessageDelay = 3,
  });

  ProjectSettings copyWith({
    int? countdown,
    String? themeMode,
    String? sendingMode,
    int? typingSpeed,
    String? storagePath,
    bool? autoSave,
    String? customChatAppUrl,
    int? interMessageDelay,
  }) {
    return ProjectSettings(
      countdown: countdown ?? this.countdown,
      themeMode: themeMode ?? this.themeMode,
      sendingMode: sendingMode ?? this.sendingMode,
      typingSpeed: typingSpeed ?? this.typingSpeed,
      storagePath: storagePath ?? this.storagePath,
      autoSave: autoSave ?? this.autoSave,
      customChatAppUrl: customChatAppUrl ?? this.customChatAppUrl,
      interMessageDelay: interMessageDelay ?? this.interMessageDelay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countdown': countdown,
      'themeMode': themeMode,
      'sendingMode': sendingMode,
      'typingSpeed': typingSpeed,
      'storagePath': storagePath,
      'autoSave': autoSave ? 1 : 0,
      'customChatAppUrl': customChatAppUrl,
      'interMessageDelay': interMessageDelay,
    };
  }

  factory ProjectSettings.fromMap(Map<dynamic, dynamic> map) {
    return ProjectSettings(
      countdown: (map['countdown'] as num?)?.toInt() ?? 5,
      themeMode: (map['themeMode'] as String?) ?? 'dark',
      sendingMode: (map['sendingMode'] as String?) ?? 'human',
      typingSpeed: (map['typingSpeed'] as num?)?.toInt() ?? 100,
      storagePath: (map['storagePath'] as String?) ?? '',
      autoSave: (map['autoSave'] == 1 || map['autoSave'] == true || map['autoSave'] == null),
      customChatAppUrl: (map['customChatAppUrl'] as String?) ?? 'whatsapp://send?text={text}',
      interMessageDelay: (map['interMessageDelay'] as num?)?.toInt() ?? 3,
    );
  }
}
