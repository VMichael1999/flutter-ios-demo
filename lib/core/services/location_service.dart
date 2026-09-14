import 'package:geolocator/geolocator.dart';

import '../errors/failures.dart';
import '../strings/error_strings.dart';
import '../utils/geo.dart';

abstract interface class LocationService {
  /// Pide permiso si hace falta y devuelve la posición actual.
  ///
  /// Lanza [LocationFailure] si no es posible obtenerla.
  Future<GeoPoint> getCurrentLocation();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static const _timeLimit = Duration(seconds: 15);

  @override
  Future<GeoPoint> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        ErrorStrings.locationDisabled,
        reason: LocationFailureReason.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationFailure(
          ErrorStrings.locationDenied,
          reason: LocationFailureReason.permissionDenied,
        );
      case LocationPermission.deniedForever:
        throw const LocationFailure(
          ErrorStrings.locationBlocked,
          reason: LocationFailureReason.permissionDeniedForever,
        );
      case LocationPermission.whileInUse ||
          LocationPermission.always ||
          LocationPermission.unableToDetermine:
        break;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeLimit,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (error) {
      throw LocationFailure(ErrorStrings.locationUnavailable, cause: error);
    }
  }
}
