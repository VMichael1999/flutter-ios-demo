import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/config/app_config.dart';

/// Las URLs vienen de `.env` (o de sus valores por defecto). Correr también
/// con `flutter test --dart-define-from-file=.env test/config` comprueba que
/// el `.env` local está bien escrito.
void main() {
  test('los servidores de Overpass se leen como URLs válidas', () {
    expect(AppConfig.overpassEndpoints, isNotEmpty);
    for (final endpoint in AppConfig.overpassEndpoints) {
      expect(endpoint.scheme, 'https');
      expect(endpoint.host, isNotEmpty);
    }
  });

  test('la plantilla de mapas tiene zoom y coordenadas', () {
    expect(
      AppConfig.mapTileUrl,
      allOf(
        startsWith('https://'),
        contains('{z}'),
        contains('{x}'),
        contains('{y}'),
      ),
    );
  });

  test('las URLs de rutas y del proyecto son válidas', () {
    expect(Uri.parse(AppConfig.directionsUrl).host, isNotEmpty);
    expect(Uri.parse(AppConfig.projectUrl).host, isNotEmpty);
  });
}
