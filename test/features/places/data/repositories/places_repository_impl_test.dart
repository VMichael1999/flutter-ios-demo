import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/utils/geo.dart';
import 'package:nova_ai/features/places/data/datasources/places_remote_datasource.dart';
import 'package:nova_ai/features/places/data/models/place_model.dart';
import 'package:nova_ai/features/places/data/repositories/places_repository_impl.dart';
import 'package:nova_ai/features/places/domain/entities/place_category.dart';

import '../../../../fixtures/places_fixtures.dart';

/// Devuelve, para cada radio, los lugares configurados en [byRadius].
class _FakePlacesDataSource implements PlacesRemoteDataSource {
  _FakePlacesDataSource(this.byRadius);

  final Map<int, List<PlaceModel>> byRadius;
  final requestedRadii = <int>[];
  final requestedNames = <String?>[];

  @override
  Future<List<PlaceModel>> fetchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    String? name,
  }) async {
    requestedRadii.add(radiusMeters);
    requestedNames.add(name);
    return byRadius[radiusMeters] ?? const [];
  }
}

/// Lugar desplazado hacia el norte del centro de pruebas.
PlaceModel _placeAt(String id, {required double metersNorth, String? name}) =>
    PlaceModel(
      id: id,
      name: name ?? 'Lugar $id',
      latitude: testCenter.latitude + metersNorth / 111195,
      longitude: testCenter.longitude,
    );

void main() {
  test('ordena del más cercano al más lejano y respeta el límite', () async {
    final dataSource = _FakePlacesDataSource({
      1000: [
        _placeAt('c', metersNorth: 900),
        _placeAt('a', metersNorth: 100),
        _placeAt('b', metersNorth: 500),
      ],
    });
    final repository = PlacesRepositoryImpl(dataSource);

    final places = await repository.searchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 5000,
      limit: 2,
    );

    expect(places.map((p) => p.id), ['a', 'b']);
    expect(dataSource.requestedRadii, [1000]);
  });

  test('amplía el radio hasta 5 km solo si faltan lugares', () async {
    final dataSource = _FakePlacesDataSource({
      1000: [_placeAt('cerca', metersNorth: 300)],
      2500: [_placeAt('cerca', metersNorth: 300)],
      5000: [
        _placeAt('cerca', metersNorth: 300),
        _placeAt('lejos', metersNorth: 4000),
      ],
    });
    final repository = PlacesRepositoryImpl(dataSource);

    final places = await repository.searchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 5000,
      limit: 5,
    );

    expect(dataSource.requestedRadii, [1000, 2500, 5000]);
    expect(places.map((p) => p.id), ['cerca', 'lejos']);
  });

  test('pasa el nombre buscado en cada consulta', () async {
    final dataSource = _FakePlacesDataSource({});
    final repository = PlacesRepositoryImpl(dataSource);

    await repository.searchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 2500,
      limit: 1,
      name: 'Chifa',
    );

    expect(dataSource.requestedNames, ['Chifa', 'Chifa']);
  });

  test('muestra una sola vez el mismo local registrado dos veces', () async {
    final dataSource = _FakePlacesDataSource({
      1000: [
        _placeAt('nodo', metersNorth: 87, name: 'La fuente de Soda'),
        _placeAt('edificio', metersNorth: 93, name: 'La Fuente de Soda'),
        _placeAt('sucursal', metersNorth: 900, name: 'La Fuente de Soda'),
      ],
    });
    final repository = PlacesRepositoryImpl(dataSource);

    final places = await repository.searchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 1000,
      limit: 5,
    );

    expect(places.map((p) => p.id), ['nodo', 'sucursal']);
  });

  test('descarta lugares fuera del radio y duplicados', () async {
    final dataSource = _FakePlacesDataSource({
      1000: [
        _placeAt('dentro', metersNorth: 800),
        _placeAt('dentro', metersNorth: 800),
        _placeAt('fuera', metersNorth: 1500),
      ],
    });
    final repository = PlacesRepositoryImpl(dataSource);

    final places = await repository.searchNearby(
      center: testCenter,
      category: PlaceCategory.cafe,
      radiusMeters: 1000,
      limit: 5,
    );

    expect(places.map((p) => p.id), ['dentro']);
    expect(places.single.category, PlaceCategory.cafe);
  });
}
