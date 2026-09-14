import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/utils/geo.dart';

void main() {
  group('distanceInMeters', () {
    test('es cero para el mismo punto', () {
      const point = GeoPoint(-12.1211, -77.0297);
      expect(distanceInMeters(point, point), 0);
    });

    test('un grado de latitud mide unos 111 km', () {
      final distance = distanceInMeters(
        const GeoPoint(0, 0),
        const GeoPoint(1, 0),
      );
      expect(distance, closeTo(111195, 100));
    });

    test('calcula distancias cortas dentro de la ciudad', () {
      // Parque Kennedy → Larcomar, Miraflores: ~1,3 km en línea recta.
      final distance = distanceInMeters(
        const GeoPoint(-12.1211, -77.0297),
        const GeoPoint(-12.1318, -77.0305),
      );
      expect(distance, closeTo(1190, 60));
    });
  });

  group('formatDistance', () {
    test('usa metros por debajo de 1 km', () {
      expect(formatDistance(850.4), '850 m');
    });

    test('usa kilómetros con un decimal desde 1 km', () {
      expect(formatDistance(1234), '1.2 km');
      expect(formatDistance(5000), '5.0 km');
    });
  });
}
