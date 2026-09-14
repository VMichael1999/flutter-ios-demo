import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/features/assistant/domain/entities/ai_reply_chunk.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/assistant/domain/repositories/ai_repository.dart';
import 'package:nova_ai/features/assistant/domain/usecases/reset_conversation.dart';
import 'package:nova_ai/features/assistant/domain/usecases/restore_conversation.dart';
import 'package:nova_ai/features/assistant/domain/usecases/send_message.dart';
import 'package:nova_ai/features/assistant/presentation/bloc/chat_bloc.dart';
import 'package:nova_ai/features/history/domain/entities/conversation.dart';

import '../../../../fixtures/history_fakes.dart';
import '../../../../fixtures/places_fixtures.dart';

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  late _MockAiRepository ai;
  late InMemoryConversationRepository history;

  setUpAll(() => registerFallbackValue(testImageAttachment));

  setUp(() {
    ai = _MockAiRepository();
    history = InMemoryConversationRepository();
    when(
      () => ai.streamReply(any(), attachment: any(named: 'attachment')),
    ).thenAnswer((_) => Stream.value(const AiTextChunk('Respuesta')));
  });

  ChatBloc buildBloc() {
    final bloc = ChatBloc(
      sendMessage: SendMessage(ai),
      resetConversation: ResetConversation(ai),
      restoreConversation: RestoreConversation(ai),
      conversations: history,
      clock: () => DateTime(2026, 9, 13, 21),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> send(ChatBloc bloc, String text) async {
    bloc.add(ChatMessageSent(text));
    await pumpEventQueue();
  }

  test('guarda la conversación cuando NOVA termina de responder', () async {
    final bloc = buildBloc();

    await send(bloc, 'Hola');
    await send(bloc, '¿Qué tal?');

    final conversation = history.saved.values.single;
    expect(conversation.title, 'Hola');
    expect(
      [for (final message in conversation.messages) message.text],
      ['Hola', 'Respuesta', '¿Qué tal?', 'Respuesta'],
    );
    expect(conversation.updatedAt, DateTime(2026, 9, 13, 21));
  });

  test('una conversación nueva no pisa la anterior', () async {
    final bloc = buildBloc();

    await send(bloc, 'Primera');
    bloc.add(const ChatCleared());
    await pumpEventQueue();
    await send(bloc, 'Segunda');

    expect([
      for (final c in history.saved.values) c.title,
    ], unorderedEquals(['Primera', 'Segunda']));
  });

  test(
    'abrir una conversación la muestra, la retoma y sigue guardándola',
    () async {
      const messages = [
        ChatMessage.user(id: '1', text: '¿Dónde hay un chifa?'),
        ChatMessage.assistant(id: '2', text: 'En Miraflores.'),
      ];
      history.saved['vieja'] = Conversation(
        id: 'vieja',
        updatedAt: DateTime(2026, 9, 1),
        messages: messages,
      );
      final bloc = buildBloc();

      bloc.add(const ChatConversationOpened('vieja'));
      await pumpEventQueue();

      expect(bloc.state.messages, messages);
      verify(() => ai.restoreConversation(messages)).called(1);

      await send(bloc, '¿Y otro?');
      expect(history.saved, hasLength(1));
      expect(history.saved['vieja']!.messages, hasLength(4));
    },
  );

  test('avisa si la conversación ya no existe', () async {
    final bloc = buildBloc();

    bloc.add(const ChatConversationOpened('borrada'));
    await pumpEventQueue();

    expect(bloc.state.status, ChatStatus.failure);
    expect(bloc.state.errorMessage, contains('No encontré'));
  });
}
