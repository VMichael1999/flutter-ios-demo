import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/assistant/data/services/media_picker_service.dart';

void main() {
  group('imageMimeTypeFor', () {
    test('reconoce los formatos de imagen habituales', () {
      expect(imageMimeTypeFor('letrero.PNG'), 'image/png');
      expect(imageMimeTypeFor('menu.webp'), 'image/webp');
      expect(imageMimeTypeFor('IMG_0001.HEIC'), 'image/heic');
      expect(imageMimeTypeFor('foto.jpeg'), 'image/jpeg');
    });

    test('usa JPEG si no reconoce la extensión', () {
      expect(imageMimeTypeFor('captura'), 'image/jpeg');
    });
  });
}
