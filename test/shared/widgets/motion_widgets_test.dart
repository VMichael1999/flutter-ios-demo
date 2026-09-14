import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/theme/motion.dart';
import 'package:nova_ai/shared/widgets/entrance.dart';
import 'package:nova_ai/shared/widgets/pressable.dart';

void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MaterialApp(
    home: Builder(
      builder:
          (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: Scaffold(body: Center(child: child)),
          ),
    ),
  );

  double opacityOf(WidgetTester tester) =>
      tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(Entrance),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;

  group('Entrance', () {
    testWidgets('entra con fundido y termina visible', (tester) async {
      await tester.pumpWidget(app(const Entrance(child: Text('Hola'))));

      expect(opacityOf(tester), 0);
      await tester.pump(Motion.enter ~/ 2);
      expect(opacityOf(tester), greaterThan(0.5));
      await tester.pumpAndSettle();
      expect(opacityOf(tester), 1);
    });

    testWidgets('respeta la espera antes de entrar', (tester) async {
      await tester.pumpWidget(
        app(
          const Entrance(
            delay: Duration(milliseconds: 100),
            child: Text('Hola'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 90));
      expect(opacityOf(tester), 0);
      await tester.pumpAndSettle();
      expect(opacityOf(tester), 1);
    });

    testWidgets('desactivada aparece directamente', (tester) async {
      await tester.pumpWidget(
        app(const Entrance(enabled: false, child: Text('Hola'))),
      );

      expect(opacityOf(tester), 1);
    });

    testWidgets('sin animaciones solo hay fundido, sin desplazamiento', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const Entrance(child: Text('Hola')), disableAnimations: true),
      );

      expect(
        find.descendant(
          of: find.byType(Entrance),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  group('Pressable', () {
    Widget card() => Pressable(
      builder:
          (context, onHighlightChanged) => Material(
            child: InkWell(
              onTap: () {},
              onHighlightChanged: onHighlightChanged,
              child: const SizedBox(width: 120, height: 80),
            ),
          ),
    );

    double scaleOf(WidgetTester tester) =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    testWidgets('se hunde mientras se presiona y vuelve al soltar', (
      tester,
    ) async {
      await tester.pumpWidget(app(card()));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(InkWell)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(scaleOf(tester), Motion.pressedScale);

      await gesture.up();
      await tester.pump();
      expect(scaleOf(tester), 1);
    });

    testWidgets('sin animaciones no cambia de tamaño', (tester) async {
      await tester.pumpWidget(app(card(), disableAnimations: true));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(InkWell)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(scaleOf(tester), 1);
      await gesture.up();
    });
  });
}
