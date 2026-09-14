import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/entities/place_category.dart';
import '../../../places/domain/usecases/search_nearby_places.dart';

/// Funciones de la app que Gemini puede ejecutar (function calling).
class NovaToolbox {
  NovaToolbox(this._searchNearbyPlaces);

  static const searchNearbyPlacesName = 'buscarLugaresCercanos';

  final SearchNearbyPlaces _searchNearbyPlaces;
  List<Place>? _foundPlaces;

  late final AutoFunctionDeclaration searchNearbyPlaces =
      AutoFunctionDeclaration(
    name: searchNearbyPlacesName,
    description: 'Busca lugares cerca de la ubicación actual del usuario y '
        'devuelve los más cercanos con su distancia en metros.',
    parameters: {
      'categoria': Schema.enumString(
        enumValues: [for (final category in PlaceCategory.values) category.name],
        description: 'Tipo de lugar que busca el usuario.',
      ),
      'radioMetros': Schema.integer(
        description: 'Radio máximo de búsqueda en metros. Por defecto '
            '${AppConfig.nearbyRadiusMeters}.',
        minimum: SearchNearbyPlaces.minRadiusMeters,
        maximum: AppConfig.nearbyRadiusMeters,
      ),
    },
    optionalParameters: const ['radioMetros'],
    callable: handleSearchNearbyPlaces,
  );

  List<Tool> get tools => [
        Tool.functionDeclarations([searchNearbyPlaces]),
      ];

  /// Lugares encontrados desde la última lectura; se vacía al leerlos.
  List<Place>? takeFoundPlaces() {
    final places = _foundPlaces;
    _foundPlaces = null;
    return places;
  }

  @visibleForTesting
  Future<Map<String, Object?>> handleSearchNearbyPlaces(
    Map<String, Object?> args,
  ) async {
    final category = switch (args['categoria']) {
      final String name => PlaceCategory.fromName(name),
      _ => null,
    };
    if (category == null) {
      return {
        'error': 'Categoría no soportada.',
        'categoriasDisponibles': [
          for (final category in PlaceCategory.values) category.name,
        ],
      };
    }
    final radiusMeters = switch (args['radioMetros']) {
      final num value => value.toInt(),
      _ => AppConfig.nearbyRadiusMeters,
    };

    try {
      final result = await _searchNearbyPlaces(
        category: category,
        radiusMeters: radiusMeters,
      );
      _foundPlaces = result.places;
      return {
        'categoria': category.label,
        'radioMetros': result.radiusMeters,
        'cantidad': result.places.length,
        'lugares': [
          for (final place in result.places)
            {
              'nombre': place.name,
              'distanciaMetros': place.distanceMeters.round(),
              if (place.address != null) 'direccion': place.address,
            },
        ],
      };
    } on LocationFailure catch (failure) {
      return {'error': failure.message};
    } on PlacesFailure catch (failure) {
      debugPrint('Error al buscar lugares: $failure');
      return {'error': failure.message};
    }
  }
}
