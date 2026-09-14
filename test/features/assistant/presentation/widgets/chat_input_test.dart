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
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInput(
            controller: controller,
            isStreaming: isStreaming,
            attachment: attachment,
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
    expect(find.text('Escribe a NOVA…'), findsOneWidget);
  });

  testWidgets('muestra la vista previa y permite quitar la imagen',
      (tester) async {
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
}
