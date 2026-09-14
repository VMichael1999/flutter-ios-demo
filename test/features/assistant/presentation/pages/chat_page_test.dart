import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/core/services/speech_service.dart';
import 'package:nova_ai/features/assistant/data/services/media_picker_service.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_attachment.dart';
import 'package:nova_ai/features/assistant/domain/repositories/ai_repository.dart';
import 'package:nova_ai/features/assistant/domain/usecases/reset_conversation.dart';
import 'package:nova_ai/features/assistant/domain/usecases/send_message.dart';
import 'package:nova_ai/features/assistant/presentation/bloc/chat_bloc.dart';
import 'package:nova_ai/features/assistant/presentation/pages/chat_page.dart';

import '../../../../fixtures/places_fixtures.dart';
import '../../../../fixtures/voice_fakes.dart';

class _MockAiRepository extends Mock implements AiRepository {}

/// Registra de dónde se pidió la imagen y devuelve [result].
class _RecordingMediaPicker implements MediaPickerService {
  _RecordingMediaPicker([this.result]);

  final ChatAttachment? result;
  final requestedSources = <MediaSource>[];

  @override
  Future<ChatAttachment?> pickImage(MediaSource source) async {
    requestedSources.add(source);
    return result;
  }
}

void main() {
  late _MockAiRepository repository;

  setUpAll(() => registerFallbackValue(testImageAttachment));

  setUp(() => repository = _MockAiRepository());

  Future<void> pumpChat(
    WidgetTester tester, {
    MediaPickerService? mediaPicker,
    SpeechService? speechService,
    ChatDraft? draft,
    bool pickImageOnOpen = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create:
              (_) => ChatBloc(
                sendMessage: SendMessage(repository),
                resetConversation: ResetConversation(repository),
              ),
          child: ChatPage(
            mediaPicker: mediaPicker ?? _RecordingMediaPicker(),
            speechService: speechService,
            initialDraft: draft,
            pickImageOnOpen: pickImageOnOpen,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'deja escrito "Busca … cerca de mí" con el cursor en el hueco, sin enviarlo',
    (tester) async {
      await pumpChat(
        tester,
        draft: const ChatDraft(prefix: 'Busca ', suffix: ' cerca de mí'),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Busca  cerca de mí');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 6),
      );
      expect(field.focusNode!.hasFocus, isTrue);
      expect(find.text('Pregúntame lo que quieras'), findsOneWidget);
      verifyNever(
        () =>
            repository.streamReply(any(), attachment: any(named: 'attachment')),
      );
    },
  );

  testWidgets('sin borrador el campo empieza vacío', (tester) async {
    await pumpChat(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('pregunta si usar la cámara o la galería antes de abrir nada', (
    tester,
  ) async {
    final picker = _RecordingMediaPicker();
    await pumpChat(tester, mediaPicker: picker, pickImageOnOpen: true);
    await tester.pumpAndSettle();

    expect(find.text('Añadir una imagen'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
    expect(picker.requestedSources, isEmpty);
  });

  testWidgets('elegir galería abre la galería y muestra la vista previa', (
    tester,
  ) async {
    final picker = _RecordingMediaPicker(testImageAttachment);
    await pumpChat(tester, mediaPicker: picker, pickImageOnOpen: true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(picker.requestedSources, [MediaSource.gallery]);
    expect(find.bySemanticsLabel('Imagen para enviar'), findsOneWidget);
  });

  testWidgets('cerrar el menú sin elegir deja el chat como estaba', (
    tester,
  ) async {
    final picker = _RecordingMediaPicker();
    await pumpChat(tester, mediaPicker: picker, pickImageOnOpen: true);
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Añadir una imagen'), findsNothing);
    expect(picker.requestedSources, isEmpty);
    expect(find.text('Pregúntame lo que quieras'), findsOneWidget);
  });

  group('dictado', () {
    testWidgets('lo dictado aparece en el campo después de lo escrito', (
      tester,
    ) async {
      final speech = FakeSpeechService();
      await pumpChat(tester, speechService: speech);

      await tester.enterText(find.byType(TextField), 'Busca');
      await tester.tap(find.byTooltip('Dictar'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dejar de dictar'), findsOneWidget);

      speech.say('farmacias');
      await tester.pumpAndSettle();
      speech.say('farmacias abiertas', isFinal: true);
      await speech.finish();
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Busca farmacias abiertas');
      expect(find.byTooltip('Dictar'), findsOneWidget);
      // Dictar no envía: la persona revisa el texto antes.
      verifyNever(
        () =>
            repository.streamReply(any(), attachment: any(named: 'attachment')),
      );
    });

    testWidgets('tocar de nuevo el micrófono termina el dictado', (
      tester,
    ) async {
      final speech = FakeSpeechService();
      await pumpChat(tester, speechService: speech);

      await tester.tap(find.byTooltip('Dictar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Dejar de dictar'));
      await tester.pumpAndSettle();

      expect(speech.stopCalls, 1);
      expect(find.byTooltip('Dictar'), findsOneWidget);
    });

    testWidgets('explica por qué no pudo escuchar', (tester) async {
      final speech = FakeSpeechService();
      await pumpChat(tester, speechService: speech);

      await tester.tap(find.byTooltip('Dictar'));
      await tester.pumpAndSettle();
      await speech.fail(
        const SpeechFailure('NOVA necesita permiso para usar el micrófono.'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('NOVA necesita permiso para usar el micrófono.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Dictar'), findsOneWidget);
    });
  });
}
