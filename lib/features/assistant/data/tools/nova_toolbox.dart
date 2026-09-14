import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/strings/ai_prompts.dart';
import '../../../../core/utils/geo.dart';
import '../../../places/domain/entities/place.dart';
import '../../../places/domain/entities/place_category.dart';
import '../../../places/domain/usecases/search_nearby_places.dart';

/// Funciones de la app que Gemini puede ejecutar (function calling).
class NovaToolbox {
  NovaToolbox(this._searchNearbyPlaces);

  static const searchNearbyPlacesName = 'buscarLugaresCercanos';

  final SearchNearbyPlaces _searchNearbyPlaces;
  List<Place>? _foundPlaces;
  GeoPoint? _foundCenter;

  /// Ubicación desde la que se hizo la última búsqueda con resultados.
  GeoPoint? get lastSearchCenter => _foundCenter;

  late final AutoFunctionDeclaration searchNearbyPlaces =
      AutoFunctionDeclaration(
        name: searchNearbyPlacesName,
        description: AiPrompts.searchPlacesDescription,
        parameters: {
          'categoria': Schema.enumString(
            enumValues: [
              for (final category in PlaceCategory.values) category.name,
            ],
            description: AiPrompts.categoryDescription,
          ),
          'radioMetros': Schema.integer(
            description: AiPrompts.radiusDescription(
              AppConfig.nearbyRadiusMeters,
            ),
            minimum: SearchNearbyPlaces.minRadiusMeters,
            maximum: AppConfig.nearbyRadiusMeters,
          ),
          'nombre': Schema.string(description: AiPrompts.nameDescription),
        },
        optionalParameters: const ['radioMetros', 'nombre'],
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
        'error': AiPrompts.unsupportedCategory,
        'categoriasDisponibles': [
          for (final category in PlaceCategory.values) category.name,
        ],
      };
    }
    final radiusMeters = switch (args['radioMetros']) {
      final num value => value.toInt(),
      _ => AppConfig.nearbyRadiusMeters,
    };
    final name = switch (args['nombre']) {
      final String value when value.trim().isNotEmpty => value.trim(),
      _ => null,
    };

    try {
      final result = await _searchNearbyPlaces(
        category: category,
        radiusMeters: radiusMeters,
        name: name,
      );
      _foundPlaces = result.places;
      _foundCenter = result.center;
      return {
        'categoria': category.label,
        if (name != null) 'nombreBuscado': name,
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
