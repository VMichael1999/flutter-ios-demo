import '../../../../core/config/app_config.dart';
import '../../../../core/services/location_service.dart';
import '../entities/place.dart';
import '../entities/place_category.dart';
import '../repositories/places_repository.dart';

/// Busca lugares cerca de la ubicación actual del usuario.
class SearchNearbyPlaces {
  const SearchNearbyPlaces({
    required LocationService locationService,
    required PlacesRepository repository,
  })  : _locationService = locationService,
        _repository = repository;

  static const minRadiusMeters = 100;

  final LocationService _locationService;
  final PlacesRepository _repository;

  Future<NearbyPlacesResult> call({
    required PlaceCategory category,
    int radiusMeters = AppConfig.nearbyRadiusMeters,
    int limit = AppConfig.nearbyResultLimit,
  }) async {
    final center = await _locationService.getCurrentLocation();
    final radius =
        radiusMeters.clamp(minRadiusMeters, AppConfig.nearbyRadiusMeters);
    final places = await _repository.searchNearby(
      center: center,
      category: category,
      radiusMeters: radius,
      limit: limit,
    );
    return NearbyPlacesResult(
      center: center,
      radiusMeters: radius,
      places: places,
    );
  }
}
