/// Textos de lugares y del mapa.
abstract final class PlacesStrings {
  static const mapTitle = 'Lugares en el mapa';
  static const expandMap = 'Ampliar';
  static const attribution = '© OpenStreetMap';
  static const userLocation = 'Tu ubicación';

  static String mapPreviewLabel(int count) =>
      count == 1
          ? 'Mapa con 1 lugar. Toca para ampliarlo.'
          : 'Mapa con $count lugares. Toca para ampliarlo.';

  static String markerLabel(int number, String name) => 'Punto $number: $name';

  static String cardNumberLabel(int number) => 'Punto $number del mapa';
}
