import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/home/presentation/pages/home_page.dart';

void main() {
  /// Dibuja la home con el tamaño de un teléfono y el tamaño de letra dado.
  /// Cualquier desbordamiento de diseño hace fallar el test.
  Future<void> pumpHomeOnPhone(
    WidgetTester tester, {
    required Size logicalSize,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = logicalSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('los accesos rápidos caben en un teléfono de 360 px',
      (tester) async {
    await pumpHomeOnPhone(tester, logicalSize: const Size(360, 800));

    for (final label in ['Cámara', 'Voz', 'Documento', 'Ubicación']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('los accesos rápidos no se desbordan con la letra al 130 %',
      (tester) async {
    await pumpHomeOnPhone(
      tester,
      logicalSize: const Size(360, 800),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
