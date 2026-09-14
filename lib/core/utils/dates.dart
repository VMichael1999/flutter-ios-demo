const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Días de calendario entre dos fechas (0 si es el mismo día).
int calendarDaysBetween(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  // Redondeo: los cambios de horario hacen que un día dure 23 o 25 horas.
  return (end.difference(start).inHours / 24).round();
}

/// Cuándo fue algo, en corto: "21:30" hoy, "Ayer", "lun" esta semana,
/// "13 sep" este año y "13 sep 2025" si es de otro año.
String relativeTimeLabel(DateTime date, DateTime now) {
  final days = calendarDaysBetween(date, now);
  if (days <= 0) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (days == 1) return 'Ayer';
  if (days < 7) return _weekdays[date.weekday - 1];
  final label = '${date.day} ${_months[date.month - 1]}';
  return date.year == now.year ? label : '$label ${date.year}';
}

/// Grupo del historial al que pertenece una fecha.
String historySectionLabel(DateTime date, DateTime now) {
  final days = calendarDaysBetween(date, now);
  if (days <= 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  if (days < 7) return 'Esta semana';
  return 'Anteriores';
}
