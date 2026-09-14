import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/core/utils/dates.dart';

void main() {
  final now = DateTime(2026, 9, 13, 21, 30);

  group('relativeTimeLabel', () {
    test('hoy muestra la hora', () {
      expect(relativeTimeLabel(DateTime(2026, 9, 13, 8, 5), now), '08:05');
    });

    test('ayer, esta semana y fechas anteriores', () {
      expect(relativeTimeLabel(DateTime(2026, 9, 12, 23), now), 'Ayer');
      expect(relativeTimeLabel(DateTime(2026, 9, 9), now), 'mié');
      expect(relativeTimeLabel(DateTime(2026, 8, 30), now), '30 ago');
      expect(relativeTimeLabel(DateTime(2025, 12, 24), now), '24 dic 2025');
    });
  });

  test('historySectionLabel agrupa por cercanía', () {
    expect(historySectionLabel(DateTime(2026, 9, 13), now), 'Hoy');
    expect(historySectionLabel(DateTime(2026, 9, 12), now), 'Ayer');
    expect(historySectionLabel(DateTime(2026, 9, 8), now), 'Esta semana');
    expect(historySectionLabel(DateTime(2026, 9, 1), now), 'Anteriores');
  });
}
