import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/features/places/data/datasources/places_remote_datasource.dart';
import 'package:nova_ai/features/places/domain/entities/place_category.dart';

import '../../../../fixtures/places_fixtures.dart';

void main() {
  final primary = Uri.parse('https://primary.test/api/interpreter');
  final mirror = Uri.parse('https://mirror.test/api/interpreter');

  http.Response jsonResponse(Object body) =>
      http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

  const overpassBody = {
    'elements': [
      {
        'type': 'node',
        'id': 1,
        'lat': -12.1138,
        'lon': -77.0374,
        'tags': {'name': 'Chifa Miraflores', 'amenity': 'restaurant'},
      },
      {
        'type': 'way',
        'id': 2,
        'center': {'lat': -12.1324, 'lon': -77.0266},
        'tags': {'name': 'Antigua Bodega Dalmacia'},
      },
      {
        'type': 'node',
        'id': 3,
        'lat': -12.12,
        'lon': -77.03,
        'tags': {'amenity': 'restaurant'},
      },
    ],
  };

  test('envía la consulta de la categoría y el radio', () async {
    late String query;
    final client = MockClient((request) async {
      query = Uri.decodeQueryComponent(request.body);
      return jsonResponse(overpassBody);
    });
    final dataSource = OverpassPlacesDataSource(client, endpoints: [primary]);

    await dataSource.fetchNearby(
      center: testCenter,
      category: PlaceCategory.pharmacy,
      radiusMeters: 5000,
    );

    expect(query, contains('nwr["amenity"="pharmacy"]'));
    expect(query, contains('around:5000,-12.1211,-77.0297'));
    expect(query, contains('[out:json]'));
  });

  test('devuelve solo los lugares con nombre y coordenadas', () async {
    final client = MockClient((_) async => jsonResponse(overpassBody));
    final dataSource = OverpassPlacesDataSource(client, endpoints: [primary]);

    final places = await dataSource.fetchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 5000,
    );

    expect(places.map((p) => p.name), [
      'Chifa Miraflores',
      'Antigua Bodega Dalmacia',
    ]);
  });

  test('usa el siguiente servidor si el primero está saturado', () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      return request.url == primary
          ? http.Response('Gateway Timeout', 504)
          : jsonResponse(overpassBody);
    });
    final dataSource =
        OverpassPlacesDataSource(client, endpoints: [primary, mirror]);

    final places = await dataSource.fetchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 1000,
    );

    expect(requested, [primary, mirror]);
    expect(places, hasLength(2));
  });

  test('lanza PlacesFailure si ningún servidor responde', () async {
    final client = MockClient((request) async {
      if (request.url == primary) throw http.ClientException('sin red');
      return http.Response('no es json', 200);
    });
    final dataSource =
        OverpassPlacesDataSource(client, endpoints: [primary, mirror]);

    expect(
      dataSource.fetchNearby(
        center: testCenter,
        category: PlaceCategory.restaurant,
        radiusMeters: 1000,
      ),
      throwsA(isA<PlacesFailure>()),
    );
  });
}
