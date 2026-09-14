import '../strings/date_strings.dart';
import '../strings/home_strings.dart';

/// Días de calendario entre dos fechas (0 si es el mismo día).
int calendarDaysBetween(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  // Redondeo: los cambios de horario hacen que un día dure 23 o 25 horas.
  return (end.difference(start).inHours / 24).round();
}

/// Saludo según la hora del día.
String greetingFor(DateTime time) => switch (time.hour) {
  < 5 => HomeStrings.greetingNight,
  < 12 => HomeStrings.greetingMorning,
  < 19 => HomeStrings.greetingAfternoon,
  _ => HomeStrings.greetingNight,
};

/// Fecha corta en español, por ejemplo "dom 13 sep".
String shortSpanishDate(DateTime date) =>
    '${DateStrings.weekdaysShort[date.weekday - 1]} ${_dayAndMonth(date)}';

/// Cuándo fue algo, en corto: "21:30" hoy, "Ayer", "lun" esta semana,
/// "13 sep" este año y "13 sep 2025" si es de otro año.
String relativeTimeLabel(DateTime date, DateTime now) {
  final days = calendarDaysBetween(date, now);
  if (days <= 0) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (days == 1) return DateStrings.yesterday;
  if (days < 7) return DateStrings.weekdaysShort[date.weekday - 1];
  final label = _dayAndMonth(date);
  return date.year == now.year ? label : '$label ${date.year}';
}

/// Grupo del historial al que pertenece una fecha.
String historySectionLabel(DateTime date, DateTime now) {
  final days = calendarDaysBetween(date, now);
  if (days <= 0) return DateStrings.today;
  if (days == 1) return DateStrings.yesterday;
  if (days < 7) return DateStrings.thisWeek;
  return DateStrings.older;
}

String _dayAndMonth(DateTime date) =>
    '${date.day} ${DateStrings.monthsShort[date.month - 1]}';
