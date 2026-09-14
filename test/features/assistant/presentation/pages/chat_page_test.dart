import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/features/assistant/data/services/media_picker_service.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_attachment.dart';
import 'package:nova_ai/features/assistant/domain/repositories/ai_repository.dart';
import 'package:nova_ai/features/assistant/domain/usecases/reset_conversation.dart';
import 'package:nova_ai/features/assistant/domain/usecases/send_message.dart';
import 'package:nova_ai/features/assistant/presentation/bloc/chat_bloc.dart';
import 'package:nova_ai/features/assistant/presentation/pages/chat_page.dart';

import '../../../../fixtures/places_fixtures.dart';

class _MockAiRepository extends Mock implements AiRepository {}

class _NoImageMediaPicker implements MediaPickerService {
  @override
  Future<ChatAttachment?> pickImage(MediaSource source) async => null;
}

void main() {
  late _MockAiRepository repository;

  setUpAll(() => registerFallbackValue(testImageAttachment));

  setUp(() => repository = _MockAiRepository());

  Future<void> pumpChat(WidgetTester tester, {ChatDraft? draft}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ChatBloc(
            sendMessage: SendMessage(repository),
            resetConversation: ResetConversation(repository),
          ),
          child: ChatPage(
            mediaPicker: _NoImageMediaPicker(),
            initialDraft: draft,
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
      () => repository.streamReply(
        any(),
        attachment: any(named: 'attachment'),
      ),
    );
  });

  testWidgets('sin borrador el campo empieza vacío', (tester) async {
    await pumpChat(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });
}
