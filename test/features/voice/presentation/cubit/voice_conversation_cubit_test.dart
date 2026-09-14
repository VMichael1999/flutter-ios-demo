import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/features/assistant/domain/entities/ai_reply_chunk.dart';
import 'package:nova_ai/features/assistant/domain/repositories/ai_repository.dart';
import 'package:nova_ai/features/assistant/domain/usecases/send_message.dart';
import 'package:nova_ai/features/voice/presentation/cubit/voice_conversation_cubit.dart';

import 'package:nova_ai/features/history/domain/entities/conversation.dart';

import '../../../../fixtures/history_fakes.dart';
import '../../../../fixtures/places_fixtures.dart';
import '../../../../fixtures/voice_fakes.dart';

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  late FakeSpeechService speech;
  late _MockAiRepository repository;

  setUpAll(() => registerFallbackValue(testImageAttachment));

  setUp(() {
    speech = FakeSpeechService();
    repository = _MockAiRepository();
  });

  VoiceConversationCubit buildCubit(
    FakeTextToSpeech textToSpeech, {
    bool continuous = false,
  }) {
    final cubit = VoiceConversationCubit(
      speech: speech,
      textToSpeech: textToSpeech,
      sendMessage: SendMessage(repository),
      continuous: continuous,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  void stubReply(String question, Stream<AiReplyChunk> Function() reply) {
    when(
      () => repository.streamReply(
        question,
        attachment: any(named: 'attachment'),
      ),
    ).thenAnswer((_) => reply());
  }

  test('escucha, pregunta a NOVA y lee la respuesta sin Markdown', () async {
    final textToSpeech = FakeTextToSpeech();
    final cubit = buildCubit(textToSpeech);
    stubReply(
      '¿Qué hora es?',
      () => Stream.fromIterable(
        const [AiTextChunk('Son las **tres**'), AiTextChunk('.')],
      ),
    );

    await cubit.startListening();
    expect(cubit.state.status, VoiceStatus.listening);

    speech.say('¿Qué hora');
    await pumpEventQueue();
    expect(cubit.state.transcript, '¿Qué hora');

    speech.say('¿Qué hora es?', isFinal: true);
    await speech.finish();
    await pumpEventQueue();

    expect(textToSpeech.spoken, ['Son las tres.']);
    expect(cubit.state.status, VoiceStatus.idle);
    expect(cubit.state.transcript, '¿Qué hora es?');
    expect(cubit.state.reply, 'Son las **tres**.');
  });

  test('en modo continuo vuelve a escuchar al terminar de hablar', () async {
    final cubit = buildCubit(FakeTextToSpeech(), continuous: true);
    stubReply('Hola', () => Stream.value(const AiTextChunk('¡Hola!')));

    await cubit.startListening();
    speech.say('Hola');
    await speech.finish();
    await pumpEventQueue();

    expect(speech.listenCalls, 2);
    expect(cubit.state.status, VoiceStatus.listening);
    expect(cubit.state.transcript, isEmpty);
  });

  test('si no escuchó nada no pregunta y lo avisa', () async {
    final cubit = buildCubit(FakeTextToSpeech(), continuous: true);

    await cubit.startListening();
    await speech.finish();
    await pumpEventQueue();

    expect(cubit.state.status, VoiceStatus.failure);
    expect(cubit.state.errorMessage, contains('No te escuché'));
    expect(speech.listenCalls, 1);
    verifyNever(
      () => repository.streamReply(
        any(),
        attachment: any(named: 'attachment'),
      ),
    );
  });

  test('muestra el motivo cuando no hay permiso de micrófono', () async {
    final cubit = buildCubit(FakeTextToSpeech());

    await cubit.startListening();
    await speech.fail(const SpeechFailure('Sin permiso de micrófono.'));
    await pumpEventQueue();

    expect(cubit.state.status, VoiceStatus.failure);
    expect(cubit.state.errorMessage, 'Sin permiso de micrófono.');
  });

  test('muestra el error de la IA', () async {
    final cubit = buildCubit(FakeTextToSpeech());
    stubReply('Hola', () => Stream.error(const AiFailure('Sin conexión.')));

    await cubit.startListening();
    speech.say('Hola');
    await speech.finish();
    await pumpEventQueue();

    expect(cubit.state.status, VoiceStatus.failure);
    expect(cubit.state.errorMessage, 'Sin conexión.');
  });

  test('tocar mientras NOVA habla la interrumpe y no vuelve a escuchar',
      () async {
    final textToSpeech = FakeTextToSpeech(holdSpeech: true);
    final cubit = buildCubit(textToSpeech, continuous: true);
    stubReply('Cuéntame algo', () => Stream.value(const AiTextChunk('Había')));

    await cubit.startListening();
    speech.say('Cuéntame algo');
    await speech.finish();
    await pumpEventQueue();
    expect(cubit.state.status, VoiceStatus.speaking);

    await cubit.toggle();
    await pumpEventQueue();

    expect(textToSpeech.stopCalls, 1);
    expect(cubit.state.status, VoiceStatus.idle);
    expect(speech.listenCalls, 1);
  });

  test('tocar mientras escucha termina la frase', () async {
    final cubit = buildCubit(FakeTextToSpeech());
    final reply = StreamController<AiReplyChunk>();
    addTearDown(reply.close);
    stubReply('Hola', () => reply.stream);

    await cubit.startListening();
    speech.say('Hola');
    await cubit.toggle();
    await pumpEventQueue();

    expect(speech.stopCalls, 1);
    expect(cubit.state.status, VoiceStatus.thinking);
  });

  test('guarda cada pregunta y respuesta en el historial', () async {
    final history = InMemoryConversationRepository();
    final cubit = VoiceConversationCubit(
      speech: speech,
      textToSpeech: FakeTextToSpeech(),
      sendMessage: SendMessage(repository),
      conversations: history,
      continuous: false,
    );
    addTearDown(cubit.close);
    stubReply('Hola', () => Stream.value(const AiTextChunk('¡Hola!')));
    stubReply('Adiós', () => Stream.value(const AiTextChunk('¡Chao!')));

    for (final question in ['Hola', 'Adiós']) {
      await cubit.startListening();
      speech.say(question);
      await speech.finish();
      await pumpEventQueue();
    }

    final conversation = history.saved.values.single;
    expect(conversation.source, ConversationSource.voice);
    expect(
      [for (final message in conversation.messages) message.text],
      ['Hola', '¡Hola!', 'Adiós', '¡Chao!'],
    );
  });

  test('si la voz del teléfono falla lo dice y deja la respuesta escrita',
      () async {
    final cubit = buildCubit(FakeTextToSpeech(fails: true));
    stubReply('Hola', () => Stream.value(const AiTextChunk('¡Hola!')));

    await cubit.startListening();
    speech.say('Hola');
    await speech.finish();
    await pumpEventQueue();

    expect(cubit.state.status, VoiceStatus.failure);
    expect(cubit.state.errorMessage, contains('voz alta'));
    expect(cubit.state.reply, '¡Hola!');
  });
}
