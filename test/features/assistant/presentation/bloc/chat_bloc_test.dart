import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/features/assistant/domain/entities/ai_reply_chunk.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/assistant/domain/repositories/ai_repository.dart';
import 'package:nova_ai/features/assistant/domain/usecases/reset_conversation.dart';
import 'package:nova_ai/features/assistant/domain/usecases/send_message.dart';
import 'package:nova_ai/features/assistant/presentation/bloc/chat_bloc.dart';

import '../../../../fixtures/places_fixtures.dart';

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  late _MockAiRepository repository;

  setUp(() => repository = _MockAiRepository());

  ChatBloc buildBloc() => ChatBloc(
        sendMessage: SendMessage(repository),
        resetConversation: ResetConversation(repository),
      );

  blocTest<ChatBloc, ChatState>(
    'muestra la respuesta del asistente fragmento a fragmento',
    setUp: () => when(() => repository.streamReply('Hola')).thenAnswer(
      (_) => Stream.fromIterable(
        const [AiTextChunk('Hola, '), AiTextChunk('soy NOVA')],
      ),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ChatMessageSent('  Hola ')),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.streaming)
          .having((s) => s.messages.first.text, 'mensaje del usuario', 'Hola')
          .having((s) => s.messages.last.isStreaming, 'isStreaming', true),
      isA<ChatState>().having((s) => s.messages.last.text, 'texto', 'Hola, '),
      isA<ChatState>()
          .having((s) => s.messages.last.text, 'texto', 'Hola, soy NOVA'),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.idle)
          .having((s) => s.messages.last.isStreaming, 'isStreaming', false),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'adjunta los lugares encontrados a la respuesta del asistente',
    setUp: () => when(() => repository.streamReply('Restaurantes cerca'))
        .thenAnswer(
      (_) => Stream.fromIterable(const [
        AiPlacesChunk([chifaPlace, bodegaPlace]),
        AiTextChunk('El más cercano es Chifa Miraflores.'),
      ]),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ChatMessageSent('Restaurantes cerca')),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<ChatState>().having((s) => s.messages.length, 'mensajes', 2),
      isA<ChatState>().having(
        (s) => s.messages.last.places,
        'lugares',
        [chifaPlace, bodegaPlace],
      ),
      isA<ChatState>().having(
        (s) => s.messages.last.text,
        'texto',
        'El más cercano es Chifa Miraflores.',
      ),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.idle)
          .having((s) => s.messages.last.places, 'lugares', hasLength(2)),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'ignora mensajes vacíos',
    build: buildBloc,
    act: (bloc) => bloc.add(const ChatMessageSent('   ')),
    expect: () => <ChatState>[],
    verify: (_) => verifyNever(() => repository.streamReply(any())),
  );

  blocTest<ChatBloc, ChatState>(
    'muestra el error y quita la burbuja vacía cuando la IA falla',
    setUp: () => when(() => repository.streamReply('Hola')).thenAnswer(
      (_) => Stream.error(const AiFailure('Sin conexión')),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ChatMessageSent('Hola')),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<ChatState>().having((s) => s.messages.length, 'mensajes', 2),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.failure)
          .having((s) => s.errorMessage, 'error', 'Sin conexión')
          .having((s) => s.messages.length, 'mensajes', 1),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'empieza una conversación nueva al limpiar el chat',
    build: buildBloc,
    seed: () => const ChatState(
      messages: [ChatMessage.user(id: '1', text: 'Hola')],
    ),
    act: (bloc) => bloc.add(const ChatCleared()),
    expect: () => [const ChatState()],
    verify: (_) => verify(() => repository.resetConversation()).called(1),
  );
}
