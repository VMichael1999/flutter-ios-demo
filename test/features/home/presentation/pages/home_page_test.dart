import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/theme/app_theme.dart';
import 'package:nova_ai/core/utils/dates.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/history/domain/entities/conversation.dart';
import 'package:nova_ai/features/home/presentation/pages/home_page.dart';

import '../../../../fixtures/history_fakes.dart';

void main() {
  final evening = DateTime(2026, 9, 13, 21, 30);

  /// Dibuja la home con el tamaño de un teléfono y el tamaño de letra dado.
  /// Cualquier desbordamiento de diseño hace fallar el test.
  Future<void> pumpHomeOnPhone(
    WidgetTester tester, {
    required Size logicalSize,
    double textScale = 1,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = logicalSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Builder(
          builder:
              (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: HomePage(clock: () => evening),
              ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('los atajos caben en un teléfono de 360 px', (tester) async {
    await pumpHomeOnPhone(tester, logicalSize: const Size(360, 800));

    for (final label in ['Voz', 'Cámara', 'Ubicación', 'Documento']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Pronto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los atajos no se desbordan con la letra al 130 %', (
    tester,
  ) async {
    await pumpHomeOnPhone(
      tester,
      logicalSize: const Size(360, 800),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('también se ve bien en modo oscuro', (tester) async {
    await pumpHomeOnPhone(
      tester,
      logicalSize: const Size(360, 800),
      theme: AppTheme.dark(),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('saluda según la hora y muestra la fecha', (tester) async {
    await pumpHomeOnPhone(tester, logicalSize: const Size(360, 800));

    expect(find.text('Buenas noches'), findsOneWidget);
    expect(find.text('dom 13 sep'), findsOneWidget);
    expect(find.text('¿Qué hacemos hoy?', findRichText: true), findsOneWidget);
  });

  testWidgets('muestra las conversaciones recientes sin desbordarse', (
    tester,
  ) async {
    final repository = InMemoryConversationRepository([
      for (var i = 1; i <= 4; i++)
        Conversation(
          id: '$i',
          updatedAt: DateTime(2026, 9, 13, 10 + i),
          messages: [
            ChatMessage.user(id: '$i-1', text: 'Pregunta número $i'),
            const ChatMessage.assistant(id: 'r', text: 'Respuesta'),
          ],
        ),
    ]);
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: HomePage(clock: () => evening, conversations: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recientes'), findsOneWidget);
    expect(find.text('Pregunta número 4'), findsOneWidget);
    expect(find.text('Pregunta número 2'), findsOneWidget);
    // Solo las tres más recientes.
    expect(find.text('Pregunta número 1'), findsNothing);
    expect(find.text('Ver todo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('greetingFor', () {
    test('cambia con la hora del día', () {
      expect(greetingFor(DateTime(2026, 1, 1, 3)), 'Buenas noches');
      expect(greetingFor(DateTime(2026, 1, 1, 8)), 'Buenos días');
      expect(greetingFor(DateTime(2026, 1, 1, 12)), 'Buenas tardes');
      expect(greetingFor(DateTime(2026, 1, 1, 19)), 'Buenas noches');
    });
  });

  test('shortSpanishDate usa días y meses en español', () {
    expect(shortSpanishDate(DateTime(2026, 9, 13)), 'dom 13 sep');
    expect(shortSpanishDate(DateTime(2026, 2, 4)), 'mié 4 feb');
  });
}
