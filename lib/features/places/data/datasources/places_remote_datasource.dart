import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/strings/error_strings.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/place_category.dart';
import '../models/place_model.dart';

abstract interface class PlacesRemoteDataSource {
  /// Lugares de [category] a menos de [radiusMeters] de [center], sin orden.
  /// Si se indica [name], solo los que contienen ese nombre.
  Future<List<PlaceModel>> fetchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    String? name,
  });
}

/// Consulta OpenStreetMap a través de Overpass.
///
/// Los servidores públicos a veces se cuelgan o rechazan peticiones. En lugar
/// de probarlos en fila (un servidor caído consumiría toda la espera), se
/// escalonan: si el primero no respondió tras [hedgeDelay] se lanza también el
/// siguiente, y se usa la primera respuesta válida.
class OverpassPlacesDataSource implements PlacesRemoteDataSource {
  OverpassPlacesDataSource(
    this._client, {
    List<Uri>? endpoints,
    this.timeout = const Duration(seconds: 15),
    this.hedgeDelay = const Duration(seconds: 2),
  }) : _endpoints = endpoints ?? AppConfig.overpassEndpoints;

  /// Elementos que se piden por consulta antes de ordenar por distancia.
  static const maxElements = 200;

  /// Al buscar un local por nombre se piden más, porque el filtro se aplica
  /// después en el dispositivo.
  static const maxElementsByName = 1000;

  /// La política de uso de Overpass pide identificar la app y un contacto.
  static const userAgent = 'NOVA-AI/0.1 (+${AppConfig.projectUrl})';

  final http.Client _client;
  final List<Uri> _endpoints;
  final Duration timeout;
  final Duration hedgeDelay;

  @override
  Future<List<PlaceModel>> fetchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    String? name,
  }) {
    // El nombre se filtra en el dispositivo: un filtro por expresión regular
    // en Overpass es costoso y empeora los tiempos de servidores saturados.
    final query = buildQuery(
      center: center,
      category: category,
      radiusMeters: radiusMeters,
      maxResults: name == null ? maxElements : maxElementsByName,
    );

    final result = Completer<List<PlaceModel>>();
    final errors = <Object>[];
    var pending = _endpoints.length;

    for (var i = 0; i < _endpoints.length; i++) {
      final endpoint = _endpoints[i];
      Future<void>.delayed(hedgeDelay * i, () async {
        try {
          if (result.isCompleted) return;
          final places = await _request(endpoint, query);
          if (!result.isCompleted) {
            result.complete(
              name == null
                  ? places
                  : places.where((place) => place.matchesName(name)).toList(),
            );
          }
        } catch (error) {
          debugPrint('Overpass falló en $endpoint: $error');
          errors.add(error);
        } finally {
          pending--;
          if (pending == 0 && !result.isCompleted) {
            result.completeError(
              PlacesFailure(
                ErrorStrings.placesUnavailable,
                cause: errors.isEmpty ? null : errors.last,
              ),
            );
          }
        }
      });
    }
    return result.future;
  }

  Future<List<PlaceModel>> _request(Uri endpoint, String query) async {
    final response = await _client
        .post(
          endpoint,
          // Los navegadores no permiten cambiar el User-Agent.
          headers: kIsWeb ? null : const {'User-Agent': userAgent},
          body: {'data': query},
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', endpoint);
    }
    return _parse(utf8.decode(response.bodyBytes));
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
    int maxResults = maxElements,
  }) {
    return '[out:json][timeout:15];'
        'nwr["${category.osmKey}"="${category.osmValue}"]'
        '(around:$radiusMeters,${center.latitude},${center.longitude});'
        'out center $maxResults;';
  }
}
