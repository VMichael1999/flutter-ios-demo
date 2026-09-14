import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/app.dart';
import 'package:nova_ai/core/di/injection.dart';
import 'package:nova_ai/features/assistant/presentation/pages/chat_page.dart';
import 'package:nova_ai/features/splash/presentation/pages/splash_page.dart';

void main() {
  setUp(() => configureDependencies(useFirebaseAi: false));

  Future<void> openHome(WidgetTester tester) async {
    await tester.pumpWidget(const NovaApp());
    await tester.pump(SplashPage.displayDuration);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
  }

  testWidgets('pasa del splash al onboarding y luego a la home', (tester) async {
    await tester.pumpWidget(const NovaApp());
    expect(find.text('NOVA AI'), findsOneWidget);

    await tester.pump(SplashPage.displayDuration);
    await tester.pumpAndSettle();
    expect(find.text('Habla con NOVA'), findsOneWidget);

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué quieres hacer?'), findsOneWidget);

    // El botón queda debajo del pliegue en la pantalla de test (800x600).
    final openChatButton = find.text('Abrir chat con NOVA');
    await tester.scrollUntilVisible(
      openChatButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(openChatButton, findsOneWidget);
  });

  testWidgets('Ubicación abre el chat con "Busca … cerca de mí" por completar',
      (tester) async {
    // Pantalla de teléfono (360x800 lógicos), como un Galaxy A03.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await openHome(tester);

    await tester.tap(find.text('Ubicación'));
    await tester.pumpAndSettle();

    // La home sigue en el árbol debajo del chat: se busca el campo del chat.
    final chatField = find.descendant(
      of: find.byType(ChatPage),
      matching: find.byType(TextField),
    );
    expect(chatField, findsOneWidget);
    final field = tester.widget<TextField>(chatField);
    expect(field.controller!.text, 'Busca  cerca de mí');
    expect(field.controller!.selection.baseOffset, 'Busca '.length);
    // No se envía nada hasta que el usuario lo complete.
    expect(find.text('Pregúntame lo que quieras'), findsOneWidget);
  });
}
