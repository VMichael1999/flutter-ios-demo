import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/utils/geo.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/history/data/shared_preferences_conversation_repository.dart';
import 'package:nova_ai/features/history/domain/entities/conversation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/places_fixtures.dart';

void main() {
  late SharedPreferencesConversationRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SharedPreferencesConversationRepository();
  });

  Conversation conversation(
    String id, {
    required DateTime at,
    List<ChatMessage>? messages,
  }) => Conversation(
    id: id,
    updatedAt: at,
    messages:
        messages ??
        [
          ChatMessage.user(id: '$id-1', text: 'Pregunta $id'),
          ChatMessage.assistant(id: '$id-2', text: 'Respuesta $id'),
        ],
  );

  test('lista primero la conversación guardada más recientemente', () async {
    await repository.save(conversation('a', at: DateTime(2026, 9, 12)));
    await repository.save(conversation('b', at: DateTime(2026, 9, 13)));
    await repository.save(conversation('a', at: DateTime(2026, 9, 13, 1)));

    final recent = await repository.recent();

    expect([for (final summary in recent) summary.id], ['a', 'b']);
    expect(recent.first.title, 'Pregunta a');
    expect(recent.first.preview, 'Respuesta a');
  });

  test('guarda texto, lugares y la marca de imagen; nunca los bytes', () async {
    await repository.save(
      conversation(
        'c',
        at: DateTime(2026, 9, 13),
        messages: [
          ChatMessage.user(
            id: 'u',
            text: '¿Qué es esto?',
            attachment: testImageAttachment,
          ),
          const ChatMessage.assistant(
            id: 'n',
            text: 'Un chifa cerca.',
            places: [chifaPlace],
          ),
        ],
      ),
    );

    final loaded = await repository.load('c');

    expect(loaded, isNotNull);
    final [question, answer] = loaded!.messages;
    expect(question.text, '¿Qué es esto?');
    expect(question.attachment, isNull);
    expect(question.hadImage, isTrue);
    expect(answer.places.single.name, chifaPlace.name);
    expect(answer.places.single.location, const GeoPoint(-12.1138, -77.0374));
    expect(answer.places.single.distanceMeters, chifaPlace.distanceMeters);
  });

  test('no guarda burbujas vacías ni conversaciones sin preguntas', () async {
    await repository.save(
      conversation(
        'd',
        at: DateTime(2026, 9, 13),
        messages: const [
          ChatMessage.user(id: '1', text: 'Hola'),
          ChatMessage.assistant(id: '2', isStreaming: true),
        ],
      ),
    );
    await repository.save(
      conversation(
        'e',
        at: DateTime(2026, 9, 13),
        messages: const [ChatMessage.assistant(id: '1', text: 'Hola')],
      ),
    );

    expect((await repository.load('d'))!.messages, hasLength(1));
    expect(await repository.load('e'), isNull);
    expect(await repository.recent(), hasLength(1));
  });

  test('borra las más antiguas al pasar el límite', () async {
    repository = SharedPreferencesConversationRepository(maxConversations: 2);
    for (var day = 1; day <= 3; day++) {
      await repository.save(conversation('$day', at: DateTime(2026, 9, day)));
    }

    expect([for (final s in await repository.recent()) s.id], ['3', '2']);
    expect(await repository.load('1'), isNull);
  });

  test('borrar quita la conversación y avisa del cambio', () async {
    await repository.save(conversation('f', at: DateTime(2026, 9, 13)));
    final changed = expectLater(repository.changes, emits(null));

    await repository.delete('f');

    await changed;
    expect(await repository.recent(), isEmpty);
    expect(await repository.load('f'), isNull);
  });

  test('al deshacer un borrado la conversación vuelve a su lugar', () async {
    final older = conversation('vieja', at: DateTime(2026, 9, 13, 10));
    await repository.save(older);
    await repository.save(conversation('nueva', at: DateTime(2026, 9, 13, 11)));

    await repository.delete('vieja');
    // "Deshacer" vuelve a guardar la misma conversación, con su fecha.
    await repository.save(older);

    expect(
      [for (final summary in await repository.recent()) summary.id],
      ['nueva', 'vieja'],
    );
  });

  test('un índice dañado no rompe la app', () async {
    SharedPreferences.setMockInitialValues({'nova.history.index': '{roto'});
    repository = SharedPreferencesConversationRepository();

    expect(await repository.recent(), isEmpty);
  });
}
