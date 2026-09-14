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

  OverpassPlacesDataSource dataSourceWith(
    http.Client client, {
    List<Uri>? endpoints,
    Duration hedgeDelay = Duration.zero,
  }) {
    return OverpassPlacesDataSource(
      client,
      endpoints: endpoints ?? [primary],
      hedgeDelay: hedgeDelay,
      timeout: const Duration(seconds: 2),
    );
  }

  Future<List<String>> fetchNames(OverpassPlacesDataSource dataSource) async {
    final places = await dataSource.fetchNearby(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 1000,
    );
    return [for (final place in places) place.name];
  }

  test('envía la consulta de la categoría y el radio identificando la app',
      () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return jsonResponse(overpassBody);
    });

    await dataSourceWith(client).fetchNearby(
      center: testCenter,
      category: PlaceCategory.pharmacy,
      radiusMeters: 5000,
    );

    final query = Uri.decodeQueryComponent(sent.body);
    expect(query, contains('nwr["amenity"="pharmacy"]'));
    expect(query, contains('around:5000,-12.1211,-77.0297'));
    expect(query, contains('[out:json]'));
    expect(sent.headers['User-Agent'], OverpassPlacesDataSource.userAgent);
  });

  test('filtra por el nombre del local sin permitir inyecciones', () {
    final query = OverpassPlacesDataSource.buildQuery(
      center: testCenter,
      category: PlaceCategory.restaurant,
      radiusMeters: 5000,
      name: 'Café "Tostado"; out;',
    );

    expect(query, contains('["name"~"Café Tostado out",i]'));
    expect(OverpassPlacesDataSource.sanitizePlaceName('  ~~~  '), isNull);
    expect(
      OverpassPlacesDataSource.buildQuery(
        center: testCenter,
        category: PlaceCategory.restaurant,
        radiusMeters: 5000,
      ),
      isNot(contains('"name"')),
    );
  });

  test('devuelve solo los lugares con nombre y coordenadas', () async {
    final client = MockClient((_) async => jsonResponse(overpassBody));

    expect(
      await fetchNames(dataSourceWith(client)),
      ['Chifa Miraflores', 'Antigua Bodega Dalmacia'],
    );
  });

  test('usa otro servidor si el primero está saturado', () async {
    final client = MockClient((request) async {
      return request.url == primary
          ? http.Response('Gateway Timeout', 504)
          : jsonResponse(overpassBody);
    });

    final names = await fetchNames(
      dataSourceWith(client, endpoints: [primary, mirror]),
    );

    expect(names, hasLength(2));
  });

  test('no espera a un servidor colgado: usa el primero que responde',
      () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      if (request.url == primary) {
        // Nunca responde a tiempo, como overpass.private.coffee.
        await Future<void>.delayed(const Duration(seconds: 10));
      }
      return jsonResponse(overpassBody);
    });
    final dataSource = dataSourceWith(
      client,
      endpoints: [primary, mirror],
      hedgeDelay: const Duration(milliseconds: 50),
    );

    final stopwatch = Stopwatch()..start();
    final names = await fetchNames(dataSource);

    expect(names, hasLength(2));
    expect(requested, [primary, mirror]);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('no lanza el siguiente servidor si el primero ya respondió', () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      return jsonResponse(overpassBody);
    });

    await fetchNames(
      dataSourceWith(
        client,
        endpoints: [primary, mirror],
        hedgeDelay: const Duration(milliseconds: 100),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(requested, [primary]);
  });

  test('lanza PlacesFailure si ningún servidor responde', () async {
    final client = MockClient((request) async {
      if (request.url == primary) throw http.ClientException('sin red');
      return http.Response('no es json', 200);
    });

    expect(
      dataSourceWith(client, endpoints: [primary, mirror]).fetchNearby(
        center: testCenter,
        category: PlaceCategory.restaurant,
        radiusMeters: 1000,
      ),
      throwsA(isA<PlacesFailure>()),
    );
  });
}
