import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/domain/entities/chat_attachment.dart';
import 'package:nova_ai/features/assistant/presentation/widgets/chat_input.dart';

import '../../../../fixtures/places_fixtures.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pumpInput(
    WidgetTester tester, {
    bool isStreaming = false,
    ChatAttachment? attachment,
    VoidCallback? onAttach,
    VoidCallback? onRemoveAttachment,
    bool isListening = false,
    VoidCallback? onMicTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInput(
            controller: controller,
            isStreaming: isStreaming,
            attachment: attachment,
            isListening: isListening,
            onMicTap: onMicTap,
            onSend: () {},
            onStop: () {},
            onAttach: onAttach ?? () {},
            onRemoveAttachment: onRemoveAttachment ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('abre el selector de imagen', (tester) async {
    var attachTapped = false;
    await pumpInput(tester, onAttach: () => attachTapped = true);

    await tester.tap(find.byTooltip('Adjuntar imagen'));

    expect(attachTapped, isTrue);
    expect(find.text('Escribe o dicta a NOVA…'), findsOneWidget);
  });

  testWidgets('muestra la vista previa y permite quitar la imagen', (
    tester,
  ) async {
    var removed = false;
    await pumpInput(
      tester,
      attachment: testImageAttachment,
      onRemoveAttachment: () => removed = true,
    );

    expect(find.bySemanticsLabel('Imagen para enviar'), findsOneWidget);
    expect(find.text('Pregunta sobre la imagen…'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar imagen'));
    expect(removed, isTrue);
  });

  testWidgets('no deja adjuntar mientras NOVA responde', (tester) async {
    await pumpInput(tester, isStreaming: true);

    final attachButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_photo_alternate_outlined),
    );
    expect(attachButton.onPressed, isNull);
    expect(find.byTooltip('Detener'), findsOneWidget);
  });

  testWidgets('sin dictado disponible no muestra el micrófono', (tester) async {
    await pumpInput(tester);

    expect(find.byTooltip('Dictar'), findsNothing);
  });

  testWidgets('el micrófono empieza el dictado', (tester) async {
    var micTapped = false;
    await pumpInput(tester, onMicTap: () => micTapped = true);

    await tester.tap(find.byTooltip('Dictar'));

    expect(micTapped, isTrue);
  });

  testWidgets('mientras dicta avisa que escucha y permite terminar', (
    tester,
  ) async {
    await pumpInput(tester, isListening: true, onMicTap: () {});

    expect(find.text('Te escucho…'), findsOneWidget);
    expect(find.byTooltip('Dejar de dictar'), findsOneWidget);
  });
}
