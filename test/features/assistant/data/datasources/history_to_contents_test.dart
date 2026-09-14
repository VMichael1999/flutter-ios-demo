import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/data/datasources/firebase_ai_datasource.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';

void main() {
  List<(String?, String)> turns(List<Content> contents) => [
    for (final content in contents)
      (content.role, (content.parts.single as TextPart).text),
  ];

  test('alterna persona y NOVA en el orden de la conversación', () {
    final contents = historyToContents(const [
      ChatMessage.user(id: '1', text: 'Hola'),
      ChatMessage.assistant(id: '2', text: '¡Hola!'),
      ChatMessage.user(id: '3', text: '¿Qué hay cerca?'),
      ChatMessage.assistant(id: '4', text: 'Un chifa.'),
    ]);

    expect(turns(contents), [
      ('user', 'Hola'),
      ('model', '¡Hola!'),
      ('user', '¿Qué hay cerca?'),
      ('model', 'Un chifa.'),
    ]);
  });

  test('une mensajes seguidos del mismo lado y describe las fotos', () {
    final contents = historyToContents(const [
      ChatMessage(id: '1', role: ChatRole.user, text: '', hadImage: true),
      ChatMessage.user(id: '2', text: '¿Qué restaurante es?'),
      ChatMessage.assistant(id: '3', text: 'Parece un chifa.'),
    ]);

    expect(turns(contents), [
      ('user', '(Envié una imagen)\n¿Qué restaurante es?'),
      ('model', 'Parece un chifa.'),
    ]);
  });

  test('empieza con la persona y descarta una pregunta sin respuesta', () {
    final contents = historyToContents(const [
      ChatMessage.assistant(id: '1', text: 'Bienvenido'),
      ChatMessage.user(id: '2', text: 'Hola'),
      ChatMessage.assistant(id: '3', text: '¡Hola!'),
      ChatMessage.user(id: '4', text: 'Esta falló'),
      ChatMessage.assistant(id: '5'),
    ]);

    expect(turns(contents), [('user', 'Hola'), ('model', '¡Hola!')]);
  });
}
