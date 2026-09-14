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
    this.brand,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;

  /// Marca u operador, por ejemplo "Tottus" en "Hipermercados Tottus".
  final String? brand;

  /// Devuelve `null` si el elemento no tiene nombre o coordenadas.
  static PlaceModel? fromOverpassElement(Map<String, Object?> json) {
    final tags = json['tags'];
    if (tags is! Map) return null;
    final name = _textTag(tags, 'name');
    if (name == null) return null;

    // Los nodos traen lat/lon; las vías y relaciones, un `center`.
    final center = json['center'];
    final latitude = json['lat'] ?? (center is Map ? center['lat'] : null);
    final longitude = json['lon'] ?? (center is Map ? center['lon'] : null);
    if (latitude is! num || longitude is! num) return null;

    return PlaceModel(
      id: '${json['type']}/${json['id']}',
      name: name,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      address: _addressFrom(tags),
      brand: _textTag(tags, 'brand') ?? _textTag(tags, 'operator'),
    );
  }

  static String? _textTag(Map<Object?, Object?> tags, String key) {
    final value = tags[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  static String? _addressFrom(Map<Object?, Object?> tags) {
    final street = _textTag(tags, 'addr:street');
    if (street == null) return null;
    final number = _textTag(tags, 'addr:housenumber');
    return number == null ? street : '$street $number';
  }

  /// `true` si el nombre o la marca contienen [query], sin distinguir
  /// mayúsculas ni tildes.
  bool matchesName(String query) {
    final needle = normalizeForSearch(query);
    if (needle.isEmpty) return true;
    return [name, brand].whereType<String>().any(
      (text) => normalizeForSearch(text).contains(needle),
    );
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

const _accents = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
  'ñ': 'n', 'ç': 'c',
};

/// Minúsculas, sin tildes y con espacios simples: "Café  Tostado" → "cafe tostado".
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
