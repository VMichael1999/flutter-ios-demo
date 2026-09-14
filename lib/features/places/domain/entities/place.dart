import 'package:equatable/equatable.dart';

import '../../../../core/utils/geo.dart';
import 'place_category.dart';

class Place extends Equatable {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.distanceMeters,
    this.address,
  });

  final String id;
  final String name;
  final PlaceCategory category;
  final GeoPoint location;

  /// Distancia desde la ubicación del usuario.
  final double distanceMeters;
  final String? address;

  @override
  List<Object?> get props =>
      [id, name, category, location, distanceMeters, address];
}

class NearbyPlacesResult extends Equatable {
  const NearbyPlacesResult({
    required this.center,
    required this.radiusMeters,
    required this.places,
  });

  final GeoPoint center;
  final int radiusMeters;

  /// Del más cercano al más lejano.
  final List<Place> places;

  @override
  List<Object?> get props => [center, radiusMeters, places];
}
