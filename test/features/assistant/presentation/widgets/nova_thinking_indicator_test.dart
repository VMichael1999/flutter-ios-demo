import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/nova_thinking_indicator.dart';

void main() {
  Future<void> pumpIndicator(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: disableAnimations),
                child: const Scaffold(
                  body: Center(child: NovaThinkingIndicator()),
                ),
              ),
        ),
      ),
    );
  }

  testWidgets('dibuja a NOVA con su texto y una etiqueta accesible', (
    tester,
  ) async {
    await pumpIndicator(tester);

    expect(find.text('NOVA está pensando…'), findsOneWidget);
    expect(find.bySemanticsLabel('NOVA está pensando…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NovaThinkingIndicator),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('se anima mientras NOVA piensa', (tester) async {
    await pumpIndicator(tester);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('se queda quieto si el usuario desactivó las animaciones', (
    tester,
  ) async {
    await pumpIndicator(tester, disableAnimations: true);

    await tester.pumpAndSettle();

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('NOVA está pensando…'), findsOneWidget);
  });
}
