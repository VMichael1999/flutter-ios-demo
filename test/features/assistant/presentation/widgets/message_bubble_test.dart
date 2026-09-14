import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/message_bubble.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/nova_thinking_indicator.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/place_card.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/places_map.dart';

import '../../../../fixtures/map_fakes.dart';
import '../../../../fixtures/places_fixtures.dart';

void main() {
  // Las respuestas con lugares incluyen un mapa: sin descargas en los tests.
  setUp(() => PlacesMap.debugTileProvider = BlankTileProvider());
  tearDown(() => PlacesMap.debugTileProvider = null);

  Future<void> pumpBubble(WidgetTester tester, ChatMessage message) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MessageBubble(message: message))),
    );
  }

  testWidgets('muestra el texto y una tarjeta por lugar con su distancia', (
    tester,
  ) async {
    await pumpBubble(
      tester,
      const ChatMessage.assistant(
        id: '1',
        text: 'Estos son los restaurantes más cercanos:',
        places: [chifaPlace, bodegaPlace],
      ),
    );

    expect(
      find.text('Estos son los restaurantes más cercanos:'),
      findsOneWidget,
    );
    expect(find.byType(PlaceCard), findsNWidgets(2));
    expect(find.text('Chifa Miraflores'), findsOneWidget);
    expect(find.text('850 m'), findsOneWidget);
    expect(find.text('1.3 km'), findsOneWidget);
    expect(
      find.text('Restaurante · Avenida Angamos Oeste 120'),
      findsOneWidget,
    );
    expect(find.byTooltip('Cómo llegar'), findsNWidgets(2));
  });

  testWidgets('muestra la foto que envió el usuario', (tester) async {
    await pumpBubble(
      tester,
      ChatMessage.user(id: '1', text: '', attachment: testImageAttachment),
    );

    expect(find.bySemanticsLabel('Imagen enviada'), findsOneWidget);
  });

  testWidgets('muestra a NOVA pensando mientras llega la respuesta', (
    tester,
  ) async {
    await pumpBubble(
      tester,
      const ChatMessage.assistant(id: '1', isStreaming: true),
    );

    expect(find.byType(NovaThinkingIndicator), findsOneWidget);
    expect(find.text('NOVA está pensando…'), findsOneWidget);
  });

  testWidgets('deja de mostrar a NOVA pensando cuando llega el primer texto', (
    tester,
  ) async {
    await pumpBubble(
      tester,
      const ChatMessage.assistant(id: '1', text: 'Hola', isStreaming: true),
    );

    expect(find.byType(NovaThinkingIndicator), findsNothing);
    expect(find.text('Hola ▍'), findsOneWidget);
  });

  test('la ruta de "Cómo llegar" apunta a las coordenadas del lugar', () {
    final uri = directionsUri(chifaPlace);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], '-12.1138,-77.0374');
  });
}
