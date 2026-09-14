import '../../../../core/utils/geo.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_remote_datasource.dart';
import '../models/place_model.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._dataSource);

  /// Overpass no ordena por distancia y limita cuántos elementos devuelve:
  /// se busca primero en un radio pequeño y se amplía solo si faltan lugares.
  static const searchStepsMeters = [1000, 2500];

  /// OpenStreetMap a veces registra un local dos veces (como punto y como
  /// edificio). Dos sucursales con el mismo nombre suelen estar más lejos.
  static const duplicateVenueMeters = 150;

  final PlacesRemoteDataSource _dataSource;

  @override
  Future<List<Place>> searchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    required int limit,
    String? name,
  }) async {
    // Un local concreto suele tener pocas coincidencias: ampliar el radio por
    // pasos solo multiplicaría las consultas, así que se busca directamente
    // en el radio completo.
    final radii = [
      if (name == null)
        for (final step in searchStepsMeters)
          if (step < radiusMeters) step,
      radiusMeters,
    ];

    var nearest = <Place>[];
    for (final radius in radii) {
      final models = await _dataSource.fetchNearby(
        center: center,
        category: category,
        radiusMeters: radius,
        name: name,
      );
      nearest = _nearest(
        models,
        center: center,
        category: category,
        radiusMeters: radius,
        limit: limit,
      );
      if (nearest.length >= limit) break;
    }
    return nearest;
  }

  static List<Place> _nearest(
    List<PlaceModel> models, {
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    required int limit,
  }) {
    final seenIds = <String>{};
    final places = [
      for (final model in models)
        if (seenIds.add(model.id))
          model.toEntity(center: center, category: category),
    ].where((place) => place.distanceMeters <= radiusMeters).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    final nearest = <Place>[];
    for (final place in places) {
      if (nearest.length == limit) break;
      if (!nearest.any((kept) => _isSameVenue(kept, place))) nearest.add(place);
    }
    return nearest;
  }

  static bool _isSameVenue(Place a, Place b) {
    return a.name.trim().toLowerCase() == b.name.trim().toLowerCase() &&
        distanceInMeters(a.location, b.location) < duplicateVenueMeters;
  }
}
