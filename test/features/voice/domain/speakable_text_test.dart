import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/voice/domain/speakable_text.dart';

void main() {
  test('quita negritas, títulos y código', () {
    expect(
      speakableText('## Resumen\nEl **chifa** abre a las `12:00`.'),
      'Resumen\nEl chifa abre a las 12:00.',
    );
  });

  test('lee el texto de los enlaces y omite las direcciones', () {
    expect(
      speakableText(
        'Mira [cómo llegar](https://maps.google.com/x) o '
        'https://example.com ahora',
      ),
      'Mira cómo llegar o ahora',
    );
  });

  test('quita viñetas y numeración de las listas', () {
    expect(
      speakableText('Opciones:\n- Farmacia Inka\n* Botica Sol\n1. Mifarma'),
      'Opciones:\nFarmacia Inka\nBotica Sol\nMifarma',
    );
  });

  test('un texto sin formato queda igual', () {
    expect(speakableText('Hola, soy NOVA.'), 'Hola, soy NOVA.');
  });
}
