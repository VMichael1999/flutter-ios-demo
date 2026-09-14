import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Distancia en metros entre dos puntos usando la fórmula de Haversine.
double distanceInMeters(GeoPoint from, GeoPoint to) {
  const earthRadiusMeters = 6371000.0;
  final deltaLatitude = _toRadians(to.latitude - from.latitude);
  final deltaLongitude = _toRadians(to.longitude - from.longitude);
  final a = math.pow(math.sin(deltaLatitude / 2), 2) +
      math.cos(_toRadians(from.latitude)) *
          math.cos(_toRadians(to.latitude)) *
          math.pow(math.sin(deltaLongitude / 2), 2);
  return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// `850 m`, `1.2 km`.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

double _toRadians(double degrees) => degrees * math.pi / 180;
