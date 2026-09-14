import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_message.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/message_bubble.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/place_card.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/typing_indicator.dart';

import '../../../../fixtures/places_fixtures.dart';

void main() {
  Future<void> pumpBubble(WidgetTester tester, ChatMessage message) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MessageBubble(message: message)),
      ),
    );
  }

  testWidgets('muestra el texto y una tarjeta por lugar con su distancia',
      (tester) async {
    await pumpBubble(
      tester,
      const ChatMessage.assistant(
        id: '1',
        text: 'Estos son los restaurantes más cercanos:',
        places: [chifaPlace, bodegaPlace],
      ),
    );

    expect(find.text('Estos son los restaurantes más cercanos:'), findsOneWidget);
    expect(find.byType(PlaceCard), findsNWidgets(2));
    expect(find.text('Chifa Miraflores'), findsOneWidget);
    expect(find.text('850 m'), findsOneWidget);
    expect(find.text('1.3 km'), findsOneWidget);
    expect(find.text('Restaurante · Avenida Angamos Oeste 120'), findsOneWidget);
    expect(find.byTooltip('Cómo llegar'), findsNWidgets(2));
  });

  testWidgets('muestra el indicador de escritura mientras llega la respuesta',
      (tester) async {
    await pumpBubble(
      tester,
      const ChatMessage.assistant(id: '1', isStreaming: true),
    );

    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  test('la ruta de "Cómo llegar" apunta a las coordenadas del lugar', () {
    final uri = directionsUri(chifaPlace);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], '-12.1138,-77.0374');
  });
}
