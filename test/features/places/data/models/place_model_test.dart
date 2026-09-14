import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/places/data/models/place_model.dart';
import 'package:nova_ai/features/places/domain/entities/place_category.dart';

import '../../../../fixtures/places_fixtures.dart';

void main() {
  group('PlaceModel.fromOverpassElement', () {
    test('lee un nodo con nombre, coordenadas y dirección', () {
      final model = PlaceModel.fromOverpassElement({
        'type': 'node',
        'id': 598825401,
        'lat': -12.1138226,
        'lon': -77.0373902,
        'tags': {
          'name': 'Chifa',
          'addr:street': 'Avenida Angamos Oeste',
          'addr:housenumber': '120',
        },
      });

      expect(model, isNotNull);
      expect(model!.id, 'node/598825401');
      expect(model.name, 'Chifa');
      expect(model.latitude, -12.1138226);
      expect(model.address, 'Avenida Angamos Oeste 120');
    });

    test('usa el centro de las vías y relaciones', () {
      final model = PlaceModel.fromOverpassElement({
        'type': 'way',
        'id': 7,
        'center': {'lat': -12.13, 'lon': -77.02},
        'tags': {'name': 'Bodega'},
      });

      expect(model?.latitude, -12.13);
      expect(model?.longitude, -77.02);
      expect(model?.address, isNull);
    });

    test('descarta elementos sin nombre o sin coordenadas', () {
      expect(
        PlaceModel.fromOverpassElement({
          'type': 'node',
          'id': 1,
          'lat': 0,
          'lon': 0,
          'tags': {'amenity': 'restaurant'},
        }),
        isNull,
      );
      expect(
        PlaceModel.fromOverpassElement({
          'type': 'way',
          'id': 2,
          'tags': {'name': 'Sin centro'},
        }),
        isNull,
      );
    });
  });

  test('toEntity calcula la distancia desde el centro', () {
    const model = PlaceModel(
      id: 'node/1',
      name: 'Chifa',
      latitude: -12.1211,
      longitude: -77.0297,
    );

    final place = model.toEntity(
      center: testCenter,
      category: PlaceCategory.restaurant,
    );

    expect(place.distanceMeters, 0);
    expect(place.category, PlaceCategory.restaurant);
  });
}
