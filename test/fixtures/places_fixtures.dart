import 'package:nova_ai/core/utils/geo.dart';
import 'package:nova_ai/features/places/domain/entities/place.dart';
import 'package:nova_ai/features/places/domain/entities/place_category.dart';

/// Parque Kennedy, Miraflores (Lima).
const testCenter = GeoPoint(-12.1211, -77.0297);

const chifaPlace = Place(
  id: 'node/1',
  name: 'Chifa Miraflores',
  category: PlaceCategory.restaurant,
  location: GeoPoint(-12.1138, -77.0374),
  distanceMeters: 850,
  address: 'Avenida Angamos Oeste 120',
);

const bodegaPlace = Place(
  id: 'way/2',
  name: 'Antigua Bodega Dalmacia',
  category: PlaceCategory.restaurant,
  location: GeoPoint(-12.1324, -77.0266),
  distanceMeters: 1250,
);
