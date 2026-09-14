import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/app.dart';
import 'package:nova_ai/core/di/injection.dart';
import 'package:nova_ai/features/splash/presentation/pages/splash_page.dart';

void main() {
  setUp(() => configureDependencies(useFirebaseAi: false));

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
}
