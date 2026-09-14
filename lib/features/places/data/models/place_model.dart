import '../../../../core/utils/geo.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_category.dart';

/// Lugar tal como lo devuelve Overpass (OpenStreetMap).
class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  /// Devuelve `null` si el elemento no tiene nombre o coordenadas.
  static PlaceModel? fromOverpassElement(Map<String, Object?> json) {
    final tags = json['tags'];
    if (tags is! Map) return null;
    final name = tags['name'];
    if (name is! String || name.trim().isEmpty) return null;

    // Los nodos traen lat/lon; las vías y relaciones, un `center`.
    final center = json['center'];
    final latitude = json['lat'] ?? (center is Map ? center['lat'] : null);
    final longitude = json['lon'] ?? (center is Map ? center['lon'] : null);
    if (latitude is! num || longitude is! num) return null;

    return PlaceModel(
      id: '${json['type']}/${json['id']}',
      name: name.trim(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      address: _addressFrom(tags),
    );
  }

  static String? _addressFrom(Map<Object?, Object?> tags) {
    final street = tags['addr:street'];
    if (street is! String) return null;
    final number = tags['addr:housenumber'];
    return number is String ? '$street $number' : street;
  }

  Place toEntity({required GeoPoint center, required PlaceCategory category}) {
    final location = GeoPoint(latitude, longitude);
    return Place(
      id: id,
      name: name,
      category: category,
      location: location,
      distanceMeters: distanceInMeters(center, location),
      address: address,
    );
  }
}
