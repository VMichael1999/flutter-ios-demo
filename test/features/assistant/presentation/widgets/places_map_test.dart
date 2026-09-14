import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/theme/app_theme.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/places_map.dart';

import '../../../../fixtures/map_fakes.dart';
import '../../../../fixtures/places_fixtures.dart';

void main() {
  setUp(() => PlacesMap.debugTileProvider = BlankTileProvider());
  tearDown(() => PlacesMap.debugTileProvider = null);

  Future<void> pumpMap(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: PlacesMap(
              places: [chifaPlace, bodegaPlace],
              userLocation: testCenter,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('marca cada lugar con su número y la ubicación del usuario', (
    tester,
  ) async {
    await pumpMap(tester);

    // La vista previa se anuncia como un solo botón; los puntos son visuales.
    // La etiqueta se une con "Ampliar" y la atribución al leerse en voz alta.
    expect(
      find.bySemanticsLabel(RegExp('Mapa con 2 lugares. Toca para ampliarlo.')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('© OpenStreetMap'), findsOneWidget);
    expect(find.text('Ampliar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al tocarlo se abre a pantalla completa con el primer lugar', (
    tester,
  ) async {
    await pumpMap(tester);

    await tester.tap(find.text('Ampliar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(PlacesMapPage), findsOneWidget);
    expect(find.text('Lugares en el mapa'), findsOneWidget);
    expect(find.text('Chifa Miraflores'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });

  testWidgets('en pantalla completa tocar un punto muestra ese lugar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const PlacesMapPage(
          places: [chifaPlace, bodegaPlace],
          userLocation: testCenter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Punto 2: Antigua Bodega Dalmacia'));
    await tester.pumpAndSettle();

    expect(find.text('Antigua Bodega Dalmacia'), findsOneWidget);
    expect(find.text('Chifa Miraflores'), findsNothing);
  });
}
