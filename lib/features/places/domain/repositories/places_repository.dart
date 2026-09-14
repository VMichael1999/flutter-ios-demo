import '../../../../core/utils/geo.dart';
import '../entities/place.dart';
import '../entities/place_category.dart';

abstract interface class PlacesRepository {
  /// Hasta [limit] lugares de [category] a menos de [radiusMeters] de
  /// [center], ordenados del más cercano al más lejano. Con [name] se buscan
  /// solo los lugares con ese nombre.
  ///
  /// Lanza `PlacesFailure` si el servicio no responde.
  Future<List<Place>> searchNearby({
    required GeoPoint center,
    required PlaceCategory category,
    required int radiusMeters,
    required int limit,
    String? name,
  });
}
