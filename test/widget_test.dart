import 'package:flutter_test/flutter_test.dart';
import 'package:chat_simulator_pro/models/message.dart';
import 'package:chat_simulator_pro/models/settings.dart';

void main() {
  test('Message Model Serialization Test', () {
    final now = DateTime.now();
    final message = Message(
      id: 'test-id',
      message: 'Hello, testing!',
      category: 'Friends',
      isFavorite: true,
      createdAt: now,
    );

    final map = message.toMap();
    expect(map['id'], 'test-id');
    expect(map['message'], 'Hello, testing!');
    expect(map['category'], 'Friends');
    expect(map['isFavorite'], 1);
    expect(map['createdAt'], now.toIso8601String());

    final deserialized = Message.fromMap(map);
    expect(deserialized.id, 'test-id');
    expect(deserialized.message, 'Hello, testing!');
    expect(deserialized.category, 'Friends');
    expect(deserialized.isFavorite, true);
    expect(deserialized.createdAt.toIso8601String(), now.toIso8601String());
  });

  test('ProjectSettings Model Serialization Test', () {
    final settings = ProjectSettings(
      countdown: 3,
      themeMode: 'light',
      sendingMode: 'instant',
      typingSpeed: 150,
      storagePath: '/test/path',
      autoSave: false,
      customChatAppUrl: 'tg://msg?text={text}',
    );

    final map = settings.toMap();
    expect(map['countdown'], 3);
    expect(map['themeMode'], 'light');
    expect(map['sendingMode'], 'instant');
    expect(map['typingSpeed'], 150);
    expect(map['storagePath'], '/test/path');
    expect(map['autoSave'], 0);
    expect(map['customChatAppUrl'], 'tg://msg?text={text}');

    final deserialized = ProjectSettings.fromMap(map);
    expect(deserialized.countdown, 3);
    expect(deserialized.themeMode, 'light');
    expect(deserialized.sendingMode, 'instant');
    expect(deserialized.typingSpeed, 150);
    expect(deserialized.storagePath, '/test/path');
    expect(deserialized.autoSave, false);
    expect(deserialized.customChatAppUrl, 'tg://msg?text={text}');
  });
}
