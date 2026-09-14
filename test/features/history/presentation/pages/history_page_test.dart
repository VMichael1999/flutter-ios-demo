import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/theme/app_theme.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/history/domain/entities/conversation.dart';
import 'package:nova_ai/features/history/presentation/pages/history_page.dart';

import '../../../../fixtures/history_fakes.dart';

void main() {
  final now = DateTime(2026, 9, 13, 21, 30);

  Conversation conversation(
    String id,
    String question,
    DateTime at, {
    ConversationSource source = ConversationSource.chat,
  }) => Conversation(
    id: id,
    updatedAt: at,
    source: source,
    messages: [
      ChatMessage.user(id: '$id-1', text: question),
      ChatMessage.assistant(id: '$id-2', text: 'Respuesta a $question'),
    ],
  );

  Future<void> pumpHistory(
    WidgetTester tester,
    InMemoryConversationRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HistoryPage(conversations: repository, clock: () => now),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin conversaciones explica qué se guardará', (tester) async {
    await pumpHistory(tester, InMemoryConversationRepository());

    expect(find.text('Aún no hay conversaciones'), findsOneWidget);
  });

  testWidgets('agrupa por fecha y muestra título, vista previa y hora', (
    tester,
  ) async {
    await pumpHistory(
      tester,
      InMemoryConversationRepository([
        conversation('1', 'Chifas cerca', DateTime(2026, 9, 13, 20, 15)),
        conversation(
          '2',
          'Cuéntame un chiste',
          DateTime(2026, 9, 12, 10),
          source: ConversationSource.voice,
        ),
        conversation('3', 'Mi semana', DateTime(2026, 8, 20)),
      ]),
    );

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Anteriores'), findsOneWidget);
    // "Ayer" es el grupo y también la hora de esa conversación.
    expect(find.text('Ayer'), findsNWidgets(2));
    expect(find.text('Chifas cerca'), findsOneWidget);
    expect(find.text('Respuesta a Chifas cerca'), findsOneWidget);
    expect(find.text('20:15'), findsOneWidget);
    // La etiqueta del ícono se une al texto de la tarjeta al leerla en voz alta.
    expect(find.bySemanticsLabel(RegExp('Por voz')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deslizar borra la conversación y se puede deshacer', (
    tester,
  ) async {
    final repository = InMemoryConversationRepository([
      conversation('1', 'Chifas cerca', DateTime(2026, 9, 13, 20)),
    ]);
    await pumpHistory(tester, repository);

    await tester.drag(find.text('Chifas cerca'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(repository.saved, isEmpty);
    expect(find.text('Conversación eliminada'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(repository.saved.keys, ['1']);
    expect(find.text('Chifas cerca'), findsOneWidget);
  });
}
