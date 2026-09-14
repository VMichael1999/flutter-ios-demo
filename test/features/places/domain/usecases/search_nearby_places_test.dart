import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/config/app_config.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/core/services/location_service.dart';
import 'package:nova_ai/core/utils/geo.dart';
import 'package:nova_ai/features/places/domain/entities/place_category.dart';
import 'package:nova_ai/features/places/domain/repositories/places_repository.dart';
import 'package:nova_ai/features/places/domain/usecases/search_nearby_places.dart';

import '../../../../fixtures/places_fixtures.dart';

class _MockLocationService extends Mock implements LocationService {}

class _MockPlacesRepository extends Mock implements PlacesRepository {}

void main() {
  late _MockLocationService locationService;
  late _MockPlacesRepository repository;
  late SearchNearbyPlaces searchNearbyPlaces;

  setUpAll(() {
    registerFallbackValue(const GeoPoint(0, 0));
    registerFallbackValue(PlaceCategory.restaurant);
  });

  setUp(() {
    locationService = _MockLocationService();
    repository = _MockPlacesRepository();
    searchNearbyPlaces = SearchNearbyPlaces(
      locationService: locationService,
      repository: repository,
    );
    when(() => locationService.getCurrentLocation())
        .thenAnswer((_) async => testCenter);
    when(
      () => repository.searchNearby(
        center: any(named: 'center'),
        category: any(named: 'category'),
        radiusMeters: any(named: 'radiusMeters'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [chifaPlace, bodegaPlace]);
  });

  test('busca en un radio de 5 km alrededor de la ubicación actual', () async {
    final result = await searchNearbyPlaces(category: PlaceCategory.restaurant);

    expect(result.center, testCenter);
    expect(result.radiusMeters, AppConfig.nearbyRadiusMeters);
    expect(result.places, [chifaPlace, bodegaPlace]);
    verify(
      () => repository.searchNearby(
        center: testCenter,
        category: PlaceCategory.restaurant,
        radiusMeters: 5000,
        limit: AppConfig.nearbyResultLimit,
      ),
    ).called(1);
  });

  test('nunca busca más lejos de 5 km', () async {
    final result = await searchNearbyPlaces(
      category: PlaceCategory.restaurant,
      radiusMeters: 50000,
    );

    expect(result.radiusMeters, 5000);
  });

  test('propaga el error si no hay permiso de ubicación', () async {
    when(() => locationService.getCurrentLocation()).thenThrow(
      const LocationFailure(
        'No diste permiso para usar tu ubicación.',
        reason: LocationFailureReason.permissionDenied,
      ),
    );

    expect(
      searchNearbyPlaces(category: PlaceCategory.restaurant),
      throwsA(isA<LocationFailure>()),
    );
    verifyNever(
      () => repository.searchNearby(
        center: any(named: 'center'),
        category: any(named: 'category'),
        radiusMeters: any(named: 'radiusMeters'),
        limit: any(named: 'limit'),
      ),
    );
  });
}
