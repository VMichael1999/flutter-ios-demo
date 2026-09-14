/// Tipos de lugar que NOVA sabe buscar, con su etiqueta en OpenStreetMap.
enum PlaceCategory {
  restaurant('restaurante', 'amenity', 'restaurant'),
  cafe('cafetería', 'amenity', 'cafe'),
  fastFood('comida rápida', 'amenity', 'fast_food'),
  bar('bar', 'amenity', 'bar'),
  pharmacy('farmacia', 'amenity', 'pharmacy'),
  hospital('hospital', 'amenity', 'hospital'),
  bank('banco', 'amenity', 'bank'),
  atm('cajero automático', 'amenity', 'atm'),
  fuel('gasolinera', 'amenity', 'fuel'),
  supermarket('supermercado', 'shop', 'supermarket'),
  park('parque', 'leisure', 'park'),
  hotel('hotel', 'tourism', 'hotel');

  const PlaceCategory(this.label, this.osmKey, this.osmValue);

  final String label;
  final String osmKey;
  final String osmValue;

  String get displayName => '${label[0].toUpperCase()}${label.substring(1)}';

  static PlaceCategory? fromName(String? name) {
    for (final category in values) {
      if (category.name == name) return category;
    }
    return null;
  }
}
