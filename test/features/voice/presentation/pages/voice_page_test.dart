import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/theme/app_theme.dart';
import 'package:nova_ai/features/assistant/domain/entities/ai_reply_chunk.dart';
import 'package:nova_ai/features/assistant/domain/repositories/ai_repository.dart';
import 'package:nova_ai/features/assistant/domain/usecases/send_message.dart';
import 'package:nova_ai/features/voice/presentation/cubit/voice_conversation_cubit.dart';
import 'package:nova_ai/features/voice/presentation/pages/voice_page.dart';

import '../../../../fixtures/places_fixtures.dart';
import '../../../../fixtures/voice_fakes.dart';

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  late FakeSpeechService speech;
  late FakeTextToSpeech textToSpeech;
  late _MockAiRepository repository;

  setUpAll(() => registerFallbackValue(testImageAttachment));

  setUp(() {
    speech = FakeSpeechService();
    textToSpeech = FakeTextToSpeech();
    repository = _MockAiRepository();
  });

  // El orbe se anima sin parar: se avanza con pump en vez de pumpAndSettle.
  Future<void> pumpVoice(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider(
          create:
              (_) => VoiceConversationCubit(
                speech: speech,
                textToSpeech: textToSpeech,
                sendMessage: SendMessage(repository),
                continuous: false,
              ),
          child: const VoicePage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('empieza a escuchar al abrir y muestra lo que oye', (
    tester,
  ) async {
    await pumpVoice(tester);

    expect(speech.listenCalls, 1);
    expect(find.text('Te escucho… habla ahora'), findsOneWidget);
    expect(find.byTooltip('Terminar de hablar'), findsOneWidget);

    speech.say('Busca farmacias');
    await tester.pump();

    expect(find.text('“Busca farmacias”'), findsOneWidget);
  });

  testWidgets('al terminar de hablar NOVA responde en texto y en voz', (
    tester,
  ) async {
    when(
      () =>
          repository.streamReply('Hola', attachment: any(named: 'attachment')),
    ).thenAnswer(
      (_) => Stream.value(const AiTextChunk('¡Hola! Soy **NOVA**.')),
    );
    await pumpVoice(tester);

    speech.say('Hola');
    await tester.tap(find.byTooltip('Terminar de hablar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('¡Hola! Soy NOVA.'), findsOneWidget);
    expect(textToSpeech.spoken, ['¡Hola! Soy NOVA.']);
    expect(find.text('Toca el micrófono y habla'), findsOneWidget);
    expect(find.byTooltip('Hablar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('si no escucha nada invita a intentarlo de nuevo', (
    tester,
  ) async {
    await pumpVoice(tester);

    await speech.finish();
    await tester.pump();

    expect(find.textContaining('No te escuché'), findsOneWidget);

    await tester.tap(find.byTooltip('Hablar'));
    await tester.pump();
    expect(speech.listenCalls, 2);
  });
}
