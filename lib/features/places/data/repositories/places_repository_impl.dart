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

  final PlacesRemoteDataSource _dataSource;

  @override
  Future<List<Place>> searchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    required int limit,
  }) async {
    final radii = [
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
    return places.take(limit).toList();
  }
}
