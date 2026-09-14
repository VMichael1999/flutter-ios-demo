import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/utils/geo.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/history/data/conversation_codec.dart';
import 'package:nova_ai/features/history/domain/entities/conversation.dart';

import '../../../fixtures/places_fixtures.dart';

void main() {
  test('conserva los lugares y desde dónde se buscaron', () {
    final original = Conversation(
      id: 'c1',
      updatedAt: DateTime(2026, 9, 13, 21),
      messages: const [
        ChatMessage.user(id: '1', text: 'Chifas cerca'),
        ChatMessage.assistant(
          id: '2',
          text: 'Encontré estos:',
          places: [chifaPlace, bodegaPlace],
          searchCenter: testCenter,
        ),
      ],
    );

    // Pasa por texto, como en el almacenamiento real.
    final restored = conversationFromJson(
      (jsonDecode(jsonEncode(conversationToJson(original))) as Map)
          .cast<String, Object?>(),
    );

    final answer = restored.messages.last;
    expect(answer.searchCenter, testCenter);
    expect(
      [for (final p in answer.places) p.name],
      [chifaPlace.name, bodegaPlace.name],
    );
  });

  test('un mensaje sin búsqueda no tiene ubicación', () {
    final restored = conversationFromJson(
      conversationToJson(
        Conversation(
          id: 'c2',
          updatedAt: DateTime(2026, 9, 13),
          messages: const [ChatMessage.user(id: '1', text: 'Hola')],
        ),
      ),
    );

    expect(restored.messages.single.searchCenter, isNull);
    expect(const GeoPoint(1, 2), isNot(restored.messages.single.searchCenter));
  });
}
