import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/features/assistant/data/tools/nova_toolbox.dart';
import 'package:nova_ai/features/places/domain/entities/place.dart';
import 'package:nova_ai/features/places/domain/entities/place_category.dart';
import 'package:nova_ai/features/places/domain/usecases/search_nearby_places.dart';

import '../../../../fixtures/places_fixtures.dart';

class _MockSearchNearbyPlaces extends Mock implements SearchNearbyPlaces {}

void main() {
  late _MockSearchNearbyPlaces searchNearbyPlaces;
  late NovaToolbox toolbox;

  setUpAll(() => registerFallbackValue(PlaceCategory.restaurant));

  setUp(() {
    searchNearbyPlaces = _MockSearchNearbyPlaces();
    toolbox = NovaToolbox(searchNearbyPlaces);
  });

  void stubSearch(Future<NearbyPlacesResult> Function() answer) {
    when(
      () => searchNearbyPlaces(
        category: any(named: 'category'),
        radiusMeters: any(named: 'radiusMeters'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) => answer());
  }

  const twoPlaces = NearbyPlacesResult(
    center: testCenter,
    radiusMeters: 5000,
    places: [chifaPlace, bodegaPlace],
  );

  test('declara la función buscarLugaresCercanos', () {
    expect(toolbox.searchNearbyPlaces.name, NovaToolbox.searchNearbyPlacesName);
    expect(toolbox.tools, hasLength(1));
  });

  test('devuelve a Gemini los lugares más cercanos con su distancia', () async {
    stubSearch(() async => twoPlaces);

    final result = await toolbox.handleSearchNearbyPlaces({
      'categoria': 'restaurant',
    });

    expect(result['cantidad'], 2);
    expect(result['radioMetros'], 5000);
    expect(result.containsKey('nombreBuscado'), isFalse);
    expect(result['lugares'], [
      {
        'nombre': 'Chifa Miraflores',
        'distanciaMetros': 850,
        'direccion': 'Avenida Angamos Oeste 120',
      },
      {'nombre': 'Antigua Bodega Dalmacia', 'distanciaMetros': 1250},
    ]);
    verify(
      () => searchNearbyPlaces(
        category: PlaceCategory.restaurant,
        radiusMeters: 5000,
        name: null,
      ),
    ).called(1);
  });

  test('busca un local por el nombre leído en una foto', () async {
    stubSearch(
      () async => const NearbyPlacesResult(
        center: testCenter,
        radiusMeters: 5000,
        places: [chifaPlace],
      ),
    );

    final result = await toolbox.handleSearchNearbyPlaces({
      'categoria': 'restaurant',
      'nombre': '  Chifa Miraflores ',
    });

    expect(result['nombreBuscado'], 'Chifa Miraflores');
    verify(
      () => searchNearbyPlaces(
        category: PlaceCategory.restaurant,
        radiusMeters: 5000,
        name: 'Chifa Miraflores',
      ),
    ).called(1);
  });

  test(
    'guarda los lugares para la interfaz y los entrega una sola vez',
    () async {
      stubSearch(() async => twoPlaces);

      await toolbox.handleSearchNearbyPlaces({
        'categoria': 'restaurant',
        'radioMetros': 2000,
      });

      expect(toolbox.takeFoundPlaces(), [chifaPlace, bodegaPlace]);
      expect(toolbox.takeFoundPlaces(), isNull);
      verify(
        () => searchNearbyPlaces(
          category: PlaceCategory.restaurant,
          radiusMeters: 2000,
          name: null,
        ),
      ).called(1);
    },
  );

  test('rechaza categorías desconocidas sin buscar', () async {
    final result = await toolbox.handleSearchNearbyPlaces({
      'categoria': 'discoteca-espacial',
    });

    expect(result['error'], 'Categoría no soportada.');
    expect(result['categoriasDisponibles'], contains('restaurant'));
    verifyNever(
      () => searchNearbyPlaces(
        category: any(named: 'category'),
        radiusMeters: any(named: 'radiusMeters'),
        name: any(named: 'name'),
      ),
    );
  });

  test('explica a Gemini cuando no hay permiso de ubicación', () async {
    stubSearch(
      () async =>
          throw const LocationFailure(
            'No diste permiso para usar tu ubicación.',
          ),
    );

    final result = await toolbox.handleSearchNearbyPlaces({
      'categoria': 'restaurant',
    });

    expect(result, {'error': 'No diste permiso para usar tu ubicación.'});
    expect(toolbox.takeFoundPlaces(), isNull);
  });

  test('explica a Gemini cuando el servicio de lugares falla', () async {
    stubSearch(() async => throw const PlacesFailure('Servicio caído'));

    final result = await toolbox.handleSearchNearbyPlaces({
      'categoria': 'pharmacy',
    });

    expect(result, {'error': 'Servicio caído'});
  });
}
