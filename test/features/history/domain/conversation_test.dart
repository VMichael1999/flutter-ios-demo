import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/history/domain/entities/conversation.dart';

void main() {
  Conversation conversationWith(
    List<ChatMessage> messages, {
    ConversationSource source = ConversationSource.chat,
  }) => Conversation(
    id: 'c1',
    updatedAt: DateTime(2026, 9, 13),
    messages: messages,
    source: source,
  );

  test('el título es la primera pregunta y la vista previa lo último', () {
    final conversation = conversationWith(const [
      ChatMessage.user(id: '1', text: '  ¿Qué   chifas hay\ncerca?'),
      ChatMessage.assistant(id: '2', text: 'Encontré **dos** chifas.'),
    ]);

    expect(conversation.title, '¿Qué chifas hay cerca?');
    expect(conversation.preview, 'Encontré dos chifas.');
  });

  test('acorta los títulos largos', () {
    final conversation = conversationWith([
      ChatMessage.user(id: '1', text: 'a' * 80),
    ]);

    expect(conversation.title.length, 48);
    expect(conversation.title, endsWith('…'));
  });

  test('una foto sin texto se titula "Foto"', () {
    final conversation = conversationWith(const [
      ChatMessage(id: '1', role: ChatRole.user, text: '', hadImage: true),
    ]);

    expect(conversation.title, 'Foto');
  });

  test('sin preguntas usa un título según el origen', () {
    expect(
      conversationWith(const [], source: ConversationSource.voice).title,
      'Conversación por voz',
    );
  });
}
