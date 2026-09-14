import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/place_category.dart';
import '../models/place_model.dart';

abstract interface class PlacesRemoteDataSource {
  /// Lugares de [category] a menos de [radiusMeters] de [center], sin orden.
  Future<List<PlaceModel>> fetchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
  });
}

/// Consulta OpenStreetMap a través de Overpass. Si un servidor falla o está
/// saturado, prueba con el siguiente.
class OverpassPlacesDataSource implements PlacesRemoteDataSource {
  OverpassPlacesDataSource(
    this._client, {
    List<Uri>? endpoints,
    // Si un servidor está saturado conviene pasar pronto al siguiente.
    this.timeout = const Duration(seconds: 8),
  }) : _endpoints = endpoints ?? AppConfig.overpassEndpoints;

  /// Elementos que se piden por consulta antes de ordenar por distancia.
  static const maxElements = 200;

  final http.Client _client;
  final List<Uri> _endpoints;
  final Duration timeout;

  @override
  Future<List<PlaceModel>> fetchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
  }) async {
    final query = buildQuery(
      center: center,
      category: category,
      radiusMeters: radiusMeters,
    );

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await _client
            .post(
              endpoint,
              // Los navegadores no permiten cambiar el User-Agent.
              headers: kIsWeb ? null : const {'User-Agent': 'NOVA-AI/0.1'},
              body: {'data': query},
            )
            .timeout(timeout);
        if (response.statusCode != 200) {
          lastError = 'HTTP ${response.statusCode} en $endpoint';
          continue;
        }
        return _parse(utf8.decode(response.bodyBytes));
      } catch (error) {
        lastError = error;
      }
    }
    throw PlacesFailure(
      'No se pudo consultar el servicio de lugares. Inténtalo de nuevo en unos minutos.',
      cause: lastError,
    );
  }

  static List<PlaceModel> _parse(String body) {
    final json = jsonDecode(body);
    final elements = json is Map ? json['elements'] : null;
    if (elements is! List) {
      throw const FormatException('Respuesta de Overpass sin "elements"');
    }
    final places = <PlaceModel>[];
    for (final element in elements) {
      if (element is! Map) continue;
      final place = PlaceModel.fromOverpassElement(
        element.cast<String, Object?>(),
      );
      if (place != null) places.add(place);
    }
    return places;
  }

  @visibleForTesting
  static String buildQuery({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
  }) {
    return '[out:json][timeout:15];'
        'nwr["${category.osmKey}"="${category.osmValue}"]'
        '(around:$radiusMeters,${center.latitude},${center.longitude});'
        'out center $maxElements;';
  }
}
